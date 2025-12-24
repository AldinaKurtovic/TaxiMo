using AutoMapper;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Linq;
using System.Security.Claims;
using TaxiMo.Services.Database;
using TaxiMo.Services.Database.Entities;
using TaxiMo.Services.DTOs;
using TaxiMo.Services.Interfaces;

namespace TaxiMoWebAPI.Controllers
{
    [Authorize(Roles = "User,Driver,Admin")]
    public class RideController : BaseCRUDController<Ride, RideDto, RideCreateDto, RideUpdateDto>
    {
        protected override string EntityName => "Ride";
        private readonly IRideService _rideService;
        private readonly IDriverService _driverService;
        private readonly TaxiMoDbContext _context;

        public RideController(
            IRideService rideService,
            IDriverService driverService,
            TaxiMoDbContext context,
            AutoMapper.IMapper mapper,
            ILogger<RideController> logger) 
            : base(rideService, mapper, logger)
        {
            _rideService = rideService;
            _driverService = driverService;
            _context = context;
        }

        // GET: api/Ride?search=xxx&status=xxx
        // Override base GetAll to use IRideService.GetAllAsync with search and status parameters
        [HttpGet]
        public override async Task<ActionResult<IEnumerable<RideDto>>> GetAll([FromQuery] string? search = null, [FromQuery] string? status = null)
        {
            try
            {
                var rides = await _rideService.GetAllAsync(search, status);
                var responses = Mapper.Map<List<RideResponse>>(rides);
                // Return RideResponse list (will be serialized correctly by ASP.NET Core)
                return new OkObjectResult(responses);
            }
            catch (Exception ex)
            {
                Logger.LogError(ex, "Error retrieving rides");
                return StatusCode(500, new { message = "An error occurred while retrieving rides" });
            }
        }

        // POST: api/Ride
        // Override base Create to add logging and better error handling
        [HttpPost]
        public override async Task<ActionResult<RideDto>> Create(RideCreateDto createDto)
        {
            try
            {
                // Log authenticated user information
                var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                var username = User.FindFirst(ClaimTypes.Name)?.Value;
                var roles = User.FindAll(ClaimTypes.Role).Select(c => c.Value).ToList();
                
                Logger.LogInformation(
                    "Ride creation request - UserId: {UserId}, Username: {Username}, Roles: {Roles}",
                    userId, username, string.Join(", ", roles));

                Logger.LogInformation(
                    "Ride creation request - RiderId: {RiderId}, DriverId: {DriverId}, PickupLocationId: {PickupLocationId}, DropoffLocationId: {DropoffLocationId}",
                    createDto.RiderId, createDto.DriverId, createDto.PickupLocationId, createDto.DropoffLocationId);

                if (!ModelState.IsValid)
                {
                    Logger.LogWarning("Ride creation failed - ModelState invalid: {ModelState}", 
                        string.Join(", ", ModelState.SelectMany(x => x.Value?.Errors.Select(e => e.ErrorMessage) ?? Enumerable.Empty<string>())));
                    return BadRequest(ModelState);
                }

                // Load driver WITH vehicles to select the first active vehicle
                var driver = await _context.Drivers
                    .Include(d => d.Vehicles)
                    .FirstOrDefaultAsync(d => d.DriverId == createDto.DriverId);

                if (driver == null)
                {
                    Logger.LogWarning("Ride creation failed - Driver not found: {DriverId}", createDto.DriverId);
                    return BadRequest(new { message = $"Driver with ID {createDto.DriverId} not found" });
                }

                // Select the first active vehicle for the driver
                var vehicle = driver.Vehicles?.FirstOrDefault(v => v.Status.ToLower() == "active");
                if (vehicle == null)
                {
                    Logger.LogWarning("Ride creation failed - Driver does not have an active vehicle: {DriverId}", createDto.DriverId);
                    return BadRequest(new { message = "Selected driver does not have an active vehicle assigned" });
                }

                // MAP FIRST - Create entity from DTO
                var ride = Mapper.Map<Ride>(createDto);

                // ASSIGN VEHICLE AFTER MAPPING - This ensures AutoMapper doesn't overwrite it
                ride.VehicleId = vehicle.VehicleId;
                Logger.LogInformation("Selected vehicle for driver {DriverId}: VehicleId {VehicleId}", createDto.DriverId, vehicle.VehicleId);

                // Get payment method from DTO (default to "cash" if not provided)
                var paymentMethod = createDto.PaymentMethod ?? "cash";

                // Use service to create ride with payment (handles fare calculation, payment creation, etc.)
                var (createdRide, createdPayment) = await _rideService.CreateRideWithPaymentAsync(ride, paymentMethod);

                Logger.LogInformation("Ride created successfully - RideId: {RideId}, PaymentId: {PaymentId}", createdRide.RideId, createdPayment.PaymentId);

                // Return custom booking response with ride and payment information
                var bookingResponse = new
                {
                    rideId = createdRide.RideId,
                    paymentId = createdPayment.PaymentId,
                    totalAmount = createdPayment.Amount,
                    currency = createdPayment.Currency,
                    message = "Ride booked successfully"
                };

                return CreatedAtAction(nameof(GetById), new { id = createdRide.RideId }, bookingResponse);
            }
            catch (Exception ex)
            {
                Logger.LogError(ex, "Error creating ride - Request: {@Request}", createDto);
                return StatusCode(500, new { message = $"An error occurred while creating the {EntityName}" });
            }
        }

