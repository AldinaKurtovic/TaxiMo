using TaxiMo.Services.Database.Entities;
using TaxiMo.Services.DTOs;

namespace TaxiMo.Services.Interfaces
{
    public interface IDriverNotificationService : IBaseCRUDService<DriverNotification>
    {
        Task<DriverNotification> CreateNotificationAsync(int recipientDriverId, string title, string? body, string type);
        Task<List<DriverNotification>> GetNotificationsByDriverIdAsync(int driverId);
        Task<List<DriverNotification>> GetUnreadNotificationsByDriverIdAsync(int driverId);
        Task<int> GetUnreadCountByDriverIdAsync(int driverId);
        Task<bool> MarkAsReadAsync(int notificationId);
    }
}

