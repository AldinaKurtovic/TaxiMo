using AutoMapper;
using Microsoft.AspNetCore.Mvc;
using TaxiMo.Services.Database.Entities;
using TaxiMo.Services.DTOs;
using TaxiMo.Services.Interfaces;

namespace TaxiMoWebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class LocationController : ControllerBase
    {
        private readonly ILocationService _locationService;
        private readonly IMapper _mapper;
        private readonly ILogger<LocationController> _logger;

        public LocationController(ILocationService locationService, IMapper mapper, ILogger<LocationController> logger)
        {
            _locationService = locationService;
            _mapper = mapper;
            _logger = logger;
        }

        // GET: api/Location
        [HttpGet]
        public async Task<ActionResult<IEnumerable<LocationDto>>> GetLocations()
        {
            try
            {
                var locations = await _locationService.GetAllAsync();
                var locationDtos = _mapper.Map<List<LocationDto>>(locations);
                return Ok(locationDtos);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving locations");
                return StatusCode(500, new { message = "An error occurred while retrieving locations" });
            }
        }

        // GET: api/Location/{id}
        [HttpGet("{id}")]
        public async Task<ActionResult<LocationDto>> GetLocation(int id)
        {
            try
            {
                var location = await _locationService.GetByIdAsync(id);

                if (location == null)
                {
                    return NotFound(new { message = $"Location with ID {id} not found" });
                }

                var locationDto = _mapper.Map<LocationDto>(location);
                return Ok(locationDto);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving location with ID {LocationId}", id);
                return StatusCode(500, new { message = "An error occurred while retrieving the location" });
            }
        }

        // POST: api/Location
        [HttpPost]
        public async Task<ActionResult<LocationDto>> CreateLocation(LocationCreateDto locationCreateDto)
        {
            try
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
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating location");
                return StatusCode(500, new { message = "An error occurred while creating the location" });
            }
        }

        // PUT: api/Location/{id}
        [HttpPut("{id}")]
        public async Task<ActionResult<LocationDto>> UpdateLocation(int id, LocationUpdateDto locationUpdateDto)
        {
            try
            {
                if (id != locationUpdateDto.LocationId)
                {
                    return BadRequest(new { message = "Location ID mismatch" });
                }

                if (!ModelState.IsValid)
                {
                    return BadRequest(ModelState);
                }

                try
                {
                    var location = _mapper.Map<Location>(locationUpdateDto);
                    var updatedLocation = await _locationService.UpdateAsync(location);
                    var locationDto = _mapper.Map<LocationDto>(updatedLocation);
                    return Ok(locationDto);
                }
                catch (KeyNotFoundException)
                {
                    return NotFound(new { message = $"Location with ID {id} not found" });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating location with ID {LocationId}", id);
                return StatusCode(500, new { message = "An error occurred while updating the location" });
            }
        }

        // DELETE: api/Location/{id}
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteLocation(int id)
        {
            try
            {
                var deleted = await _locationService.DeleteAsync(id);
                if (!deleted)
                {
                    return NotFound(new { message = $"Location with ID {id} not found" });
                }

                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting location with ID {LocationId}", id);
                return StatusCode(500, new { message = "An error occurred while deleting the location" });
            }
        }
    }
}

