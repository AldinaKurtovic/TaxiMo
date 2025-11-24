using TaxiMo.Services.Database.Entities;

namespace TaxiMo.Services.Interfaces
{
    public interface IDriverNotificationService
    {
        Task<List<DriverNotification>> GetAllAsync();
        Task<DriverNotification?> GetByIdAsync(int id);
        Task<DriverNotification> CreateAsync(DriverNotification driverNotification);
        Task<DriverNotification> UpdateAsync(DriverNotification driverNotification);
        Task<bool> DeleteAsync(int id);
    }
}

