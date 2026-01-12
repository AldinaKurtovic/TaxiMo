using AutoMapper;
using TaxiMo.Model.Exceptions;
using TaxiMo.Services.Database;
using TaxiMo.Services.Database.Entities;

namespace TaxiMo.Services.Services.RideStateMachine
{
    public class RequestedRideState : BaseRideState
    {
        public RequestedRideState(TaxiMoDbContext context, IMapper mapper)
            : base(context, mapper)
        {
        }

        public override async Task<Ride> AcceptAsync(int rideId, int driverId)
        {
            var ride = await GetRideAsync(rideId);

            // Validate that the ride is assigned to this driver
            if (ride.DriverId != driverId)
            {
                throw new UserException("You can only accept rides assigned to you.");
            }

            // Validate that the ride is in Requested state
            if (ride.Status.ToLower() != RideStatuses.Requested)
            {
                throw new UserException($"Cannot accept ride. Current status is {ride.Status}.");
            }

            ride.Status = RideStatuses.Accepted;
            ride.DriverId = driverId;
            // Note: AcceptedAt field doesn't exist in the database schema, so we skip it

            return ride;
        }

        public override async Task<Ride> RejectAsync(int rideId, int driverId)
        {
            var ride = await GetRideAsync(rideId);

            // Validate that the ride is assigned to this driver
            if (ride.DriverId != driverId)
            {
                throw new UserException("You can only reject rides assigned to you.");
            }

            // Validate that the ride is in Requested state
            if (ride.Status.ToLower() != RideStatuses.Requested)
            {
                throw new UserException($"Cannot reject ride. Current status is {ride.Status}.");
            }

            ride.Status = RideStatuses.Cancelled;

            return ride;
        }

        public override async Task<Ride> CancelAsync(int rideId, bool isAdmin)
        {
            var ride = await GetRideAsync(rideId);

            // Validate that the ride is in Requested state
            if (ride.Status.ToLower() != RideStatuses.Requested)
            {
                throw new UserException($"Cannot cancel ride. Current status is {ride.Status}.");
            }

            ride.Status = RideStatuses.Cancelled;

            return ride;
        }
    }
}

