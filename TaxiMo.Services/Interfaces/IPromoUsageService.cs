using TaxiMo.Services.Database.Entities;

namespace TaxiMo.Services.Interfaces
{
    public interface IPromoUsageService
    {
        Task<List<PromoUsage>> GetAllAsync();
        Task<PromoUsage?> GetByIdAsync(int id);
        Task<PromoUsage> CreateAsync(PromoUsage promoUsage);
        Task<PromoUsage> UpdateAsync(PromoUsage promoUsage);
        Task<bool> DeleteAsync(int id);
    }
}

