using TaxiMo.Services.Database.Entities;

namespace TaxiMo.Services.Interfaces
{
    public interface ILocationService
    {
        Task<List<Location>> GetAllAsync();
        Task<Location?> GetByIdAsync(int id);
        Task<Location> CreateAsync(Location location);
        Task<Location> UpdateAsync(Location location);
        Task<bool> DeleteAsync(int id);
    }
}

