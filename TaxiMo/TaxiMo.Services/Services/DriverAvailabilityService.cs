using TaxiMo.Services.Database;
using TaxiMo.Services.Database.Entities;
using TaxiMo.Services.Interfaces;

namespace TaxiMo.Services.Services
{
    public class DriverAvailabilityService : BaseCRUDService<DriverAvailability>, IDriverAvailabilityService
    {
        public DriverAvailabilityService(TaxiMoDbContext context) : base(context)
        {
        }

        public override async Task<DriverAvailability> CreateAsync(DriverAvailability driverAvailability)
        {
            driverAvailability.UpdatedAt = DateTime.UtcNow;
            return await base.CreateAsync(driverAvailability);
        }

        public override async Task<DriverAvailability> UpdateAsync(DriverAvailability driverAvailability)
        {
            var existingDriverAvailability = await GetByIdAsync(driverAvailability.AvailabilityId);
            if (existingDriverAvailability == null)
            {
                throw new TaxiMo.Model.Exceptions.UserException($"DriverAvailability with ID {driverAvailability.AvailabilityId} not found.");
            }

            // Update properties
            existingDriverAvailability.DriverId = driverAvailability.DriverId;
            existingDriverAvailability.IsOnline = driverAvailability.IsOnline;
            existingDriverAvailability.CurrentLat = driverAvailability.CurrentLat;
            existingDriverAvailability.CurrentLng = driverAvailability.CurrentLng;
            existingDriverAvailability.LastLocationUpdate = driverAvailability.LastLocationUpdate;
            existingDriverAvailability.UpdatedAt = DateTime.UtcNow;

            await Context.SaveChangesAsync();
            return existingDriverAvailability;
        }
    }
}

