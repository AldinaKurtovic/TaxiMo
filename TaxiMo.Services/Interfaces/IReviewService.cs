using TaxiMo.Services.Database.Entities;

namespace TaxiMo.Services.Interfaces
{
    public interface IReviewService : IBaseCRUDService<Review>
    {
        Task<List<Review>> GetAllAsync(string? search = null, decimal? minRating = null);
        Task<List<Review>> GetByRiderIdAsync(int riderId);
        Task<List<Review>> GetByDriverIdAsync(int driverId);
        Task<Review?> GetByRideIdAsync(int rideId);
        Task<(decimal averageRating, int totalReviews)> GetDriverReviewStatsAsync(int driverId);
        Task<(int totalCompletedRides, decimal totalEarnings)> GetDriverRideStatsAsync(int driverId);
    }
}

