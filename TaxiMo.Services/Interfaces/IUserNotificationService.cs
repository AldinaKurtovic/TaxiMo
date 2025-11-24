using TaxiMo.Services.Database.Entities;

namespace TaxiMo.Services.Interfaces
{
    public interface IUserNotificationService
    {
        Task<List<UserNotification>> GetAllAsync();
        Task<UserNotification?> GetByIdAsync(int id);
        Task<UserNotification> CreateAsync(UserNotification userNotification);
        Task<UserNotification> UpdateAsync(UserNotification userNotification);
        Task<bool> DeleteAsync(int id);
    }
}

