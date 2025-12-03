using Microsoft.EntityFrameworkCore;
using TaxiMo.Model.Exceptions;
using TaxiMo.Services.Database;
using TaxiMo.Services.Database.Entities;
using TaxiMo.Services.Interfaces;

namespace TaxiMo.Services.Services
{
    public class LocationService : ILocationService
    {
        private readonly TaxiMoDbContext _context;

        public LocationService(TaxiMoDbContext context)
        {
            _context = context;
        }

        public async Task<List<Location>> GetAllAsync()
        {
            return await _context.Locations.ToListAsync();
        }

        public async Task<Location?> GetByIdAsync(int id)
        {
            return await _context.Locations.FindAsync(id);
        }

        public async Task<Location> CreateAsync(Location location)
        {
            location.CreatedAt = DateTime.UtcNow;
            location.UpdatedAt = DateTime.UtcNow;

            _context.Locations.Add(location);
            await _context.SaveChangesAsync();

            return location;
        }

        public async Task<Location> UpdateAsync(Location location)
        {
            var existingLocation = await _context.Locations.FindAsync(location.LocationId);
            if (existingLocation == null)
            {
                throw new UserException($"Location with ID {location.LocationId} not found.");
            }

            // Update properties
            existingLocation.UserId = location.UserId;
            existingLocation.Name = location.Name;
            existingLocation.AddressLine = location.AddressLine;
            existingLocation.City = location.City;
            existingLocation.Lat = location.Lat;
            existingLocation.Lng = location.Lng;
            existingLocation.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            return existingLocation;
        }

        public async Task<bool> DeleteAsync(int id)
        {
            var location = await _context.Locations.FindAsync(id);
            if (location == null)
            {
                return false;
            }

            _context.Locations.Remove(location);
            await _context.SaveChangesAsync();

            return true;
        }
    }
}

