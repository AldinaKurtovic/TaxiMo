using TaxiMo.Services.Database;
using TaxiMo.Services.Database.Entities;
using TaxiMo.Services.Interfaces;

namespace TaxiMo.Services.Services
{
    public class LocationService : BaseCRUDService<Location>, ILocationService
    {
        public LocationService(TaxiMoDbContext context) : base(context)
        {
        }

        public override async Task<Location> CreateAsync(Location location)
        {
            location.CreatedAt = DateTime.UtcNow;
            location.UpdatedAt = DateTime.UtcNow;
            return await base.CreateAsync(location);
        }

        public override async Task<Location> UpdateAsync(Location location)
        {
            var existingLocation = await GetByIdAsync(location.LocationId);
            if (existingLocation == null)
            {
                throw new TaxiMo.Model.Exceptions.UserException($"Location with ID {location.LocationId} not found.");
            }

            // Update properties
            existingLocation.UserId = location.UserId;
            existingLocation.Name = location.Name;
            existingLocation.AddressLine = location.AddressLine;
            existingLocation.City = location.City;
            existingLocation.Lat = location.Lat;
            existingLocation.Lng = location.Lng;
            existingLocation.UpdatedAt = DateTime.UtcNow;

            await Context.SaveChangesAsync();
            return existingLocation;
        }
    }
}

