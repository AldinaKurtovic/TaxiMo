using AutoMapper;
using Microsoft.EntityFrameworkCore;
using TaxiMo.Model.Exceptions;
using TaxiMo.Services.Database;
using TaxiMo.Services.Database.Entities;
using TaxiMo.Services.DTOs;

namespace TaxiMo.Services.Services.RideStateMachine
{
    public abstract class BaseRideState
    {
        protected readonly TaxiMoDbContext Context;
        protected readonly IMapper Mapper;

        protected BaseRideState(TaxiMoDbContext context, IMapper mapper)
        {
            Context = context;
            Mapper = mapper;
        }

        public virtual async Task<Ride> CreateAsync(RideCreateDto dto)
        {
            throw new UserException("Not allowed");
        }

        public virtual async Task<Ride> AcceptAsync(int rideId, int driverId)
        {
            throw new UserException("Not allowed");
        }

        public virtual async Task<Ride> RejectAsync(int rideId, int driverId)
        {
            throw new UserException("Not allowed");
        }

        public virtual async Task<Ride> StartAsync(int rideId)
        {
            throw new UserException("Not allowed");
        }

        public virtual async Task<Ride> CompleteAsync(int rideId)
        {
            throw new UserException("Not allowed");
        }

        public virtual async Task<Ride> CancelAsync(int rideId, bool isAdmin)
        {
            throw new UserException("Not allowed");
        }

        protected async Task<Ride> GetRideAsync(int rideId)
        {
            var ride = await Context.Rides
                .Include(r => r.Driver)
                .Include(r => r.Rider)
                .FirstOrDefaultAsync(r => r.RideId == rideId);

            if (ride == null)
            {
                throw new UserException($"Ride with ID {rideId} not found.");
            }

            return ride;
        }
    }
}

