using TaxiMo.Services.Database.Entities;
using TaxiMo.Services.DTOs;

namespace TaxiMo.Services.Interfaces
{
    public interface IPaymentService : IBaseCRUDService<Payment>
    {
        Task<PagedResponse<Payment>> GetAllPagedAsync(int page = 1, int limit = 7, string? search = null);
    }
}

