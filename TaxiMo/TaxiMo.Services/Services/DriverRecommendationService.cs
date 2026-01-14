using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.ML;
using Microsoft.ML.Data;
using Microsoft.ML.Trainers;
using System.Security.Claims;
using TaxiMo.Services.Database;
using TaxiMo.Services.Database.Entities;
using TaxiMo.Services.DTOs;
using TaxiMo.Services.Interfaces;
using TaxiMo.Services.MLModels;

namespace TaxiMo.Services.Services
{
    /// <summary>
    /// Content-based recommender system for recommending drivers to users using ML.NET SDCA regression.
    /// This service implements a machine learning-based recommendation system that learns from user's ride history
    /// and predicts driver preference scores based on driver characteristics and ride features.
    /// </summary>
    public class DriverRecommendationService : IDriverRecommendationService
    {
        private readonly TaxiMoDbContext _context;
        private readonly ILogger<DriverRecommendationService> _logger;
        private readonly IReviewService _reviewService;
        private readonly string _modelsDirectory;
        private readonly MLContext _mlContext;
        private const int MIN_TRAINING_SAMPLES = 3; // Minimum number of completed rides with reviews needed for training

        public DriverRecommendationService(
            TaxiMoDbContext context,
            ILogger<DriverRecommendationService> logger,
            IReviewService reviewService)
        {
            _context = context;
            _logger = logger;
            _reviewService = reviewService;
            _mlContext = new MLContext(seed: 0);
            
            // Ensure Models directory exists
            _modelsDirectory = Path.Combine(Directory.GetCurrentDirectory(), "Models");
            if (!Directory.Exists(_modelsDirectory))
            {
                Directory.CreateDirectory(_modelsDirectory);
                _logger.LogInformation("Created Models directory at {ModelsDirectory}", _modelsDirectory);
            }
        }

