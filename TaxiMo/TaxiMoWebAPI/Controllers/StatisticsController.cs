using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TaxiMo.Services.Interfaces;

namespace TaxiMoWebAPI.Controllers
{
    [ApiController]
    [Route("api/statistics")]
    [Authorize(Roles = "Admin")]
    public class StatisticsController : ControllerBase
    {
        private readonly IStatisticsService _statisticsService;
        private readonly ILogger<StatisticsController> _logger;

        public StatisticsController(
            IStatisticsService statisticsService,
            ILogger<StatisticsController> logger)
        {
            _statisticsService = statisticsService;
            _logger = logger;
        }

        /// <summary>
        /// Gets the total number of registered users
        /// </summary>
        [HttpGet("total-users")]
        public async Task<ActionResult> GetTotalUsers()
        {
            try
            {
                var result = await _statisticsService.GetTotalUsersAsync();
                return Ok(result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving total users");
                return StatusCode(500, new { message = "An error occurred while retrieving total users" });
            }
        }

        /// <summary>
        /// Gets the total number of drivers, optionally filtered by status
        /// </summary>
        [HttpGet("total-drivers")]
        public async Task<ActionResult> GetTotalDrivers([FromQuery] string? status = null)
        {
            try
            {
                var result = await _statisticsService.GetTotalDriversAsync(status);
                return Ok(result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving total drivers");
                return StatusCode(500, new { message = "An error occurred while retrieving total drivers" });
            }
        }

        /// <summary>
        /// Gets the total number of completed rides
        /// </summary>
        [HttpGet("total-rides")]
        public async Task<ActionResult> GetTotalRides()
        {
            try
            {
                var result = await _statisticsService.GetTotalRidesAsync();
                return Ok(result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving total rides");
                return StatusCode(500, new { message = "An error occurred while retrieving total rides" });
            }
        }

        /// <summary>
        /// Gets the average driver rating grouped by month for a given year
        /// </summary>
        [HttpGet("avg-rating-per-month")]
        public async Task<ActionResult> GetAvgRatingPerMonth([FromQuery] int? year = null)
        {
            try
            {
                // Default to current year if not provided
                if (!year.HasValue || year.Value < 1900 || year.Value > 9999)
                {
                    year = DateTime.UtcNow.Year;
                }

                var result = await _statisticsService.GetAvgRatingPerMonthAsync(year.Value);
                return Ok(result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving average rating per month for year {Year}", year);
                return StatusCode(500, new { message = "An error occurred while retrieving average rating per month" });
            }
        }

        /// <summary>
        /// Gets the total revenue per month for a given year
        /// </summary>
        [HttpGet("revenue-per-month")]
        public async Task<ActionResult> GetRevenuePerMonth([FromQuery] int? year = null)
        {
            try
            {
                // Default to current year if not provided
                if (!year.HasValue || year.Value < 1900 || year.Value > 9999)
                {
                    year = DateTime.UtcNow.Year;
                }

                var result = await _statisticsService.GetRevenuePerMonthAsync(year.Value);
                return Ok(result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving revenue per month for year {Year}", year);
                return StatusCode(500, new { message = "An error occurred while retrieving revenue per month" });
            }
        }
    }
}

