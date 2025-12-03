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
    [Authorize(Roles = "User,Admin")]
    public class LocationController : ControllerBase
    {
        private readonly ILocationService _locationService;
        private readonly IMapper _mapper;

        public LocationController(ILocationService locationService, IMapper mapper)
        {
            _locationService = locationService;
            _mapper = mapper;
        }

        // GET: api/Location
        [HttpGet]
        public async Task<ActionResult<IEnumerable<LocationDto>>> GetLocations()
        {
            var locations = await _locationService.GetAllAsync();
            var locationDtos = _mapper.Map<List<LocationDto>>(locations);
            return Ok(locationDtos);
        }

        // GET: api/Location/{id}
        [HttpGet("{id}")]
        public async Task<ActionResult<LocationDto>> GetLocation(int id)
        {
            var location = await _locationService.GetByIdAsync(id);

            if (location == null)
            {
                return NotFound(new { message = $"Location with ID {id} not found" });
            }

            var locationDto = _mapper.Map<LocationDto>(location);
            return Ok(locationDto);
        }

        // POST: api/Location
        [HttpPost]
        public async Task<ActionResult<LocationDto>> CreateLocation(LocationCreateDto locationCreateDto)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            var location = _mapper.Map<Location>(locationCreateDto);
            var createdLocation = await _locationService.CreateAsync(location);
            var locationDto = _mapper.Map<LocationDto>(createdLocation);

            return CreatedAtAction(nameof(GetLocation), new { id = locationDto.LocationId }, locationDto);
        }

        // PUT: api/Location/{id}
        [HttpPut("{id}")]
        public async Task<ActionResult<LocationDto>> UpdateLocation(int id, LocationUpdateDto locationUpdateDto)
        {
            if (id != locationUpdateDto.LocationId)
            {
                return BadRequest(new { message = "Location ID mismatch" });
            }

            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            var location = _mapper.Map<Location>(locationUpdateDto);
            var updatedLocation = await _locationService.UpdateAsync(location);
            var locationDto = _mapper.Map<LocationDto>(updatedLocation);
            return Ok(locationDto);
        }

        // DELETE: api/Location/{id}
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteLocation(int id)
        {
            var deleted = await _locationService.DeleteAsync(id);
            if (!deleted)
            {
                return NotFound(new { message = $"Location with ID {id} not found" });
            }

            return NoContent();
        }
    }
}
