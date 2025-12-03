using Microsoft.EntityFrameworkCore;
using TaxiMo.Model.Exceptions;
using TaxiMo.Services.Database;
using TaxiMo.Services.Database.Entities;
using TaxiMo.Services.Interfaces;

namespace TaxiMo.Services.Services
{
    public class UserNotificationService : IUserNotificationService
    {
        private readonly TaxiMoDbContext _context;

        public UserNotificationService(TaxiMoDbContext context)
        {
            _context = context;
        }

        public async Task<List<UserNotification>> GetAllAsync()
        {
            return await _context.UserNotifications.ToListAsync();
        }

        public async Task<UserNotification?> GetByIdAsync(int id)
        {
            return await _context.UserNotifications.FindAsync(id);
        }

        public async Task<UserNotification> CreateAsync(UserNotification userNotification)
        {
            _context.UserNotifications.Add(userNotification);
            await _context.SaveChangesAsync();

            return userNotification;
        }

        public async Task<UserNotification> UpdateAsync(UserNotification userNotification)
        {
            var existingUserNotification = await _context.UserNotifications.FindAsync(userNotification.NotificationId);
            if (existingUserNotification == null)
            {
                throw new UserException($"UserNotification with ID {userNotification.NotificationId} not found.");
            }

            // Update properties
            existingUserNotification.RecipientUserId = userNotification.RecipientUserId;
            existingUserNotification.Title = userNotification.Title;
            existingUserNotification.Body = userNotification.Body;
            existingUserNotification.Type = userNotification.Type;
            existingUserNotification.IsRead = userNotification.IsRead;
            existingUserNotification.SentAt = userNotification.SentAt;

            await _context.SaveChangesAsync();

            return existingUserNotification;
        }

        public async Task<bool> DeleteAsync(int id)
        {
            var userNotification = await _context.UserNotifications.FindAsync(id);
            if (userNotification == null)
            {
                return false;
            }

            _context.UserNotifications.Remove(userNotification);
            await _context.SaveChangesAsync();

            return true;
        }
    }
}

