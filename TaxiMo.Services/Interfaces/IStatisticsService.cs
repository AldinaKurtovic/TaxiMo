using TaxiMo.Services.DTOs;

namespace TaxiMo.Services.Interfaces
{
    public interface IStatisticsService
    {
        /// <summary>
        /// Gets the total number of registered users
        /// </summary>
        Task<TotalCountDto> GetTotalUsersAsync();

        /// <summary>
        /// Gets the total number of drivers, optionally filtered by status
        /// </summary>
        Task<TotalCountDto> GetTotalDriversAsync(string? status = null);

        /// <summary>
        /// Gets the total number of completed rides
        /// </summary>
        Task<TotalCountDto> GetTotalRidesAsync();

        /// <summary>
        /// Gets the average driver rating grouped by month for a given year
        /// </summary>
        Task<List<MonthlyValueDto>> GetAvgRatingPerMonthAsync(int year);

        /// <summary>
        /// Gets the total revenue per month for a given year
        /// </summary>
        Task<List<MonthlyValueDto>> GetRevenuePerMonthAsync(int year);
    }
}

