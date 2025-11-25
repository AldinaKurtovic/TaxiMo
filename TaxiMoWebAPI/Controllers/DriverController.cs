using AutoMapper;
using Microsoft.AspNetCore.Mvc;
using TaxiMo.Services.Database.Entities;
using TaxiMo.Services.DTOs;
using TaxiMo.Services.Interfaces;

namespace TaxiMoWebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class DriverController : ControllerBase
    {
        private readonly IDriverService _driverService;
        private readonly IMapper _mapper;
        private readonly ILogger<DriverController> _logger;

        public DriverController(IDriverService driverService, IMapper mapper, ILogger<DriverController> logger)
        {
            _driverService = driverService;
            _mapper = mapper;
            _logger = logger;
        }

        // GET: api/driver
        [HttpGet]
        public async Task<ActionResult<IEnumerable<DriverDto>>> GetDrivers([FromQuery] string? search = null, [FromQuery] bool? isActive = null, [FromQuery] string? licence = null)
        {
            try
            {
                var drivers = await _driverService.GetAllAsync(search, isActive, licence);
                var driverDtos = _mapper.Map<List<DriverDto>>(drivers);
                return Ok(driverDtos);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving drivers");
                return StatusCode(500, new { message = "An error occurred while retrieving drivers" });
            }
        }

        // GET: api/driver/{id}
        [HttpGet("{id}")]
        public async Task<ActionResult<DriverDto>> GetDriver(int id)
        {
            try
            {
                var driver = await _driverService.GetByIdAsync(id);

                if (driver == null)
                {
                    return NotFound(new { message = $"Driver with ID {id} not found" });
                }

                var driverDto = _mapper.Map<DriverDto>(driver);
                return Ok(driverDto);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving driver with ID {DriverId}", id);
                return StatusCode(500, new { message = "An error occurred while retrieving the driver" });
            }
        }

        // POST: api/driver
        [HttpPost]
        public async Task<ActionResult<DriverDto>> CreateDriver(DriverCreateDto driverCreateDto)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    return BadRequest(ModelState);
                }

                var driver = _mapper.Map<Driver>(driverCreateDto);
                var createdDriver = await _driverService.CreateAsync(driver);
                var driverDto = _mapper.Map<DriverDto>(createdDriver);

                return CreatedAtAction(nameof(GetDriver), new { id = driverDto.DriverId }, driverDto);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating driver");
                return StatusCode(500, new { message = "An error occurred while creating the driver" });
            }
        }

        // PUT: api/driver/{id}
        [HttpPut("{id}")]
        public async Task<ActionResult<DriverDto>> UpdateDriver(int id, DriverUpdateDto driverUpdateDto)
        {
            try
            {
                if (id != driverUpdateDto.DriverId)
                {
                    return BadRequest(new { message = "Driver ID mismatch" });
                }

                if (!ModelState.IsValid)
                {
                    return BadRequest(ModelState);
                }

                try
                {
                    var driver = _mapper.Map<Driver>(driverUpdateDto);
                    var updatedDriver = await _driverService.UpdateAsync(driver);
                    var driverDto = _mapper.Map<DriverDto>(updatedDriver);
                    return Ok(driverDto);
                }
                catch (KeyNotFoundException)
                {
                    return NotFound(new { message = $"Driver with ID {id} not found" });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating driver with ID {DriverId}", id);
                return StatusCode(500, new { message = "An error occurred while updating the driver" });
            }
        }

        // DELETE: api/driver/{id}
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteDriver(int id)
        {
            try
            {
                var deleted = await _driverService.DeleteAsync(id);
                if (!deleted)
                {
                    return NotFound(new { message = $"Driver with ID {id} not found" });
                }

                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting driver with ID {DriverId}", id);
                return StatusCode(500, new { message = "An error occurred while deleting the driver" });
            }
        }
    }
}