        /// <summary>
        /// Gets recommended drivers for a user based on ML model predictions or cold start strategy.
        /// This method implements lazy training: if no model exists but sufficient data is available, it trains a new model.
        /// If a model exists, it loads it from cache and uses it for predictions.
        /// </summary>
        public async Task<List<DriverDto>> GetRecommendedDriversForUser(int userId, int topN = 5)
        {
            try
            {
                _logger.LogInformation("Getting recommended drivers for user {UserId}, topN: {TopN}", userId, topN);

                // Clamp topN to reasonable bounds (min 1, max 20)
                topN = Math.Clamp(topN, 1, 20);

                // Get all available drivers (using the same logic as DriverService.GetFreeDriversAsync)
                var availableDrivers = await GetAvailableDriversAsync();

                if (!availableDrivers.Any())
                {
                    _logger.LogWarning("No available drivers found for user {UserId}", userId);
                    return new List<DriverDto>();
                }

                // Load user's ride history with drivers for history bonus calculation
                // This includes completed rides with reviews to determine user's experience with each driver
                var userRideHistory = await _context.Rides
                    .Include(r => r.Reviews.Where(rev => rev.RiderId == userId))
                    .Where(r => r.RiderId == userId)
                    .ToListAsync();

                _logger.LogInformation("Found {AvailableCount} available drivers for user {UserId}. User has {HistoryCount} total rides in history.", 
                    availableDrivers.Count, userId, userRideHistory.Count);

                // LAZY TRAINING: Check if model exists, if not use cold start immediately
                if (!ModelExistsForUser(userId))
                {
                    // Always use cold start immediately for faster response
                    // Model will be trained on next request if sufficient data exists (lazy training)
                    _logger.LogInformation("Model does not exist for user {UserId}, using cold start strategy immediately.", userId);
                    return await ColdStartRecommendationWithHistory(availableDrivers, userRideHistory, userId, topN);
                }
                else
                {
                    _logger.LogInformation("Loading cached ML model for user {UserId}", userId);
                }

                // Load the model and make predictions
                try
                {
                    var modelPath = GetModelPath(userId);
                    var mlModel = _mlContext.Model.Load(modelPath, out var modelInputSchema);
                    var predictionEngine = _mlContext.Model.CreatePredictionEngine<DriverFeatures, DriverPrediction>(mlModel);

                    // Get user's average ride characteristics for prediction
                    var userAvgRideStats = await GetUserAverageRideStatsAsync(userId);

                    // Predict scores for each available driver and combine with history bonus
                    var driverScores = new List<(Driver Driver, float FinalScore, float MlScore, float HistoryBonus)>();

                    foreach (var driver in availableDrivers)
                    {
                        try
                        {
                            // Filter out drivers with whom user already had completed rides (unless rating was excellent 4.5+)
                            if (ShouldExcludeDriver(userId, driver.DriverId, userRideHistory))
                            {
                                _logger.LogDebug("Excluding driver {DriverId} for user {UserId} - already had completed ride with lower rating", 
                                    driver.DriverId, userId);
                                continue;
                            }

                            // Get ML prediction score
                            var features = ExtractFeaturesForDriver(driver, userAvgRideStats);
                            var prediction = predictionEngine.Predict(features);
                            var mlScore = prediction.PredictedScore;

                            // Safety check: Ignore NaN or Infinity predictions
                            if (float.IsNaN(mlScore) || float.IsInfinity(mlScore))
                            {
                                _logger.LogWarning("Invalid ML prediction score (NaN/Infinity) for driver {DriverId}, user {UserId}. Skipping driver.", 
                                    driver.DriverId, userId);
                                continue;
                            }

                            // Calculate history bonus based on user's previous experience with this driver
                            var historyBonus = CalculateHistoryBonus(userId, driver.DriverId, userRideHistory);

                            // Combine ML score with history bonus: finalScore = mlScore + historyBonus
                            var finalScore = mlScore + historyBonus;

                            driverScores.Add((driver, finalScore, mlScore, historyBonus));

                            // Log when history bonus is applied
                            if (Math.Abs(historyBonus) > 0.01f) // Only log if bonus is significant
                            {
                                _logger.LogInformation(
                                    "History bonus applied for driver {DriverId}, user {UserId}: ML Score={MlScore:F3}, History Bonus={HistoryBonus:F3}, Final Score={FinalScore:F3}",
                                    driver.DriverId, userId, mlScore, historyBonus, finalScore);
                            }
                        }
                        catch (Exception ex)
                        {
                            _logger.LogWarning(ex, "Error calculating score for driver {DriverId}, user {UserId}. Skipping driver.", 
                                driver.DriverId, userId);
                            continue;
                        }
                    }

                    // If no valid predictions remain, fallback to cold start
                    if (!driverScores.Any())
                    {
                        _logger.LogWarning("No valid predictions generated for user {UserId}, falling back to cold start", userId);
                        return await ColdStartRecommendationWithHistory(availableDrivers, userRideHistory, userId, topN);
                    }

                    // Sort by final score (ML score + history bonus) descending and take top N
                    var topDrivers = driverScores
                        .OrderByDescending(x => x.FinalScore)
                        .Take(topN)
                        .ToList();

                    // Map to DTOs with actual rating and rides count
                    var recommendedDrivers = new List<DriverDto>();
                    foreach (var driverScore in topDrivers)
                    {
                        var dto = await MapToDriverDtoAsync(driverScore.Driver);
                        recommendedDrivers.Add(dto);
                    }

                    // Log metrics including history bonus information
                    var topScores = driverScores.OrderByDescending(x => x.FinalScore).Take(topN).ToList();
                    var scoreDetails = topScores.Select(x => 
                        $"ML:{x.MlScore:F3}+History:{x.HistoryBonus:F3}={x.FinalScore:F3}").ToList();
                    _logger.LogInformation(
                        "Returned {Count} recommended drivers for user {UserId}. Top scores: [{Scores}]", 
                        recommendedDrivers.Count, userId, string.Join(", ", scoreDetails));

                    return recommendedDrivers;
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "Error loading or using model for user {UserId}, falling back to cold start", userId);
                    return await ColdStartRecommendationWithHistory(availableDrivers, userRideHistory, userId, topN);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting recommended drivers for user {UserId}", userId);
                throw;
            }
        }

