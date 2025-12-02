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
    [Authorize(Roles = "Admin,Driver")]
    public class DriverAvailabilityController : ControllerBase
    {
        private readonly IDriverAvailabilityService _driverAvailabilityService;
        private readonly IMapper _mapper;
        private readonly ILogger<DriverAvailabilityController> _logger;

        public DriverAvailabilityController(IDriverAvailabilityService driverAvailabilityService, IMapper mapper, ILogger<DriverAvailabilityController> logger)
        {
            _driverAvailabilityService = driverAvailabilityService;
            _mapper = mapper;
            _logger = logger;
        }

        // GET: api/DriverAvailability
        [HttpGet]
        public async Task<ActionResult<IEnumerable<DriverAvailabilityDto>>> GetDriverAvailabilities()
        {
            try
            {
                var driverAvailabilities = await _driverAvailabilityService.GetAllAsync();
                var driverAvailabilityDtos = _mapper.Map<List<DriverAvailabilityDto>>(driverAvailabilities);
                return Ok(driverAvailabilityDtos);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving driverAvailabilities");
                return StatusCode(500, new { message = "An error occurred while retrieving driverAvailabilities" });
            }
        }

        // GET: api/DriverAvailability/{id}
        [HttpGet("{id}")]
        public async Task<ActionResult<DriverAvailabilityDto>> GetDriverAvailability(int id)
        {
            try
            {
                var driverAvailability = await _driverAvailabilityService.GetByIdAsync(id);

                if (driverAvailability == null)
                {
                    return NotFound(new { message = $"DriverAvailability with ID {id} not found" });
                }

                var driverAvailabilityDto = _mapper.Map<DriverAvailabilityDto>(driverAvailability);
                return Ok(driverAvailabilityDto);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving driverAvailability with ID {DriverAvailabilityId}", id);
                return StatusCode(500, new { message = "An error occurred while retrieving the driverAvailability" });
            }
        }

        // POST: api/DriverAvailability
        [HttpPost]
        public async Task<ActionResult<DriverAvailabilityDto>> CreateDriverAvailability(DriverAvailabilityCreateDto driverAvailabilityCreateDto)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    return BadRequest(ModelState);
                }

                var driverAvailability = _mapper.Map<DriverAvailability>(driverAvailabilityCreateDto);
                var createdDriverAvailability = await _driverAvailabilityService.CreateAsync(driverAvailability);
                var driverAvailabilityDto = _mapper.Map<DriverAvailabilityDto>(createdDriverAvailability);

                return CreatedAtAction(nameof(GetDriverAvailability), new { id = driverAvailabilityDto.AvailabilityId }, driverAvailabilityDto);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating driverAvailability");
                return StatusCode(500, new { message = "An error occurred while creating the driverAvailability" });
            }
        }

        // PUT: api/DriverAvailability/{id}
        [HttpPut("{id}")]
        public async Task<ActionResult<DriverAvailabilityDto>> UpdateDriverAvailability(int id, DriverAvailabilityUpdateDto driverAvailabilityUpdateDto)
        {
            try
            {
                if (id != driverAvailabilityUpdateDto.AvailabilityId)
                {
                    return BadRequest(new { message = "DriverAvailability ID mismatch" });
                }

                if (!ModelState.IsValid)
                {
                    return BadRequest(ModelState);
                }

                try
                {
                    var driverAvailability = _mapper.Map<DriverAvailability>(driverAvailabilityUpdateDto);
                    var updatedDriverAvailability = await _driverAvailabilityService.UpdateAsync(driverAvailability);
                    var driverAvailabilityDto = _mapper.Map<DriverAvailabilityDto>(updatedDriverAvailability);
                    return Ok(driverAvailabilityDto);
                }
                catch (KeyNotFoundException)
                {
                    return NotFound(new { message = $"DriverAvailability with ID {id} not found" });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating driverAvailability with ID {DriverAvailabilityId}", id);
                return StatusCode(500, new { message = "An error occurred while updating the driverAvailability" });
            }
        }

        // DELETE: api/DriverAvailability/{id}
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteDriverAvailability(int id)
        {
            try
            {
                var deleted = await _driverAvailabilityService.DeleteAsync(id);
                if (!deleted)
                {
                    return NotFound(new { message = $"DriverAvailability with ID {id} not found" });
                }

                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting driverAvailability with ID {DriverAvailabilityId}", id);
                return StatusCode(500, new { message = "An error occurred while deleting the driverAvailability" });
            }
        }
    }
}

