using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using System.Security.Claims;
using System.Linq;
using TaxiMo.Model.Responses;
using TaxiMo.Services.Database.Entities;
using TaxiMo.Services.DTOs;
using TaxiMo.Services.Interfaces;

namespace TaxiMoWebAPI.Controllers
{
    [Authorize(Roles = "User,Driver,Admin")]
    public class ReviewController : BaseCRUDController<Review, ReviewDto, ReviewCreateDto, ReviewUpdateDto>
    {
        protected override string EntityName => "Review";
        private readonly IReviewService _reviewService;

        private readonly IDriverRecommendationService _recommendationService;
        private readonly IRideService _rideService;

        public ReviewController(
            IReviewService reviewService,
            IDriverRecommendationService recommendationService,
            IRideService rideService,
            AutoMapper.IMapper mapper,
            ILogger<ReviewController> logger) 
            : base(reviewService, mapper, logger)
        {
            _reviewService = reviewService;
            _recommendationService = recommendationService;
            _rideService = rideService;
        }

        // GET: api/Review
        [HttpGet]
        public override async Task<ActionResult<IEnumerable<ReviewDto>>> GetAll([FromQuery] string? search = null, [FromQuery] string? status = null)
        {
            try
            {
                // Parse pagination parameters from query string
                int page = 1;
                int limit = 7;
                if (Request.Query.ContainsKey("page") && int.TryParse(Request.Query["page"].ToString(), out int pageValue))
                {
                    page = pageValue;
                }
                if (Request.Query.ContainsKey("limit") && int.TryParse(Request.Query["limit"].ToString(), out int limitValue))
                {
                    limit = limitValue;
                }

                // Parse minRating from query if provided
                decimal? minRating = null;
                if (Request.Query.ContainsKey("minRating"))
                {
                    if (decimal.TryParse(Request.Query["minRating"].ToString(), out decimal minRatingValue))
                    {
                        minRating = minRatingValue;
                    }
                }

                var pagedResult = await _reviewService.GetAllPagedAsync(page, limit, search, minRating);
                var responses = Mapper.Map<List<ReviewResponse>>(pagedResult.Data);
                
                return Ok(new
                {
                    data = responses,
                    pagination = new
                    {
                        currentPage = pagedResult.Pagination.CurrentPage,
                        totalPages = pagedResult.Pagination.TotalPages,
                        totalItems = pagedResult.Pagination.TotalItems,
                        limit = pagedResult.Pagination.Limit
                    }
                });
            }
            catch (Exception ex)
            {
                Logger.LogError(ex, "Error retrieving {EntityName}", EntityName);
                return StatusCode(500, new { message = $"An error occurred while retrieving {EntityName}" });
            }
        }

        // GET: api/Review/{id}
        [HttpGet("{id}")]
        public override async Task<ActionResult<ReviewDto>> GetById(int id)
        {
            try
            {
                var entity = await _reviewService.GetByIdAsync(id);

                if (entity == null)
                {
                    return NotFound(new { message = $"{EntityName} with ID {id} not found" });
                }

                var response = Mapper.Map<ReviewResponse>(entity);
                return Ok(response);
            }
            catch (Exception ex)
            {
                Logger.LogError(ex, "Error retrieving {EntityName} with ID {Id}", EntityName, id);
                return StatusCode(500, new { message = $"An error occurred while retrieving the {EntityName}" });
            }
        }

        // GET: api/Review/by-rider/{riderId}
        [HttpGet("by-rider/{riderId}")]
        public async Task<ActionResult<IEnumerable<ReviewDto>>> GetByRiderId(int riderId)
        {
            try
            {
                var entities = await _reviewService.GetByRiderIdAsync(riderId);
                // Map to ReviewDto which now includes driver and rider photo info
                var dtos = Mapper.Map<List<ReviewDto>>(entities);
                return Ok(dtos);
            }
            catch (Exception ex)
            {
                Logger.LogError(ex, "Error retrieving reviews for rider {RiderId}", riderId);
                return StatusCode(500, new { message = $"An error occurred while retrieving reviews for rider {riderId}" });
            }
        }

