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

        public RideController(IRideService rideService, IMapper mapper)
        {
            _rideService = rideService;
            _mapper = mapper;
        }

        // GET: api/Ride
        [HttpGet]
        public async Task<ActionResult<IEnumerable<RideDto>>> GetRides([FromQuery] string? search = null, [FromQuery] string? status = null)
        {
            var rides = await _rideService.GetAllAsync(search, status);
            var rideDtos = _mapper.Map<List<RideDto>>(rides);
            return Ok(rideDtos);
        }

        // GET: api/Ride/{id}
        [HttpGet("{id}")]
        public async Task<ActionResult<RideDto>> GetRide(int id)
        {
            var ride = await _rideService.GetByIdAsync(id);

            if (ride == null)
            {
                return NotFound(new { message = $"Ride with ID {id} not found" });
            }

            var rideDto = _mapper.Map<RideDto>(ride);
            return Ok(rideDto);
        }

        // POST: api/Ride
        [HttpPost]
        public async Task<ActionResult<RideDto>> CreateRide(RideCreateDto rideCreateDto)
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

        // PUT: api/Ride/{id}
        [HttpPut("{id}")]
        public async Task<ActionResult<RideDto>> UpdateRide(int id, RideUpdateDto rideUpdateDto)
        {
            if (id != rideUpdateDto.RideId)
            {
                return BadRequest(new { message = "Ride ID mismatch" });
            }

            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            var ride = _mapper.Map<Ride>(rideUpdateDto);
            var updatedRide = await _rideService.UpdateAsync(ride);
            var rideDto = _mapper.Map<RideDto>(updatedRide);
            return Ok(rideDto);
        }

        // DELETE: api/Ride/{id}
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteRide(int id)
        {
            var deleted = await _rideService.DeleteAsync(id);
            if (!deleted)
            {
                return NotFound(new { message = $"Ride with ID {id} not found" });
            }

            return NoContent();
        }
    }
}

