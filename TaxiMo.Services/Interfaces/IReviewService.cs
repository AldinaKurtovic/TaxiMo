using TaxiMo.Services.Database.Entities;

namespace TaxiMo.Services.Interfaces
{
    public interface IReviewService : IBaseCRUDService<Review>
    {
        Task<List<Review>> GetAllAsync(string? search = null, decimal? minRating = null);
    }
}

