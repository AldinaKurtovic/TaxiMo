using Microsoft.EntityFrameworkCore;
using TaxiMo.Services.Database;
using TaxiMo.Services.DTOs;
using TaxiMo.Services.Interfaces;

namespace TaxiMo.Services.Services
{
    public class StatisticsService : IStatisticsService
    {
        private readonly TaxiMoDbContext _context;

        public StatisticsService(TaxiMoDbContext context)
        {
            _context = context;
        }

        public async Task<TotalCountDto> GetTotalUsersAsync()
        {
            var count = await _context.Users.CountAsync();
            return new TotalCountDto { Count = count };
        }

        public async Task<TotalCountDto> GetTotalDriversAsync(string? status = null)
        {
            var query = _context.Drivers.AsQueryable();

            if (!string.IsNullOrWhiteSpace(status))
            {
                query = query.Where(d => d.Status.ToLower() == status.ToLower());
            }

            var count = await query.CountAsync();
            return new TotalCountDto { Count = count };
        }

        public async Task<TotalCountDto> GetTotalRidesAsync()
        {
            var count = await _context.Rides
                .Where(r => r.Status.ToLower() == "completed")
                .CountAsync();

            return new TotalCountDto { Count = count };
        }

        public async Task<List<MonthlyValueDto>> GetAvgRatingPerMonthAsync(int year)
        {
            var dbResults = await _context.Reviews
                .Where(r => r.CreatedAt.Year == year)
                .GroupBy(r => r.CreatedAt.Month)
                .Select(g => new MonthlyValueDto
                {
                    Month = g.Key,
                    Value = g.Average(r => r.Rating)
                })
                .ToListAsync();

            return FillMissingMonths(dbResults);
        }

        public async Task<List<MonthlyValueDto>> GetRevenuePerMonthAsync(int year)
        {
            // Join Payments with Rides to get completed rides only
            // Use PaidAt if available, otherwise use Ride.CompletedAt
            var query = from p in _context.Payments
                       join r in _context.Rides on p.RideId equals r.RideId
                       where r.Status.ToLower() == "completed" &&
                             p.Status.ToLower() == "completed" &&
                             ((p.PaidAt.HasValue && p.PaidAt.Value.Year == year) ||
                              (!p.PaidAt.HasValue && r.CompletedAt.HasValue && r.CompletedAt.Value.Year == year))
                       select new
                       {
                           Amount = p.Amount,
                           RevenueMonth = p.PaidAt.HasValue ? p.PaidAt!.Value.Month : r.CompletedAt!.Value.Month
                       };

            var dbResults = await query
                .GroupBy(x => x.RevenueMonth)
                .Select(g => new MonthlyValueDto
                {
                    Month = g.Key,
                    Value = g.Sum(x => x.Amount)
                })
                .ToListAsync();

            return FillMissingMonths(dbResults);
        }

        /// <summary>
        /// Ensures all 12 months are present in the results, filling missing months with value 0.
        /// Returns a sorted list of 12 MonthlyValueDto objects (one for each month).
        /// </summary>
        private List<MonthlyValueDto> FillMissingMonths(List<MonthlyValueDto> dbResults)
        {
            var completeResults = new List<MonthlyValueDto>();

            // Create array of all 12 months
            for (int month = 1; month <= 12; month++)
            {
                // Search for existing data for this month
                var existingData = dbResults.FirstOrDefault(m => m.Month == month);
                
                if (existingData != null)
                {
                    // Use existing data
                    completeResults.Add(new MonthlyValueDto
                    {
                        Month = month,
                        Value = existingData.Value
                    });
                }
                else
                {
                    // Fill with 0 for missing month
                    completeResults.Add(new MonthlyValueDto
                    {
                        Month = month,
                        Value = 0
                    });
                }
            }

            // Ensure sorted by month (already sorted, but explicit for clarity)
            return completeResults.OrderBy(m => m.Month).ToList();
        }
    }
}

