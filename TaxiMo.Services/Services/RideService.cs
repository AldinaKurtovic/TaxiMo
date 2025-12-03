using Microsoft.EntityFrameworkCore;
using TaxiMo.Services.Database;
using TaxiMo.Services.Database.Entities;
using TaxiMo.Services.Interfaces;

namespace TaxiMo.Services.Services
{
    public class RideService : BaseCRUDService<Ride>, IRideService
    {
        public RideService(TaxiMoDbContext context) : base(context)
        {
        }

        public async Task<List<Ride>> GetAllAsync(string? search = null, string? status = null)
        {
            var query = DbSet
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

        public override async Task<Ride> UpdateAsync(Ride ride)
        {
            var existingRide = await GetByIdAsync(ride.RideId);
            if (existingRide == null)
            {
                throw new TaxiMo.Model.Exceptions.UserException($"Ride with ID {ride.RideId} not found.");
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

            await Context.SaveChangesAsync();
            return existingRide;
        }
    }
}

