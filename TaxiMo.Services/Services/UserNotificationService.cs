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
    }
}

