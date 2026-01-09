using AutoMapper;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using System.Security.Claims;
using TaxiMo.Services.DTOs;
using TaxiMo.Services.Interfaces;

namespace TaxiMoWebAPI.Controllers
{
    [ApiController]
    [Route("api/rides/available-drivers")]
    [Authorize(Roles = "User")]
    public class AvailableDriversController : ControllerBase
    {
        private readonly IDriverRecommendationService _recommendationService;
        private readonly ILogger<AvailableDriversController> _logger;

        public AvailableDriversController(
            IDriverRecommendationService recommendationService,
            ILogger<AvailableDriversController> logger)
        {
            _recommendationService = recommendationService;
            _logger = logger;
        }

        // GET: api/rides/available-drivers
        [HttpGet]
        public async Task<ActionResult<IEnumerable<DriverDto>>> GetAvailableDrivers([FromQuery] int topN = 5)
        {
            try
            {
                // Get current user ID from claims
                var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
                if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out var userId))
                {
                    _logger.LogWarning("Unable to get user ID from claims");
                    return Unauthorized(new { message = "Unable to identify user" });
                }

                // Clamp topN to reasonable bounds (min 1, max 20)
                topN = Math.Clamp(topN, 1, 20);

                // Get recommended drivers using ML-based recommendation system
                var recommendedDrivers = await _recommendationService.GetRecommendedDriversForUser(userId, topN);
                return Ok(recommendedDrivers);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving recommended drivers");
                return StatusCode(500, new { message = "An error occurred while retrieving recommended drivers" });
            }
        }
    }
}