        // GET: api/Review/by-driver/{driverId}
        [HttpGet("by-driver/{driverId}")]
        public async Task<ActionResult<IEnumerable<ReviewResponse>>> GetByDriverId(int driverId)
        {
            try
            {
                var entities = await _reviewService.GetByDriverIdAsync(driverId);
                
                // Map to ReviewResponse format which includes user photo info
                var responses = Mapper.Map<List<ReviewResponse>>(entities);

                return Ok(responses);
            }
            catch (Exception ex)
            {
                Logger.LogError(ex, "Error retrieving reviews for driver {DriverId}", driverId);
                return StatusCode(500, new { message = $"An error occurred while retrieving reviews for driver {driverId}" });
            }
        }

        // POST: api/Review
        // Override base Create to trigger model retraining
        [HttpPost]
        public override async Task<ActionResult<ReviewDto>> Create(ReviewCreateDto createDto)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    return BadRequest(ModelState);
                }

                // Get authenticated user ID from claims
                var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int authenticatedUserId))
                {
                    Logger.LogWarning("Review creation failed - User ID not found in claims");
                    return Unauthorized(new { message = "User ID not found in claims" });
                }

                // Validate that the authenticated user matches the RiderId in the request
                if (createDto.RiderId != authenticatedUserId)
                {
                    Logger.LogWarning("Review creation failed - Authenticated user {AuthenticatedUserId} does not match RiderId {RiderId}", 
                        authenticatedUserId, createDto.RiderId);
                    return BadRequest(new { message = "You can only create reviews for your own rides" });
                }

                // Validate that the ride exists
                var ride = await _rideService.GetByIdAsync(createDto.RideId);
                if (ride == null)
                {
                    Logger.LogWarning("Review creation failed - Ride {RideId} not found", createDto.RideId);
                    return BadRequest(new { message = $"Ride with ID {createDto.RideId} not found" });
                }

                // Validate that the ride is completed
                if (ride.Status.ToLower() != "completed")
                {
                    Logger.LogWarning("Review creation failed - Ride {RideId} is not completed. Current status: {Status}", 
                        createDto.RideId, ride.Status);
                    return BadRequest(new { message = "You can only review completed rides. Current status: " + ride.Status });
                }

                // Validate that the RiderId matches the ride's RiderId
                if (ride.RiderId != createDto.RiderId)
                {
                    Logger.LogWarning("Review creation failed - RiderId {RiderId} does not match ride's RiderId {RideRiderId}", 
                        createDto.RiderId, ride.RiderId);
                    return BadRequest(new { message = "RiderId in review does not match the ride's RiderId" });
                }

                // Validate that the DriverId matches the ride's DriverId
                if (ride.DriverId != createDto.DriverId)
                {
                    Logger.LogWarning("Review creation failed - DriverId {DriverId} does not match ride's DriverId {RideDriverId}", 
                        createDto.DriverId, ride.DriverId);
                    return BadRequest(new { message = "DriverId in review does not match the ride's DriverId" });
                }

                // Check if a review already exists for this ride by this rider
                var existingReview = await _reviewService.GetByRideIdAsync(createDto.RideId);
                if (existingReview != null && existingReview.RiderId == createDto.RiderId)
                {
                    Logger.LogWarning("Review creation failed - Review already exists for ride {RideId} by rider {RiderId}", 
                        createDto.RideId, createDto.RiderId);
                    return BadRequest(new { message = "You have already reviewed this ride" });
                }

                var entity = Mapper.Map<Review>(createDto);
                var createdEntity = await _reviewService.CreateAsync(entity);
                var dto = Mapper.Map<ReviewDto>(createdEntity);

                // Invalidate model asynchronously (fire and forget)
                // The model will be retrained lazily on the next recommendation request
                _ = Task.Run(() =>
                {
                    try
                    {
                        _recommendationService.InvalidateUserModel(createdEntity.RiderId);
                        Logger.LogInformation("Invalidated ML model for user {UserId} after review {ReviewId} creation. Model will be retrained on next recommendation request.", 
                            createdEntity.RiderId, createdEntity.ReviewId);
                    }
                    catch (Exception ex)
                    {
                        Logger.LogError(ex, "Error invalidating model for user {UserId} after review {ReviewId} creation", createdEntity.RiderId, createdEntity.ReviewId);
                    }
                });

                return CreatedAtAction(nameof(GetById), new { id = createdEntity.ReviewId }, dto);
            }
            catch (Exception ex)
            {
                Logger.LogError(ex, "Error creating {EntityName}", EntityName);
                return StatusCode(500, new { message = $"An error occurred while creating the {EntityName}" });
            }
        }
    }
}