        /// <summary>
        /// Trains or retrains the ML model for a specific user based on their ride history.
        /// This method should only be called explicitly or via lazy training when no model exists.
        /// For normal operation, use InvalidateUserModel() to mark the model for retraining.
        /// </summary>
        public async Task<bool> TrainModelForUser(int userId)
        {
            // Check if model exists - if it does, we should not retrain unless explicitly invalidated
            if (ModelExistsForUser(userId))
            {
                _logger.LogWarning("Model already exists for user {UserId}. Use InvalidateUserModel() first if retraining is needed.", userId);
                return true; // Model exists, no need to retrain
            }

            return await TrainModelForUserIfPossible(userId);
        }

        /// <summary>
        /// Internal method that attempts to train a model if sufficient data is available.
        /// Returns true if training succeeded, false otherwise.
        /// </summary>
        private async Task<bool> TrainModelForUserIfPossible(int userId)
        {
            try
            {
                _logger.LogInformation("Training new ML model for user {UserId}", userId);

                // Get completed rides for the user with reviews
                var completedRides = await _context.Rides
                    .Include(r => r.Driver)
                    .Include(r => r.Reviews.Where(rev => rev.RiderId == userId))
                    .Where(r => r.RiderId == userId && r.Status.ToLower() == "completed")
                    .ToListAsync();

                if (completedRides.Count < MIN_TRAINING_SAMPLES)
                {
                    _logger.LogWarning(
                        "Insufficient data for training model for user {UserId}. Required: {Required}, Found: {Count}", 
                        userId, MIN_TRAINING_SAMPLES, completedRides.Count);
                    return false;
                }

                // Extract features from completed rides
                var trainingData = new List<DriverFeatures>();

                foreach (var ride in completedRides)
                {
                    try
                    {
                        var features = await ExtractFeaturesFromRide(ride);
                        if (features != null)
                        {
                            trainingData.Add(features);
                        }
                    }
                    catch (Exception ex)
                    {
                        _logger.LogWarning(ex, "Error extracting features from ride {RideId} for user {UserId}", ride.RideId, userId);
                    }
                }

                // Safety check: Ensure minimum training samples after feature extraction
                if (trainingData.Count < MIN_TRAINING_SAMPLES)
                {
                    _logger.LogWarning(
                        "Insufficient valid training data for user {UserId}. Required: {Required}, Found: {Count}", 
                        userId, MIN_TRAINING_SAMPLES, trainingData.Count);
                    return false;
                }

                _logger.LogInformation(
                    "Training ML model for user {UserId} with {SampleCount} training samples", 
                    userId, trainingData.Count);

                // Convert to IDataView
                var dataView = _mlContext.Data.LoadFromEnumerable(trainingData);

                // Build ML pipeline:
                // 1. Concatenate all features into a single feature vector
                // 2. Normalize features using MinMax normalization (scales all features to 0-1 range)
                // 3. Train using SDCA (Stochastic Dual Coordinate Ascent) regression
                // 
                // Why SDCA Regression?
                // - SDCA is efficient for linear models with normalized features
                // - Works well with sparse and dense feature vectors
                // - Provides good convergence properties
                // - Suitable for content-based recommendation where we predict continuous preference scores
                var pipeline = _mlContext.Transforms.Concatenate(
                        "Features",
                        nameof(DriverFeatures.DriverAverageRating),
                        nameof(DriverFeatures.DriverTotalRides),
                        nameof(DriverFeatures.AverageRidePrice),
                        nameof(DriverFeatures.RideDistanceKm),
                        nameof(DriverFeatures.RideDurationMin),
                        nameof(DriverFeatures.TimeOfDay))
                    .Append(_mlContext.Transforms.NormalizeMinMax("Features", "Features"))
                    .Append(_mlContext.Regression.Trainers.Sdca(
                        labelColumnName: nameof(DriverFeatures.Label),
                        featureColumnName: "Features"));

                // Train the model
                var model = pipeline.Fit(dataView);

                // Save the model with retry logic for file locking issues
                var modelPath = GetModelPath(userId);
                const int maxRetries = 3;
                const int retryDelayMs = 100;
                
                for (int attempt = 1; attempt <= maxRetries; attempt++)
                {
                    try
                    {
                _mlContext.Model.Save(model, dataView.Schema, modelPath);

                _logger.LogInformation(
                    "Successfully trained and saved ML model for user {UserId} at {ModelPath} with {SampleCount} samples", 
                    userId, modelPath, trainingData.Count);
                return true;
                    }
                    catch (IOException ioEx) when (attempt < maxRetries && ioEx.Message.Contains("being used by another process"))
                    {
                        // File is locked by another process, wait and retry
                        _logger.LogWarning(
                            "Model file for user {UserId} is locked, retrying ({Attempt}/{MaxRetries}) after {DelayMs}ms", 
                            userId, attempt, maxRetries, retryDelayMs);
                        await Task.Delay(retryDelayMs * attempt); // Exponential backoff
                        
                        // Check if file was saved by another process
                        if (File.Exists(modelPath))
                        {
                            _logger.LogInformation(
                                "Model file for user {UserId} was saved by another process, skipping save", userId);
                            return true;
                        }
                    }
                }
                
                // If all retries failed, check if file exists (another process might have saved it)
                if (File.Exists(modelPath))
                {
                    _logger.LogInformation(
                        "Model file for user {UserId} exists after save failure, assuming saved by another process", userId);
                    return true;
                }
                
                throw new IOException($"Failed to save model for user {userId} after {maxRetries} attempts");
            }
            catch (IOException ioEx)
            {
                // Check if file was saved by another process
                var modelPath = GetModelPath(userId);
                if (File.Exists(modelPath))
                {
                    _logger.LogInformation(
                        "Model file for user {UserId} exists after IOException, assuming saved by another process", userId);
                    return true;
                }
                _logger.LogError(ioEx, "Error saving model file for user {UserId}", userId);
                return false;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error training model for user {UserId}", userId);
                return false;
            }
        }

