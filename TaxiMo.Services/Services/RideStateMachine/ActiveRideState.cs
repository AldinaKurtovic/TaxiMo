using AutoMapper;
using TaxiMo.Model.Exceptions;
using TaxiMo.Services.Database;
using TaxiMo.Services.Database.Entities;

namespace TaxiMo.Services.Services.RideStateMachine
{
    public class ActiveRideState : BaseRideState
    {
        public ActiveRideState(TaxiMoDbContext context, IMapper mapper)
            : base(context, mapper)
        {
        }

        public override async Task<Ride> CompleteAsync(int rideId)
        {
            var ride = await GetRideAsync(rideId);

            // Validate that the ride is in Active state
            if (ride.Status.ToLower() != RideStatuses.Active)
            {
                throw new UserException($"Cannot complete ride. Current status is {ride.Status}.");
            }

            ride.Status = RideStatuses.Completed;
            ride.CompletedAt = DateTime.UtcNow;

            return ride;
        }

        public override async Task<Ride> CancelAsync(int rideId, bool isAdmin)
        {
            var ride = await GetRideAsync(rideId);

            // Validate that the ride is in Active state
            if (ride.Status.ToLower() != RideStatuses.Active)
            {
                throw new UserException($"Cannot cancel ride. Current status is {ride.Status}.");
            }

            // Only Admin can cancel Active rides
            if (!isAdmin)
            {
                throw new UserException("Only admin can cancel an active ride");
            }

            ride.Status = RideStatuses.Cancelled;

            return ride;
        }
    }
}