        // PUT: api/Ride/{id}/accept
        [HttpPut("{id}/accept")]
        [Authorize(Roles = "Driver")]
        public async Task<ActionResult<RideDto>> AcceptRide(int id)
        {
            try
            {
                var driverIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                if (string.IsNullOrEmpty(driverIdClaim) || !int.TryParse(driverIdClaim, out int driverId))
                {
                    return Unauthorized(new { message = "Driver ID not found in claims" });
                }

                var ride = await _rideService.AcceptRideAsync(id, driverId);
                var rideDto = Mapper.Map<RideDto>(ride);
                return Ok(rideDto);
            }
            catch (TaxiMo.Model.Exceptions.UserException ex)
            {
                Logger.LogWarning(ex, "Error accepting ride {RideId}", id);
                return BadRequest(new { message = ex.Message });
            }
            catch (Exception ex)
            {
                Logger.LogError(ex, "Error accepting ride {RideId}", id);
                return StatusCode(500, new { message = "An error occurred while accepting the ride" });
            }
        }

        // PUT: api/Ride/{id}/reject
        [HttpPut("{id}/reject")]
        [Authorize(Roles = "Driver")]
        public async Task<ActionResult<RideDto>> RejectRide(int id)
        {
            try
            {
                var driverIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                if (string.IsNullOrEmpty(driverIdClaim) || !int.TryParse(driverIdClaim, out int driverId))
                {
                    return Unauthorized(new { message = "Driver ID not found in claims" });
                }

                var ride = await _rideService.RejectRideAsync(id, driverId);
                var rideDto = Mapper.Map<RideDto>(ride);
                return Ok(rideDto);
            }
            catch (TaxiMo.Model.Exceptions.UserException ex)
            {
                Logger.LogWarning(ex, "Error rejecting ride {RideId}", id);
                return BadRequest(new { message = ex.Message });
            }
            catch (Exception ex)
            {
                Logger.LogError(ex, "Error rejecting ride {RideId}", id);
                return StatusCode(500, new { message = "An error occurred while rejecting the ride" });
            }
        }

        // PUT: api/Ride/{id}/start
        [HttpPut("{id}/start")]
        [Authorize(Roles = "Driver")]
        public async Task<ActionResult<RideDto>> StartRide(int id)
        {
            try
            {
                var ride = await _rideService.StartRideAsync(id);
                var rideDto = Mapper.Map<RideDto>(ride);
                return Ok(rideDto);
            }
            catch (TaxiMo.Model.Exceptions.UserException ex)
            {
                Logger.LogWarning(ex, "Error starting ride {RideId}", id);
                return BadRequest(new { message = ex.Message });
            }
            catch (Exception ex)
            {
                Logger.LogError(ex, "Error starting ride {RideId}", id);
                return StatusCode(500, new { message = "An error occurred while starting the ride" });
            }
        }

        // PUT: api/Ride/{id}/complete
        [HttpPut("{id}/complete")]
        [Authorize(Roles = "Driver")]
        public async Task<ActionResult<RideDto>> CompleteRide(int id)
        {
            try
            {
                var ride = await _rideService.CompleteRideAsync(id);
                var rideDto = Mapper.Map<RideDto>(ride);
                return Ok(rideDto);
            }
            catch (TaxiMo.Model.Exceptions.UserException ex)
            {
                Logger.LogWarning(ex, "Error completing ride {RideId}", id);
                return BadRequest(new { message = ex.Message });
            }
            catch (Exception ex)
            {
                Logger.LogError(ex, "Error completing ride {RideId}", id);
                return StatusCode(500, new { message = "An error occurred while completing the ride" });
            }
        }

        // PUT: api/Ride/{id}/cancel
        [HttpPut("{id}/cancel")]
        [Authorize(Roles = "User,Admin")]
        public async Task<ActionResult<RideDto>> CancelRide(int id)
        {
            try
            {
                var roles = User.FindAll(ClaimTypes.Role).Select(c => c.Value).ToList();
                var isAdmin = roles.Contains("Admin");

                var ride = await _rideService.CancelRideAsync(id, isAdmin);
                var rideDto = Mapper.Map<RideDto>(ride);
                return Ok(rideDto);
            }
            catch (TaxiMo.Model.Exceptions.UserException ex)
            {
                Logger.LogWarning(ex, "Error cancelling ride {RideId}", id);
                return BadRequest(new { message = ex.Message });
            }
            catch (Exception ex)
            {
                Logger.LogError(ex, "Error cancelling ride {RideId}", id);
                return StatusCode(500, new { message = "An error occurred while cancelling the ride" });
            }
        }
    }
}

