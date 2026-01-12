using Microsoft.EntityFrameworkCore;
using TaxiMo.Services.Database;
using TaxiMo.Services.Database.Entities;
using TaxiMo.Services.Interfaces;

namespace TaxiMo.Services.Services
{
    public class DriverNotificationService : BaseCRUDService<DriverNotification>, IDriverNotificationService
    {
        public DriverNotificationService(TaxiMoDbContext context) : base(context)
        {
        }

        public override async Task<DriverNotification> UpdateAsync(DriverNotification driverNotification)
        {
            var existingDriverNotification = await GetByIdAsync(driverNotification.NotificationId);
            if (existingDriverNotification == null)
            {
                throw new TaxiMo.Model.Exceptions.UserException($"DriverNotification with ID {driverNotification.NotificationId} not found.");
            }

            // Update properties
            existingDriverNotification.RecipientDriverId = driverNotification.RecipientDriverId;
            existingDriverNotification.Title = driverNotification.Title;
            existingDriverNotification.Body = driverNotification.Body;
            existingDriverNotification.Type = driverNotification.Type;
            existingDriverNotification.IsRead = driverNotification.IsRead;
            existingDriverNotification.SentAt = driverNotification.SentAt;

            await Context.SaveChangesAsync();
            return existingDriverNotification;
        }

        public async Task<DriverNotification> CreateNotificationAsync(int recipientDriverId, string title, string? body, string type)
        {
            var notification = new DriverNotification
            {
                RecipientDriverId = recipientDriverId,
                Title = title,
                Body = body,
                Type = type,
                IsRead = false,
                SentAt = DateTime.UtcNow
            };

            Context.DriverNotifications.Add(notification);
            await Context.SaveChangesAsync();
            return notification;
        }

        public async Task<List<DriverNotification>> GetNotificationsByDriverIdAsync(int driverId)
        {
            return await Context.DriverNotifications
                .Where(n => n.RecipientDriverId == driverId)
                .OrderByDescending(n => n.SentAt)
                .ToListAsync();
        }

        public async Task<List<DriverNotification>> GetUnreadNotificationsByDriverIdAsync(int driverId)
        {
            return await Context.DriverNotifications
                .Where(n => n.RecipientDriverId == driverId && !n.IsRead)
                .OrderByDescending(n => n.SentAt)
                .ToListAsync();
        }

        public async Task<int> GetUnreadCountByDriverIdAsync(int driverId)
        {
            return await Context.DriverNotifications
                .CountAsync(n => n.RecipientDriverId == driverId && !n.IsRead);
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

