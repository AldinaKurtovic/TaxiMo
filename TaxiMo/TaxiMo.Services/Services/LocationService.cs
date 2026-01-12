using Microsoft.EntityFrameworkCore;
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

        /// <summary>
        /// Gets an existing location by latitude and longitude, or creates a new one if it doesn't exist.
        /// This prevents duplicate locations in the database by reusing existing locations with the same coordinates.
        /// </summary>
        public async Task<Location> GetOrCreateLocationAsync(decimal lat, decimal lng, string name, string? addressLine = null, string? city = null, int? userId = null)
        {
            // Check if a location with the same latitude and longitude already exists
            var existingLocation = await Context.Locations
                .FirstOrDefaultAsync(l => l.Lat == lat && l.Lng == lng);

            if (existingLocation != null)
            {
                // Return existing location - reuse it to avoid duplicates
                return existingLocation;
            }

            // Create new location if it doesn't exist
            var newLocation = new Location
            {
                Lat = lat,
                Lng = lng,
                Name = name,
                AddressLine = addressLine,
                City = city,
                UserId = userId,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            Context.Locations.Add(newLocation);
            await Context.SaveChangesAsync();

            return newLocation;
        }

        /// <summary>
        /// Creates a location, checking for duplicates first using GetOrCreateLocationAsync.
        /// This ensures no duplicate locations are created even when CreateAsync is called directly.
        /// </summary>
        public override async Task<Location> CreateAsync(Location location)
        {
            // Use GetOrCreateLocation to prevent duplicates
            return await GetOrCreateLocationAsync(
                location.Lat,
                location.Lng,
                location.Name,
                location.AddressLine,
                location.City,
                location.UserId
            );
        }

        public override async Task<Location> UpdateAsync(Location location)
        {
            var existingLocation = await GetByIdAsync(location.LocationId);
            if (existingLocation == null)
            {
                throw new TaxiMo.Model.Exceptions.UserException($"Location with ID {location.LocationId} not found.");
            }

            // Check if another location with the same lat/lng already exists (excluding the current location)
            var duplicateLocation = await Context.Locations
                .FirstOrDefaultAsync(l => l.Lat == location.Lat && l.Lng == location.Lng && l.LocationId != location.LocationId);

            if (duplicateLocation != null)
            {
                throw new TaxiMo.Model.Exceptions.UserException(
                    $"A location with the same coordinates (lat: {location.Lat}, lng: {location.Lng}) already exists. " +
                    $"Consider using the existing location ID: {duplicateLocation.LocationId}");
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

