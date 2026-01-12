using AutoMapper;
using TaxiMo.Services.Database;
using TaxiMo.Services.Database.Entities;
using TaxiMo.Services.DTOs;

namespace TaxiMo.Services.Services.RideStateMachine
{
    public class InitialRideState : BaseRideState
    {
        public InitialRideState(TaxiMoDbContext context, IMapper mapper)
            : base(context, mapper)
        {
        }

        public override async Task<Ride> CreateAsync(RideCreateDto dto)
        {
            var ride = Mapper.Map<Ride>(dto);
            InitializeRide(ride);
            Context.Rides.Add(ride);
            // Note: SaveChangesAsync is called by RideService

            return ride;
        }

        public void InitializeRide(Ride ride)
        {
            ride.Status = RideStatuses.Requested;
            ride.RequestedAt = DateTime.UtcNow;
        }
    }
}

