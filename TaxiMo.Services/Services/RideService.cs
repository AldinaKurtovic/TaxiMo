using Microsoft.EntityFrameworkCore;
using TaxiMo.Model.Exceptions;
using TaxiMo.Services.Database;
using TaxiMo.Services.Database.Entities;
using TaxiMo.Services.Interfaces;

namespace TaxiMo.Services.Services
{
    public class RideService : IRideService
    {
        private readonly TaxiMoDbContext _context;

        public RideService(TaxiMoDbContext context)
        {
            _context = context;
        }

        public async Task<List<Ride>> GetAllAsync(string? search = null, string? status = null)
        {
            var query = _context.Rides
                .Include(r => r.Driver)
                .Include(r => r.Rider)
                .AsQueryable();

            if (!string.IsNullOrWhiteSpace(search))
            {
                search = search.Trim();
                query = query.Where(r =>
                    r.Status.Contains(search) ||
                    (r.Driver != null && (r.Driver.FirstName.Contains(search) || r.Driver.LastName.Contains(search))) ||
                    (r.Rider != null && (r.Rider.FirstName.Contains(search) || r.Rider.LastName.Contains(search))));
            }

            if (!string.IsNullOrWhiteSpace(status))
            {
                status = status.Trim();
                query = query.Where(r => r.Status == status);
            }

            return await query.ToListAsync();
        }

        public async Task<Ride?> GetByIdAsync(int id)
        {
            return await _context.Rides.FindAsync(id);
        }

        public async Task<Ride> CreateAsync(Ride ride)
        {
            _context.Rides.Add(ride);
            await _context.SaveChangesAsync();

            return ride;
        }

        public async Task<Ride> UpdateAsync(Ride ride)
        {
            var existingRide = await _context.Rides.FindAsync(ride.RideId);
            if (existingRide == null)
            {
                throw new UserException($"Ride with ID {ride.RideId} not found.");
            }

            // Update properties
            existingRide.RiderId = ride.RiderId;
            existingRide.DriverId = ride.DriverId;
            existingRide.VehicleId = ride.VehicleId;
            existingRide.PickupLocationId = ride.PickupLocationId;
            existingRide.DropoffLocationId = ride.DropoffLocationId;
            existingRide.RequestedAt = ride.RequestedAt;
            existingRide.StartedAt = ride.StartedAt;
            existingRide.CompletedAt = ride.CompletedAt;
            existingRide.Status = ride.Status;
            existingRide.FareEstimate = ride.FareEstimate;
            existingRide.FareFinal = ride.FareFinal;
            existingRide.DistanceKm = ride.DistanceKm;
            existingRide.DurationMin = ride.DurationMin;

            await _context.SaveChangesAsync();

            return existingRide;
        }

        public async Task<bool> DeleteAsync(int id)
        {
            var ride = await _context.Rides.FindAsync(id);
            if (ride == null)
            {
                return false;
            }

            _context.Rides.Remove(ride);
            await _context.SaveChangesAsync();

            return true;
        }
    }
}

