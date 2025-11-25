using TaxiMo.Services.Database.Entities;

namespace TaxiMo.Services.Interfaces
{
    public interface IPromoCodeService
    {
        Task<List<PromoCode>> GetAllAsync(string? search = null, bool? isActive = null);
        Task<PromoCode?> GetByIdAsync(int id);
        Task<PromoCode> CreateAsync(PromoCode promoCode);
        Task<PromoCode> UpdateAsync(PromoCode promoCode);
        Task<bool> DeleteAsync(int id);
    }
}