        /// <summary>
        /// Checks if a cached model exists for the user.
        /// </summary>
        public bool ModelExistsForUser(int userId)
        {
            var modelPath = GetModelPath(userId);
            return File.Exists(modelPath);
        }

        /// <summary>
        /// Invalidates (deletes) the user's cached model, forcing retraining on the next recommendation request.
        /// This should be called when new training data becomes available (e.g., after a ride completion or review submission).
        /// The model will be retrained lazily when GetRecommendedDriversForUser is called next.
        /// </summary>
        public void InvalidateUserModel(int userId)
        {
            var modelPath = GetModelPath(userId);
            if (File.Exists(modelPath))
            {
                try
                {
                    File.Delete(modelPath);
                    _logger.LogInformation("Invalidated (deleted) ML model for user {UserId}. Model will be retrained on next recommendation request.", userId);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error deleting model file for user {UserId} at {ModelPath}", userId, modelPath);
                    throw;
                }
            }
            else
            {
                _logger.LogDebug("No model to invalidate for user {UserId} (model does not exist)", userId);
            }
        }

        private string GetModelPath(int userId)
        {
            return Path.Combine(_modelsDirectory, $"User_{userId}_DriverModel.zip");
        }

        private async Task<List<Driver>> GetAvailableDriversAsync()
        {
            // Get drivers with status "active" who don't have any active rides
            // AND who have at least one active vehicle
            var activeDrivers = await _context.Drivers
                .Include(d => d.DriverAvailabilities)
                .Include(d => d.Vehicles)
                .Where(d =>
                    d.Status.ToLower() == "active" &&
                    d.Vehicles.Any(v => v.Status.ToLower() == "active")
                )
                .ToListAsync();

            var activeRideDriverIds = await _context.Rides
                .Where(r => r.Status.ToLower() == "active" ||
                           r.Status.ToLower() == "requested" ||
                           r.Status.ToLower() == "accepted")
                .Select(r => r.DriverId)
                .Distinct()
                .ToListAsync();

            var freeDrivers = activeDrivers
                .Where(d => !activeRideDriverIds.Contains(d.DriverId))
                .ToList();

            return freeDrivers;
        }

