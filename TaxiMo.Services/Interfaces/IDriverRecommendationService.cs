using TaxiMo.Services.DTOs;

namespace TaxiMo.Services.Interfaces
{
    /// <summary>
    /// Service for recommending drivers to users based on ML model predictions
    /// </summary>
    public interface IDriverRecommendationService
    {
        /// <summary>
        /// Gets recommended drivers for a user based on ML model predictions
        /// </summary>
        /// <param name="userId">The user ID</param>
        /// <param name="topN">Number of top recommendations to return (default: 5)</param>
        /// <returns>List of recommended drivers sorted by predicted score (descending)</returns>
        Task<List<DriverDto>> GetRecommendedDriversForUser(int userId, int topN = 5);

        /// <summary>
        /// Trains or retrains the ML model for a specific user based on their ride history
        /// </summary>
        /// <param name="userId">The user ID</param>
        /// <returns>True if training was successful, false if not enough data</returns>
        Task<bool> TrainModelForUser(int userId);

        /// <summary>
        /// Checks if a model exists for a user
        /// </summary>
        /// <param name="userId">The user ID</param>
        /// <returns>True if model exists, false otherwise</returns>
        bool ModelExistsForUser(int userId);

        /// <summary>
        /// Invalidates (deletes) the user's cached model, forcing retraining on the next recommendation request.
        /// This should be called when new training data becomes available (e.g., after a ride completion or review submission).
        /// </summary>
        /// <param name="userId">The user ID</param>
        void InvalidateUserModel(int userId);
    }
}
