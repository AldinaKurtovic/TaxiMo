using Microsoft.EntityFrameworkCore;
using TaxiMo.Services.Database;
using TaxiMo.Services.Database.Entities;
using TaxiMo.Services.Interfaces;

namespace TaxiMo.Services.Services
{
    public class UserNotificationService : BaseCRUDService<UserNotification>, IUserNotificationService
    {
        public UserNotificationService(TaxiMoDbContext context) : base(context)
        {
        }

        public override async Task<UserNotification> UpdateAsync(UserNotification userNotification)
        {
            var existingUserNotification = await GetByIdAsync(userNotification.NotificationId);
            if (existingUserNotification == null)
            {
                throw new TaxiMo.Model.Exceptions.UserException($"UserNotification with ID {userNotification.NotificationId} not found.");
            }

            // Update properties
            existingUserNotification.RecipientUserId = userNotification.RecipientUserId;
            existingUserNotification.Title = userNotification.Title;
            existingUserNotification.Body = userNotification.Body;
            existingUserNotification.Type = userNotification.Type;
            existingUserNotification.IsRead = userNotification.IsRead;
            existingUserNotification.SentAt = userNotification.SentAt;

            await Context.SaveChangesAsync();
            return existingUserNotification;
        }

        public async Task<UserNotification> CreateNotificationAsync(int recipientUserId, string title, string? body, string type)
        {
            var notification = new UserNotification
            {
                RecipientUserId = recipientUserId,
                Title = title,
                Body = body,
                Type = type,
                IsRead = false,
                SentAt = DateTime.UtcNow
            };

            Context.UserNotifications.Add(notification);
            await Context.SaveChangesAsync();
            return notification;
        }

        public async Task<List<UserNotification>> GetNotificationsByUserIdAsync(int userId)
        {
            return await Context.UserNotifications
                .Where(n => n.RecipientUserId == userId)
                .OrderByDescending(n => n.SentAt)
                .ToListAsync();
        }

        public async Task<List<UserNotification>> GetUnreadNotificationsByUserIdAsync(int userId)
        {
            return await Context.UserNotifications
                .Where(n => n.RecipientUserId == userId && !n.IsRead)
                .OrderByDescending(n => n.SentAt)
                .ToListAsync();
        }

        public async Task<int> GetUnreadCountByUserIdAsync(int userId)
        {
            return await Context.UserNotifications
                .CountAsync(n => n.RecipientUserId == userId && !n.IsRead);
        }

        public async Task<bool> MarkAsReadAsync(int notificationId)
        {
            var notification = await GetByIdAsync(notificationId);
            if (notification == null)
            {
                return false;
            }

            notification.IsRead = true;
            await Context.SaveChangesAsync();
            return true;
        }
    }
}

