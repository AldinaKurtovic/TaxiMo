using AutoMapper;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TaxiMo.Services.Database.Entities;
using TaxiMo.Services.DTOs;
using TaxiMo.Services.Interfaces;

namespace TaxiMoWebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize(Roles = "User,Driver,Admin")]
    public class RideController : ControllerBase
    {
        private readonly IRideService _rideService;
        private readonly IMapper _mapper;
        private readonly ILogger<RideController> _logger;

        public RideController(IRideService rideService, IMapper mapper, ILogger<RideController> logger)
        {
            _rideService = rideService;
            _mapper = mapper;
            _logger = logger;
        }

        // GET: api/Ride
        [HttpGet]
        public async Task<ActionResult<IEnumerable<RideDto>>> GetRides([FromQuery] string? search = null, [FromQuery] string? status = null)
        {
            try
            {
                var rides = await _rideService.GetAllAsync(search, status);
                var rideDtos = _mapper.Map<List<RideDto>>(rides);
                return Ok(rideDtos);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving rides");
                return StatusCode(500, new { message = "An error occurred while retrieving rides" });
            }
        }

        // GET: api/Ride/{id}
        [HttpGet("{id}")]
        public async Task<ActionResult<RideDto>> GetRide(int id)
        {
            try
            {
                var ride = await _rideService.GetByIdAsync(id);

                if (ride == null)
                {
                    return NotFound(new { message = $"Ride with ID {id} not found" });
                }

                var rideDto = _mapper.Map<RideDto>(ride);
                return Ok(rideDto);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving ride with ID {RideId}", id);
                return StatusCode(500, new { message = "An error occurred while retrieving the ride" });
            }
        }

        // POST: api/Ride
        [HttpPost]
        public async Task<ActionResult<RideDto>> CreateRide(RideCreateDto rideCreateDto)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    return BadRequest(ModelState);
                }

                var ride = _mapper.Map<Ride>(rideCreateDto);
                var createdRide = await _rideService.CreateAsync(ride);
                var rideDto = _mapper.Map<RideDto>(createdRide);

                return CreatedAtAction(nameof(GetRide), new { id = rideDto.RideId }, rideDto);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating ride");
                return StatusCode(500, new { message = "An error occurred while creating the ride" });
            }
        }

        // PUT: api/Ride/{id}
        [HttpPut("{id}")]
        public async Task<ActionResult<RideDto>> UpdateRide(int id, RideUpdateDto rideUpdateDto)
        {
            try
            {
                if (id != rideUpdateDto.RideId)
                {
                    return BadRequest(new { message = "Ride ID mismatch" });
                }

                if (!ModelState.IsValid)
                {
                    return BadRequest(ModelState);
                }

                try
                {
                    var ride = _mapper.Map<Ride>(rideUpdateDto);
                    var updatedRide = await _rideService.UpdateAsync(ride);
                    var rideDto = _mapper.Map<RideDto>(updatedRide);
                    return Ok(rideDto);
                }
                catch (KeyNotFoundException)
                {
                    return NotFound(new { message = $"Ride with ID {id} not found" });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating ride with ID {RideId}", id);
                return StatusCode(500, new { message = "An error occurred while updating the ride" });
            }
        }

        // DELETE: api/Ride/{id}
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteRide(int id)
        {
            try
            {
                var deleted = await _rideService.DeleteAsync(id);
                if (!deleted)
                {
                    return NotFound(new { message = $"Ride with ID {id} not found" });
                }

                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting ride with ID {RideId}", id);
                return StatusCode(500, new { message = "An error occurred while deleting the ride" });
            }
        }
    }
}

