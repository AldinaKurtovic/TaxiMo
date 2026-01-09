using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using System.Security.Claims;
using TaxiMo.Services.DTOs;
using TaxiMo.Services.Interfaces;

namespace TaxiMoWebAPI.Controllers
{
    /// <summary>
    /// Controller for ML-based driver recommendations.
    /// Provides endpoints for getting personalized driver recommendations using content-based filtering.
    /// </summary>
    [ApiController]
    [Route("api/recommendations")]
    [Authorize(Roles = "User,Driver,Admin")]
    public class DriverRecommendationController : ControllerBase
    {
        private readonly IDriverRecommendationService _recommendationService;
        private readonly ILogger<DriverRecommendationController> _logger;

        public DriverRecommendationController(
            IDriverRecommendationService recommendationService,
            ILogger<DriverRecommendationController> logger)
        {
            _recommendationService = recommendationService;
            _logger = logger;
        }

        /// <summary>
        /// Gets recommended drivers for the current authenticated user.
        /// Uses ML-based content recommendation if model exists, otherwise falls back to cold start strategy.
        /// </summary>
        /// <param name="topN">Number of top recommendations to return (min: 1, max: 20, default: 5)</param>
        /// <returns>List of recommended drivers sorted by predicted score (descending)</returns>
        /// <response code="200">Returns the list of recommended drivers</response>
        /// <response code="401">If user is not authenticated</response>
        /// <response code="500">If an error occurred while getting recommendations</response>
        // GET: api/recommendations/me?topN=5
        [HttpGet("me")]
        public async Task<ActionResult<IEnumerable<DriverDto>>> GetMyRecommendations([FromQuery] int topN = 5)
        {
            try
            {
                // Get current user ID from claims
                var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
                if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out var userId))
                {
                    _logger.LogWarning("Unable to get user ID from claims in recommendation request");
                    return Unauthorized(new { message = "Unable to identify user" });
                }

                // Clamp topN to reasonable bounds (min 1, max 20)
                topN = Math.Clamp(topN, 1, 20);

                // Get recommended drivers using ML-based recommendation system
                var recommendedDrivers = await _recommendationService.GetRecommendedDriversForUser(userId, topN);

                _logger.LogInformation("Returned {Count} recommended drivers for user {UserId}", recommendedDrivers.Count, userId);

                return Ok(recommendedDrivers);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving recommended drivers for authenticated user");
                return StatusCode(500, new { message = "An error occurred while retrieving recommended drivers" });
            }
        }
    }
}

