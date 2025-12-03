using TaxiMo.Services.Database.Entities;

namespace TaxiMo.Services.Interfaces
{
    public interface IRideService : IBaseCRUDService<Ride>
    {
        Task<List<Ride>> GetAllAsync(string? search = null, string? status = null);
    }
}

