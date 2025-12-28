using AutoMapper;
using EasyNetQ;
using Microsoft.EntityFrameworkCore;
using TaxiMo.Model.Messages;
using TaxiMo.Services.Database;
using TaxiMo.Services.Database.Entities;
using TaxiMo.Services.Interfaces;
using TaxiMo.Services.Services.RideStateMachine;

namespace TaxiMo.Services.Services
{
    public class RideService : BaseCRUDService<Ride>, IRideService
    {
        private readonly IRidePriceCalculator _priceCalculator;
        private readonly RideStateFactory _stateFactory;
        private readonly IMapper _mapper;
        private readonly IDriverService _driverService;

        public RideService(
            TaxiMoDbContext context, 
            IRidePriceCalculator priceCalculator,
            RideStateFactory stateFactory,
            IMapper mapper,
            IDriverService driverService) : base(context)
        {
            _priceCalculator = priceCalculator;
            _stateFactory = stateFactory;
            _mapper = mapper;
            _driverService = driverService;
        }

        public async Task<List<Ride>> GetAllAsync(string? search = null, string? status = null)
        {
            var query = DbSet
                .Include(r => r.Driver)
                    .ThenInclude(d => d.DriverAvailabilities)
                .Include(r => r.Rider)
                .Include(r => r.PickupLocation)
                .Include(r => r.DropoffLocation)
                .Include(r => r.Vehicle)
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

        public override async Task<Ride> CreateAsync(Ride ride)
        {
            var (createdRide, _) = await CreateRideWithPaymentAsync(ride, "cash");
            return createdRide;
        }

        public async Task<(Ride Ride, Payment Payment)> CreateRideWithPaymentAsync(Ride ride, string paymentMethod)
        {
            // Calculate fare estimate if distance is provided
            if (ride.DistanceKm.HasValue && ride.DistanceKm.Value > 0)
            {
                var distanceKm = (double)ride.DistanceKm.Value;
                ride.FareEstimate = _priceCalculator.CalculateFareEstimate(distanceKm, _priceCalculator.PricePerKm);
            }

            // Use InitialRideState to initialize the ride
            var initialState = _stateFactory.GetInitialState();
            initialState.InitializeRide(ride);
            Context.Rides.Add(ride);
            await Context.SaveChangesAsync();

            // Create payment record with provided payment method
            var payment = new Payment
            {
                RideId = ride.RideId,
                UserId = ride.RiderId,
                Amount = ride.FareEstimate ?? 0,
                Currency = "KM",
                Method = paymentMethod ?? "cash",
                Status = "pending",
                TransactionRef = null,
                PaidAt = null
            };

            Context.Payments.Add(payment);
            await Context.SaveChangesAsync();

            // Publish RabbitMQ message after successful save
            await PublishRideCreatedMessageAsync(ride);

            return (ride, payment);
        }

        private async Task PublishRideCreatedMessageAsync(Ride ride)
        {
            try
            {
                using var bus = RabbitHutch.CreateBus("host=localhost");

                // Load location entities to get their string representation
                var pickupLocation = await Context.Locations.FindAsync(ride.PickupLocationId);
                var dropoffLocation = await Context.Locations.FindAsync(ride.DropoffLocationId);

                var pickupLocationString = FormatLocationString(pickupLocation);
                var dropoffLocationString = FormatLocationString(dropoffLocation);

                var rideCreatedMessage = new RideCreated
                {
                    RideId = ride.RideId,
                    RiderId = ride.RiderId,
                    DriverId = ride.DriverId,
                    PickupLocation = pickupLocationString,
                    DropoffLocation = dropoffLocationString,
                    FareEstimate = ride.FareEstimate
                };

                await bus.PubSub.PublishAsync(rideCreatedMessage);
            }
            catch (Exception ex)
            {
                // Log error but don't fail the ride creation if RabbitMQ is unavailable
                Console.WriteLine($"Failed to publish RabbitMQ message: {ex.Message}");
            }
        }

        private static string FormatLocationString(Location? location)
        {
            if (location == null)
            {
                return string.Empty;
            }

            var parts = new List<string> { location.Name };

            if (!string.IsNullOrWhiteSpace(location.AddressLine))
            {
                parts.Add(location.AddressLine);
            }

            if (!string.IsNullOrWhiteSpace(location.City))
            {
                parts.Add(location.City);
            }

            return string.Join(", ", parts);
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

        public async Task<Ride> AcceptRideAsync(int rideId, int driverId)
        {
            var ride = await GetByIdAsync(rideId);
            if (ride == null)
            {
                throw new TaxiMo.Model.Exceptions.UserException($"Ride with ID {rideId} not found.");
            }

            var state = _stateFactory.GetState(ride.Status);
            var updatedRide = await state.AcceptAsync(rideId, driverId);
            await Context.SaveChangesAsync();
            return updatedRide;
        }

        public async Task<Ride> RejectRideAsync(int rideId, int driverId)
        {
            var ride = await GetByIdAsync(rideId);
            if (ride == null)
            {
                throw new TaxiMo.Model.Exceptions.UserException($"Ride with ID {rideId} not found.");
            }

            var state = _stateFactory.GetState(ride.Status);
            var updatedRide = await state.RejectAsync(rideId, driverId);
            await Context.SaveChangesAsync();
            return updatedRide;
        }

        public async Task<Ride> StartRideAsync(int rideId)
        {
            var ride = await GetByIdAsync(rideId);
            if (ride == null)
            {
                throw new TaxiMo.Model.Exceptions.UserException($"Ride with ID {rideId} not found.");
            }

            var state = _stateFactory.GetState(ride.Status);
            var updatedRide = await state.StartAsync(rideId);
            await Context.SaveChangesAsync();
            return updatedRide;
        }

        public async Task<Ride> CompleteRideAsync(int rideId)
        {
            var ride = await GetByIdAsync(rideId);
            if (ride == null)
            {
                throw new TaxiMo.Model.Exceptions.UserException($"Ride with ID {rideId} not found.");
            }

            var state = _stateFactory.GetState(ride.Status);
            var updatedRide = await state.CompleteAsync(rideId);
            await Context.SaveChangesAsync();
            return updatedRide;
        }

        public async Task<Ride> CancelRideAsync(int rideId, bool isAdmin)
        {
            var ride = await GetByIdAsync(rideId);
            if (ride == null)
            {
                throw new TaxiMo.Model.Exceptions.UserException($"Ride with ID {rideId} not found.");
            }

            var state = _stateFactory.GetState(ride.Status);
            var updatedRide = await state.CancelAsync(rideId, isAdmin);
            await Context.SaveChangesAsync();
            return updatedRide;
        }

        public async Task<Ride> AssignDriverAsync(int rideId, int driverId)
        {
            // Validate that the ride exists
            var ride = await Context.Rides
                .Include(r => r.Driver)
                .Include(r => r.Vehicle)
                .FirstOrDefaultAsync(r => r.RideId == rideId);

            if (ride == null)
            {
                throw new TaxiMo.Model.Exceptions.UserException($"Ride with ID {rideId} not found.");
            }

            // Define statusLower once at the top and reuse it
            var statusLower = ride.Status.ToLower();

            // Reject assignment if ride is in a finished state
            if (statusLower == RideStatuses.Completed || statusLower == RideStatuses.Cancelled)
            {
                throw new TaxiMo.Model.Exceptions.UserException("Cannot assign driver to a finished ride.");
            }

            // Driver can only be assigned to requested rides
            if (statusLower != RideStatuses.Requested)
            {
                throw new TaxiMo.Model.Exceptions.UserException("Driver can only be assigned to requested rides.");
            }

            // Track old driver ID for re-assignment handling
            var oldDriverId = ride.DriverId;

            // Validate that the driver exists
            var driver = await _driverService.GetByIdAsync(driverId);
            if (driver == null)
            {
                throw new TaxiMo.Model.Exceptions.UserException($"Driver with ID {driverId} not found.");
            }

            // Validate that the driver is active
            if (driver.Status.ToLower() != "active")
            {
                throw new TaxiMo.Model.Exceptions.UserException($"Driver with ID {driverId} is not active.");
            }

            // Validate that the driver is currently free (not assigned to any active ride)
            // Note: If re-assigning the same driver, skip this check
            if (oldDriverId != driverId)
            {
                var freeDrivers = await _driverService.GetFreeDriversAsync();
                if (!freeDrivers.Any(d => d.DriverId == driverId))
                {
                    throw new TaxiMo.Model.Exceptions.UserException($"Driver with ID {driverId} is not currently available.");
                }
            }

            // Select the first active vehicle for the driver
            var vehicle = driver.Vehicles?.FirstOrDefault(v => v.Status.ToLower() == "active");
            if (vehicle == null)
            {
                throw new TaxiMo.Model.Exceptions.UserException($"Driver with ID {driverId} does not have an active vehicle assigned.");
            }

            // Handle re-assignment: if ride already has a different driver, the old driver becomes available again
            // (Availability is managed through ride assignments - removing the ride assignment makes driver available)
            // Assign the new driver and vehicle to the ride
            ride.DriverId = driverId;
            ride.VehicleId = vehicle.VehicleId;
            // Keep status as "requested" - do NOT change to "active"
            // Status will transition to "active" only when driver accepts the ride

            await Context.SaveChangesAsync();

            // Reload the ride with all related entities for the response
            var updatedRide = await Context.Rides
                .Include(r => r.Driver)
                    .ThenInclude(d => d.DriverAvailabilities)
                .Include(r => r.Rider)
                .Include(r => r.PickupLocation)
                .Include(r => r.DropoffLocation)
                .Include(r => r.Vehicle)
                .FirstOrDefaultAsync(r => r.RideId == rideId);

            return updatedRide ?? ride;
        }
    }
}

