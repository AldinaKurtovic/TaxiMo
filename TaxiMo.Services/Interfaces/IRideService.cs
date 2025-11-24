using TaxiMo.Services.Database.Entities;

namespace TaxiMo.Services.Interfaces
{
    public interface IRideService
    {
        Task<List<Ride>> GetAllAsync();
        Task<Ride?> GetByIdAsync(int id);
        Task<Ride> CreateAsync(Ride ride);
        Task<Ride> UpdateAsync(Ride ride);
        Task<bool> DeleteAsync(int id);
    }
}

