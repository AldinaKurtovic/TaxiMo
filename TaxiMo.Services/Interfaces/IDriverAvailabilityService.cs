using TaxiMo.Services.Database.Entities;

namespace TaxiMo.Services.Interfaces
{
    public interface IDriverAvailabilityService
    {
        Task<List<DriverAvailability>> GetAllAsync();
        Task<DriverAvailability?> GetByIdAsync(int id);
        Task<DriverAvailability> CreateAsync(DriverAvailability driverAvailability);
        Task<DriverAvailability> UpdateAsync(DriverAvailability driverAvailability);
        Task<bool> DeleteAsync(int id);
    }
}

