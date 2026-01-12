using TaxiMo.Services.Database.Entities;
using TaxiMo.Services.DTOs;

namespace TaxiMo.Services.Interfaces
{
    public interface IPromoCodeService : IBaseCRUDService<PromoCode>
    {
        Task<List<PromoCode>> GetAllAsync(string? search = null, bool? isActive = null, string? sortBy = null, string? sortOrder = null);
        Task<PagedResponse<PromoCode>> GetAllPagedAsync(int page = 1, int limit = 7, string? search = null, bool? isActive = null, string? sortBy = null, string? sortOrder = null);
    }
}

