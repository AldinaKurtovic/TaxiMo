using TaxiMo.Services.Database.Entities;

namespace TaxiMo.Services.Interfaces
{
    public interface IPromoCodeService : IBaseCRUDService<PromoCode>
    {
        Task<List<PromoCode>> GetAllAsync(string? search = null, bool? isActive = null, string? sortBy = null, string? sortOrder = null);
    }
}

