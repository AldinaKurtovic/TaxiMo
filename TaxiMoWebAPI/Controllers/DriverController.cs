using AutoMapper;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TaxiMo.Services.Database.Entities;
using TaxiMo.Services.DTOs;
using TaxiMo.Services.Helpers;   
using TaxiMo.Services.Interfaces;

namespace TaxiMoWebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize(Roles = "Admin,Driver")]
    public class DriverController : ControllerBase
    {
        private readonly IDriverService _driverService;
        private readonly IMapper _mapper;
        private readonly ILogger<DriverController> _logger;

        public DriverController(
            IDriverService driverService,
            IMapper mapper,
            ILogger<DriverController> logger)
        {
            _driverService = driverService;
            _mapper = mapper;
            _logger = logger;
        }

        // GET: api/driver
        [HttpGet]
        public async Task<ActionResult<IEnumerable<DriverDto>>> GetDrivers(
            [FromQuery] string? search = null,
            [FromQuery] bool? isActive = null,
            [FromQuery] string? licence = null)
        {
            var drivers = await _driverService.GetAllAsync(search, isActive, licence);
            return Ok(_mapper.Map<List<DriverDto>>(drivers));
        }

        // GET: api/driver/{id}
        [HttpGet("{id}")]
        public async Task<ActionResult<DriverDto>> GetDriver(int id)
        {
            var driver = await _driverService.GetByIdAsync(id);
            if (driver == null)
                return NotFound(new { message = $"Driver with ID {id} not found" });

            return Ok(_mapper.Map<DriverDto>(driver));
        }

        // GET: api/driver/free
        [HttpGet("free")]
        public async Task<ActionResult<IEnumerable<DriverDto>>> GetFreeDrivers()
        {
            try
            {
                var allDrivers = await _driverService.GetAllAsync(null, true, null);
                var freeDrivers = await _driverService.GetFreeDriversAsync();
                var freeDriverDtos = _mapper.Map<List<DriverDto>>(freeDrivers);
                return Ok(freeDriverDtos);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving free drivers");
                return StatusCode(500, new { message = "An error occurred while retrieving free drivers" });
            }
        }

        // POST: api/driver
        [HttpPost]
        public async Task<ActionResult<object>> CreateDriver(DriverCreateDto dto)
        {
            if (!ModelState.IsValid)
                return BadRequest(new { message = "Validation failed.", errors = ModelState });

            // Email check
            if (await _driverService.EmailExistsAsync(dto.Email))
                return BadRequest(new { message = "A driver with this email already exists." });

            var driver = _mapper.Map<Driver>(dto);

            // If driver create dto contains plain password, hash it here (like in UsersController)
            if (!string.IsNullOrWhiteSpace(dto.Password))
            {
                PasswordHelper.CreatePasswordHash(dto.Password, out string hash, out string salt);
                driver.PasswordHash = hash;
                driver.PasswordSalt = salt;
            }

            var created = await _driverService.CreateAsync(driver);

            return CreatedAtAction(
                nameof(GetDriver),
                new { id = created.DriverId },
                new
                {
                    message = $"Driver '{created.FirstName} {created.LastName}' successfully created.",
                    data = _mapper.Map<DriverDto>(created)
                });
        }

        // PUT: api/driver/{id}
        [HttpPut("{id}")]
        public async Task<ActionResult<object>> UpdateDriver(int id, DriverUpdateDto dto, [FromQuery] bool isSelfUpdate = false)
        {
            _logger.LogInformation("UpdateDriver request received. Id: {Id}, Dto.DriverId: {DriverId}", id, dto.DriverId);
            
            if (id != dto.DriverId)
            {
                _logger.LogWarning("Driver ID mismatch. Route id: {RouteId}, DTO id: {DtoId}", id, dto.DriverId);
                return BadRequest(new { message = "Driver ID mismatch." });
            }

            if (!ModelState.IsValid)
            {
                _logger.LogWarning("ModelState is invalid: {ModelState}", ModelState);
                return BadRequest(new { message = "Validation failed.", errors = ModelState });
            }

            try
            {
                // Password change verification (if self-update)
                if (dto.ChangePassword && !string.IsNullOrWhiteSpace(dto.NewPassword) && isSelfUpdate)
                {
                    var existing = await _driverService.GetByIdAsync(id);
                    if (existing == null)
                        return NotFound(new { message = $"Driver with ID {id} not found." });

                    // Verify old password
                    var ok = PasswordHelper.VerifyPassword(dto.OldPassword, existing.PasswordHash, existing.PasswordSalt);
                    if (!ok)
                    {
                        _logger.LogWarning("Old password verification failed for driver. DriverId: {DriverId}", id);
                        return BadRequest(new { message = "Old password is incorrect." });
                    }
                }

                // Use the DTO-based UpdateAsync which handles all the logic properly
                var updatedDriver = await _driverService.UpdateAsync(dto);
                _logger.LogInformation("Driver updated successfully. DriverId: {DriverId}", updatedDriver.DriverId);
                
                return Ok(new
                {
                    message = $"Driver '{updatedDriver.FirstName} {updatedDriver.LastName}' successfully updated.",
                    data = _mapper.Map<DriverDto>(updatedDriver)
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating driver. DriverId: {DriverId}. Exception: {ExceptionType} - {Message}. StackTrace: {StackTrace}", 
                    dto.DriverId, ex.GetType().FullName, ex.Message, ex.StackTrace);
                throw; // Re-throw to let ExceptionFilter handle it
            }
        }

        // DELETE: api/driver/{id}
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteDriver(int id)
        {
            _logger.LogInformation("DeleteDriver request received. Id: {Id}", id);
            
            try
            {
                var deleted = await _driverService.DeleteAsync(id);
                if (!deleted)
                {
                    _logger.LogWarning("Driver not found for deletion. DriverId: {DriverId}", id);
                    return NotFound(new { message = $"Driver with ID {id} not found" });
                }

                _logger.LogInformation("Driver deleted successfully. DriverId: {DriverId}", id);
                return NoContent();
            }
            catch (InvalidOperationException ex)
            {
                // Business logic error - driver cannot be deleted due to related records
                _logger.LogWarning("Driver deletion blocked: {Message}. DriverId: {DriverId}", ex.Message, id);
                return BadRequest(new { message = ex.Message });
            }
            catch (Exception ex)
            {
                // Log the full exception details
                _logger.LogError(ex, "Error deleting driver. DriverId: {DriverId}. Exception: {ExceptionType} - {Message}. StackTrace: {StackTrace}", 
                    id, ex.GetType().FullName, ex.Message, ex.StackTrace);
                throw; // Re-throw to let ExceptionFilter handle it with full details
            }
        }
    }
}