        /// <summary>
        /// Extracts features from a completed ride for training data.
        /// Features include:
        /// - DriverAverageRating: Driver's average rating at time of ride (indicator of driver quality)
        /// - DriverTotalRides: Driver's total completed rides (experience indicator)
        /// - AverageRidePrice: Price paid for this ride (affordability preference)
        /// - RideDistanceKm: Distance of the ride (trip length preference)
        /// - RideDurationMin: Duration of the ride (trip duration preference)
        /// - TimeOfDay: Time period (0=morning, 1=afternoon, 2=night) - captures temporal preferences
        /// 
        /// Label represents user satisfaction:
        /// - 1.0: Rating 4-5 stars (highly satisfied)
        /// - 0.6: Rating 3 stars (neutral/moderately satisfied)
        /// - 0.2: Rating 1-2 stars (dissatisfied)
        /// </summary>
        private async Task<DriverFeatures?> ExtractFeaturesFromRide(Ride ride)
        {
            try
            {
                // Get the review for this ride (user's rating)
                var review = ride.Reviews.FirstOrDefault(r => r.RiderId == ride.RiderId);
                if (review == null)
                {
                    _logger.LogDebug("No review found for ride {RideId}", ride.RideId);
                    return null;
                }

                // Get driver's stats at the time of ride completion (or current if not available)
                var driver = ride.Driver;
                var driverRating = driver.RatingAvg ?? 0m;
                var driverTotalRides = driver.TotalRides;

                // Calculate average ride price (use FareFinal if available, otherwise FareEstimate)
                var ridePrice = ride.FareFinal ?? ride.FareEstimate ?? 0m;
                
                // Get ride distance and duration
                var rideDistance = ride.DistanceKm ?? 0m;
                var rideDuration = ride.DurationMin ?? 0;

                // Calculate time of day from ride completion time (or requested time if not completed)
                var rideTime = ride.CompletedAt ?? ride.RequestedAt;
                var hour = rideTime.Hour;
                float timeOfDay;
                if (hour >= 6 && hour < 12)
                    timeOfDay = 0f; // Morning (6-12)
                else if (hour >= 12 && hour < 18)
                    timeOfDay = 1f; // Afternoon (12-18)
                else
                    timeOfDay = 2f; // Night (18-6)

                // Map rating to label
                // Label encoding: Continuous scale representing user satisfaction level
                // This allows the regression model to learn nuanced preferences
                float label;
                var rating = review.Rating;
                if (rating >= 4)
                    label = 1.0f; // Highly satisfied (4-5 stars)
                else if (rating == 3)
                    label = 0.6f; // Neutral/moderately satisfied (3 stars)
                else
                    label = 0.2f; // Dissatisfied (1-2 stars)

                return new DriverFeatures
                {
                    DriverAverageRating = (float)driverRating,
                    DriverTotalRides = driverTotalRides,
                    AverageRidePrice = (float)ridePrice,
                    RideDistanceKm = (float)rideDistance,
                    RideDurationMin = rideDuration,
                    TimeOfDay = timeOfDay,
                    Label = label
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error extracting features from ride {RideId}", ride.RideId);
                return null;
            }
        }

        private async Task<(float avgPrice, float avgDistance, int avgDuration)> GetUserAverageRideStatsAsync(int userId)
        {
            // Get user's completed rides to calculate average ride characteristics
            var userCompletedRides = await _context.Rides
                .Where(r => r.RiderId == userId && r.Status.ToLower() == "completed")
                .ToListAsync();

            if (!userCompletedRides.Any())
            {
                // Return default values if user has no ride history
                return (25.0f, 5.0f, 15);
            }

            var avgPrice = (float)userCompletedRides.Average(r => (r.FareFinal ?? r.FareEstimate ?? 0m));
            var avgDistance = (float)userCompletedRides.Average(r => r.DistanceKm ?? 0m);
            var avgDuration = (int)userCompletedRides.Average(r => r.DurationMin ?? 0);

            return (avgPrice, avgDistance, avgDuration);
        }

        /// <summary>
        /// Extracts features for a driver candidate for prediction.
        /// Uses current driver stats and user's average ride characteristics to predict preference score.
        /// </summary>
        private DriverFeatures ExtractFeaturesForDriver(Driver driver, (float avgPrice, float avgDistance, int avgDuration) userAvgStats)
        {
            // Extract features for prediction (current driver stats, average ride characteristics from user's history)
            // Use current time of day
            var currentHour = DateTime.Now.Hour;
            float timeOfDay;
            if (currentHour >= 6 && currentHour < 12)
                timeOfDay = 0f; // Morning
            else if (currentHour >= 12 && currentHour < 18)
                timeOfDay = 1f; // Afternoon
            else
                timeOfDay = 2f; // Night

            return new DriverFeatures
            {
                DriverAverageRating = (float)(driver.RatingAvg ?? 0m),
                DriverTotalRides = driver.TotalRides,
                AverageRidePrice = userAvgStats.avgPrice,
                RideDistanceKm = userAvgStats.avgDistance,
                RideDurationMin = userAvgStats.avgDuration,
                TimeOfDay = timeOfDay,
                Label = 0f // Not used for prediction
            };
        }

        /// <summary>
        /// Determines if a driver should be excluded from recommendations.
        /// Excludes drivers with whom user already had completed rides, unless the rating was excellent (4.5+).
        /// This encourages users to try new drivers while still allowing highly-rated previous drivers.
        /// </summary>
        private bool ShouldExcludeDriver(int userId, int driverId, List<Ride> userRideHistory)
        {
            // Get all completed rides with this specific driver
            var completedRidesWithDriver = userRideHistory
                .Where(r => r.DriverId == driverId && r.Status.ToLower() == "completed")
                .OrderByDescending(r => r.CompletedAt ?? r.RequestedAt)
                .ToList();

            if (!completedRidesWithDriver.Any())
            {
                // No completed rides with this driver - don't exclude
                return false;
            }

            // Get the most recent completed ride with a review
            var mostRecentRide = completedRidesWithDriver
                .Where(r => r.Reviews.Any(rev => rev.RiderId == userId))
                .OrderByDescending(r => r.CompletedAt ?? r.RequestedAt)
                .FirstOrDefault();

            if (mostRecentRide == null)
            {
                // No reviews - don't exclude (maybe user didn't rate)
                return false;
            }

            // Get the user's rating for this ride
            var review = mostRecentRide.Reviews.FirstOrDefault(r => r.RiderId == userId);
            if (review == null)
            {
                return false;
            }

            var rating = (float)review.Rating;

            // Only exclude if rating was less than 4.5 (excellent)
            // If rating is 4.5+, we want to show this driver again (they had excellent experience)
            return rating < 4.5f;
        }

        /// <summary>
        /// Calculates a history bonus score for a driver based on user's previous experience.
        /// Positive bonus for good experiences, negative for poor experiences.
        /// Enhanced to prioritize drivers with more ride history.
        /// </summary>
        private float CalculateHistoryBonus(int userId, int driverId, List<Ride> userRideHistory)
        {
            // Get all rides with this specific driver
            var ridesWithDriver = userRideHistory
                .Where(r => r.DriverId == driverId)
                .OrderByDescending(r => r.CompletedAt ?? r.RequestedAt)
                .ToList();

            if (!ridesWithDriver.Any())
            {
                // No previous rides with this driver - no bonus or penalty
                return 0.0f;
            }

            // Check for cancelled rides (negative indicator)
            var hasCancelledRide = ridesWithDriver.Any(r => r.Status.ToLower() == "cancelled");
            if (hasCancelledRide)
            {
                _logger.LogDebug("Driver {DriverId} has cancelled ride with user {UserId}, applying negative history bonus", driverId, userId);
                return -0.3f;
            }

            // Get all completed rides with reviews for this driver
            var completedRidesWithReviews = ridesWithDriver
                .Where(r => r.Status.ToLower() == "completed" && r.Reviews.Any(rev => rev.RiderId == userId))
                .ToList();

            if (!completedRidesWithReviews.Any())
            {
                // No completed rides with reviews - neutral
                return 0.0f;
            }

            // Get the most recent completed ride with a review for rating assessment
            var mostRecentRide = completedRidesWithReviews
                .OrderByDescending(r => r.CompletedAt ?? r.RequestedAt)
                .FirstOrDefault();

            if (mostRecentRide == null)
            {
                return 0.0f;
            }

            // Get the user's rating for the most recent ride
            var review = mostRecentRide.Reviews.FirstOrDefault(r => r.RiderId == userId);
            if (review == null)
            {
                return 0.0f;
            }

            var rating = (float)review.Rating;
            var completedRidesCount = completedRidesWithReviews.Count;

            // Apply history bonus based on rating, with additional bonus for more rides
            if (rating >= 4.5f)
            {
                // Excellent experience: base +0.5, +0.1 per additional ride (max +1.0 total)
                var baseBonus = 0.5f;
                var additionalBonus = Math.Min((completedRidesCount - 1) * 0.1f, 0.5f);
                return baseBonus + additionalBonus;
            }
            else if (rating >= 4.0f)
            {
                // Good experience: base +0.2, +0.05 per additional ride (max +0.5 total)
                var baseBonus = 0.2f;
                var additionalBonus = Math.Min((completedRidesCount - 1) * 0.05f, 0.3f);
                return baseBonus + additionalBonus;
            }
            else if (rating < 3.0f)
            {
                return -0.3f; // Poor experience - negative penalty
            }
            else
            {
                // Rating between 3.0-3.9 (neutral/moderate) - no bonus or penalty
                return 0.0f;
            }
        }

        /// <summary>
        /// Cold start recommendation strategy used when:
        /// - User has no completed rides
        /// - User has insufficient data to train a model (< 3 completed rides with reviews)
        /// 
        /// Strategy: Recommend drivers with highest average rating, then by most completed rides.
        /// Also applies history bonus to prioritize drivers with good previous experiences.
        /// This provides a sensible fallback that prioritizes driver quality and experience.
        /// </summary>
        private async Task<List<DriverDto>> ColdStartRecommendationWithHistory(
            List<Driver> drivers, 
            List<Ride> userRideHistory, 
            int userId, 
            int topN)
        {
            _logger.LogInformation("Using cold start recommendation strategy with history bonus for {Count} drivers", drivers.Count);

            // Log which drivers are being excluded and why
            var excludedDrivers = drivers.Where(driver => ShouldExcludeDriver(userId, driver.DriverId, userRideHistory)).ToList();
            if (excludedDrivers.Any())
            {
                foreach (var excludedDriver in excludedDrivers)
                {
                    var completedRidesWithDriver = userRideHistory
                        .Where(r => r.DriverId == excludedDriver.DriverId && r.Status.ToLower() == "completed")
                        .OrderByDescending(r => r.CompletedAt ?? r.RequestedAt)
                        .ToList();
                    
                    var mostRecentRide = completedRidesWithDriver
                        .Where(r => r.Reviews.Any(rev => rev.RiderId == userId))
                        .OrderByDescending(r => r.CompletedAt ?? r.RequestedAt)
                        .FirstOrDefault();
                    
                    if (mostRecentRide != null)
                    {
                        var review = mostRecentRide.Reviews.FirstOrDefault(r => r.RiderId == userId);
                        if (review != null)
                        {
                            _logger.LogInformation("Cold start: Excluding driver {DriverId} (username: {Username}) for user {UserId} - completed ride {RideId} with rating {Rating} (< 4.5)", 
                                excludedDriver.DriverId, excludedDriver.Username, userId, mostRecentRide.RideId, review.Rating);
                        }
                    }
                }
            }

            // Calculate base score (rating + total rides) and combine with history bonus
            var driverScores = drivers
                .Where(driver => !ShouldExcludeDriver(userId, driver.DriverId, userRideHistory))
                .Select(driver =>
            {
                // Base score: normalize rating (0-5 scale) and total rides
                var baseScore = (float)(driver.RatingAvg ?? 0m) * 0.2f + Math.Min(driver.TotalRides / 100.0f, 1.0f);
                
                // Apply history bonus
                var historyBonus = CalculateHistoryBonus(userId, driver.DriverId, userRideHistory);
                var finalScore = baseScore + historyBonus;

                return (Driver: driver, FinalScore: finalScore, HistoryBonus: historyBonus);
            }).ToList();

            // Sort by final score (base score + history bonus) descending
            var topDrivers = driverScores
                .OrderByDescending(x => x.FinalScore)
                .Take(topN)
                .ToList();

            // Map to DTOs with actual rating and rides count
            var recommendedDrivers = new List<DriverDto>();
            foreach (var driverScore in topDrivers)
            {
                var dto = await MapToDriverDtoAsync(driverScore.Driver);
                recommendedDrivers.Add(dto);
            }

            // Log history bonus application in cold start
            var driversWithBonus = driverScores.Where(x => Math.Abs(x.HistoryBonus) > 0.01f).ToList();
            if (driversWithBonus.Any())
            {
                _logger.LogInformation(
                    "Cold start: Applied history bonus to {Count} drivers. Drivers with bonus: {Drivers}",
                    driversWithBonus.Count,
                    string.Join(", ", driversWithBonus.Select(d => $"Driver {d.Driver.DriverId} (bonus: {d.HistoryBonus:F3})")));
            }

            _logger.LogInformation("Cold start: Returned {Count} recommended drivers (sorted by base score + history bonus)", recommendedDrivers.Count);

            return recommendedDrivers;
        }

        private async Task<DriverDto> MapToDriverDtoAsync(Driver driver)
        {
            // Get latest availability for coordinates
            double? currentLatitude = null;
            double? currentLongitude = null;
            if (driver.DriverAvailabilities != null && driver.DriverAvailabilities.Any())
            {
                var latestAvailability = driver.DriverAvailabilities
                    .OrderByDescending(da => da.LastLocationUpdate ?? da.UpdatedAt)
                    .FirstOrDefault();
                if (latestAvailability != null)
                {
                    currentLatitude = latestAvailability.CurrentLat.HasValue ? (double?)latestAvailability.CurrentLat.Value : null;
                    currentLongitude = latestAvailability.CurrentLng.HasValue ? (double?)latestAvailability.CurrentLng.Value : null;
                }
            }

            // Get first vehicle ID
            int? vehicleId = null;
            if (driver.Vehicles != null && driver.Vehicles.Any())
            {
                vehicleId = driver.Vehicles.FirstOrDefault()?.VehicleId;
            }

            // Get actual rating and rides count from ReviewService (not from driver entity which may be outdated)
            var (averageRating, _) = await _reviewService.GetDriverReviewStatsAsync(driver.DriverId);
            var (totalCompletedRides, _) = await _reviewService.GetDriverRideStatsAsync(driver.DriverId);

            return new DriverDto
            {
                DriverId = driver.DriverId,
                FirstName = driver.FirstName,
                LastName = driver.LastName,
                Email = driver.Email,
                Phone = driver.Phone,
                LicenseNumber = driver.LicenseNumber,
                Username = driver.Username,
                LicenseExpiry = driver.LicenseExpiry,
                RatingAvg = averageRating,
                TotalRides = totalCompletedRides,
                Status = driver.Status,
                PhotoUrl = string.IsNullOrWhiteSpace(driver.PhotoUrl) ? "images/default-avatar.png" : driver.PhotoUrl,
                CreatedAt = driver.CreatedAt,
                UpdatedAt = driver.UpdatedAt,
                Roles = new List<string>(), // Would need to load from DriverRoles if needed
                CurrentLatitude = currentLatitude,
                CurrentLongitude = currentLongitude,
                VehicleId = vehicleId
            };
        }
    }
}
