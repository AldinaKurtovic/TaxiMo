using TaxiMo.Services.Database.Entities;
using TaxiMo.Services.DTOs;

namespace TaxiMo.Services.Interfaces
{
    public interface IUserNotificationService : IBaseCRUDService<UserNotification>
    {
        Task<UserNotification> CreateNotificationAsync(int recipientUserId, string title, string? body, string type);
        Task<List<UserNotification>> GetNotificationsByUserIdAsync(int userId);
        Task<List<UserNotification>> GetUnreadNotificationsByUserIdAsync(int userId);
        Task<int> GetUnreadCountByUserIdAsync(int userId);
        Task<bool> MarkAsReadAsync(int notificationId);
    }
}

