using AutoMapper;
using TaxiMo.Model.Exceptions;
using TaxiMo.Services.Database;
using TaxiMo.Services.Database.Entities;

namespace TaxiMo.Services.Services.RideStateMachine
{
    public class AcceptedRideState : BaseRideState
    {
        public AcceptedRideState(TaxiMoDbContext context, IMapper mapper)
            : base(context, mapper)
        {
        }

        public override async Task<Ride> StartAsync(int rideId)
        {
            var ride = await GetRideAsync(rideId);

            // Validate that the ride is in Accepted state
            if (ride.Status.ToLower() != RideStatuses.Accepted)
            {
                throw new UserException($"Cannot start ride. Current status is {ride.Status}.");
            }

            ride.Status = RideStatuses.Active;
            ride.StartedAt = DateTime.UtcNow;

            return ride;
        }

        public override async Task<Ride> CancelAsync(int rideId, bool isAdmin)
        {
            var ride = await GetRideAsync(rideId);

            // Validate that the ride is in Accepted state
            if (ride.Status.ToLower() != RideStatuses.Accepted)
            {
                throw new UserException($"Cannot cancel ride. Current status is {ride.Status}.");
            }

            ride.Status = RideStatuses.Cancelled;

            return ride;
        }
    }
}

