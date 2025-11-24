using Microsoft.EntityFrameworkCore;
using TaxiMo.Services.Database;
using TaxiMo.Services.Database.Entities;
using TaxiMo.Services.Interfaces;

namespace TaxiMo.Services.Services
{
    public class DriverNotificationService : IDriverNotificationService
    {
        private readonly TaxiMoDbContext _context;

        public DriverNotificationService(TaxiMoDbContext context)
        {
            _context = context;
        }

        public async Task<List<DriverNotification>> GetAllAsync()
        {
            return await _context.DriverNotifications.ToListAsync();
        }

        public async Task<DriverNotification?> GetByIdAsync(int id)
        {
            return await _context.DriverNotifications.FindAsync(id);
        }

        public async Task<DriverNotification> CreateAsync(DriverNotification driverNotification)
        {
            _context.DriverNotifications.Add(driverNotification);
            await _context.SaveChangesAsync();

            return driverNotification;
        }

        public async Task<DriverNotification> UpdateAsync(DriverNotification driverNotification)
        {
            var existingDriverNotification = await _context.DriverNotifications.FindAsync(driverNotification.NotificationId);
            if (existingDriverNotification == null)
            {
                throw new KeyNotFoundException($"DriverNotification with ID {driverNotification.NotificationId} not found.");
            }

            // Update properties
            existingDriverNotification.RecipientDriverId = driverNotification.RecipientDriverId;
            existingDriverNotification.Title = driverNotification.Title;
            existingDriverNotification.Body = driverNotification.Body;
            existingDriverNotification.Type = driverNotification.Type;
            existingDriverNotification.IsRead = driverNotification.IsRead;
            existingDriverNotification.SentAt = driverNotification.SentAt;

            await _context.SaveChangesAsync();

            return existingDriverNotification;
        }

        public async Task<bool> DeleteAsync(int id)
        {
            var driverNotification = await _context.DriverNotifications.FindAsync(id);
            if (driverNotification == null)
            {
                return false;
            }

            _context.DriverNotifications.Remove(driverNotification);
            await _context.SaveChangesAsync();

            return true;
        }
    }
}

