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
    }
}

