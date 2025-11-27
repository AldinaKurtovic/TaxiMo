using AutoMapper;
using Microsoft.AspNetCore.Mvc;
using System.Security.Cryptography;
using System.Text;
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

        private static string HashPassword(string password)
        {
            using var sha256 = SHA256.Create();
            var hashedBytes = sha256.ComputeHash(Encoding.UTF8.GetBytes(password));
            return Convert.ToBase64String(hashedBytes);
        }

        private static bool VerifyPassword(string password, string hash)
        {
            var hashOfInput = HashPassword(password);
            return hashOfInput == hash;
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
        public async Task<ActionResult<object>> CreateDriver(DriverCreateDto driverCreateDto)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    var errors = ModelState
                        .Where(x => x.Value?.Errors.Count > 0)
                        .SelectMany(x => x.Value!.Errors.Select(e => new
                        {
                            Field = x.Key,
                            Message = e.ErrorMessage
                        }))
                        .ToList();
                    return BadRequest(new { message = "Validation failed.", errors });
                }

                // Check if email already exists
                var existingDrivers = await _driverService.GetAllAsync();
                var existingDriver = existingDrivers.FirstOrDefault(d => d.Email.Equals(driverCreateDto.Email, StringComparison.OrdinalIgnoreCase));
                if (existingDriver != null)
                {
                    return BadRequest(new { message = "A driver with this email address already exists." });
                }

                var driver = _mapper.Map<Driver>(driverCreateDto);
                driver.PasswordHash = HashPassword(driverCreateDto.Password);
                
                var createdDriver = await _driverService.CreateAsync(driver);
                var driverDto = _mapper.Map<DriverDto>(createdDriver);

                return CreatedAtAction(
                    nameof(GetDriver), 
                    new { id = driverDto.DriverId }, 
                    new { 
                        message = $"Driver '{driverDto.FirstName} {driverDto.LastName}' has been successfully created.",
                        data = driverDto 
                    });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating driver");
                return StatusCode(500, new { message = "An error occurred while creating the driver" });
            }
        }

        // PUT: api/driver/{id}
        [HttpPut("{id}")]
        public async Task<ActionResult<object>> UpdateDriver(int id, DriverUpdateDto driverUpdateDto, [FromQuery] bool isSelfUpdate = false)
        {
            try
            {
                if (id != driverUpdateDto.DriverId)
                {
                    return BadRequest(new { message = "Driver ID mismatch." });
                }

                if (!ModelState.IsValid)
                {
                    var errors = ModelState
                        .Where(x => x.Value?.Errors.Count > 0)
                        .SelectMany(x => x.Value!.Errors.Select(e => new
                        {
                            Field = x.Key,
                            Message = e.ErrorMessage
                        }))
                        .ToList();
                    return BadRequest(new { message = "Validation failed.", errors });
                }

                try
                {
                    var existingDriver = await _driverService.GetByIdAsync(id);
                    if (existingDriver == null)
                    {
                        return NotFound(new { message = $"Driver with ID {id} not found." });
                    }

                    // Handle password change
                    if (driverUpdateDto.ChangePassword && !string.IsNullOrWhiteSpace(driverUpdateDto.NewPassword))
                    {
                        // If driver is updating their own password, verify old password
                        if (isSelfUpdate)
                        {
                            if (string.IsNullOrWhiteSpace(driverUpdateDto.OldPassword))
                            {
                                return BadRequest(new { message = "Old password is required when changing your own password." });
                            }

                            if (!VerifyPassword(driverUpdateDto.OldPassword, existingDriver.PasswordHash))
                            {
                                return BadRequest(new { message = "Old password is incorrect." });
                            }
                        }

                        existingDriver.PasswordHash = HashPassword(driverUpdateDto.NewPassword);
                    }

                    // Update other properties only if provided (partial update support)
                    if (!string.IsNullOrWhiteSpace(driverUpdateDto.FirstName))
                    {
                        existingDriver.FirstName = driverUpdateDto.FirstName;
                    }
                    if (!string.IsNullOrWhiteSpace(driverUpdateDto.LastName))
                    {
                        existingDriver.LastName = driverUpdateDto.LastName;
                    }
                    if (!string.IsNullOrWhiteSpace(driverUpdateDto.Email))
                    {
                        // Check if email is already taken by another driver
                        var existingDrivers = await _driverService.GetAllAsync();
                        var emailDriver = existingDrivers.FirstOrDefault(d => d.Email.Equals(driverUpdateDto.Email, StringComparison.OrdinalIgnoreCase) && d.DriverId != id);
                        if (emailDriver != null)
                        {
                            return BadRequest(new { message = "A driver with this email address already exists." });
                        }
                        existingDriver.Email = driverUpdateDto.Email;
                    }
                    if (driverUpdateDto.Phone != null)
                    {
                        existingDriver.Phone = driverUpdateDto.Phone;
                    }
                    if (!string.IsNullOrWhiteSpace(driverUpdateDto.LicenseNumber))
                    {
                        existingDriver.LicenseNumber = driverUpdateDto.LicenseNumber;
                    }
                    if (driverUpdateDto.LicenseExpiry.HasValue)
                    {
                        existingDriver.LicenseExpiry = driverUpdateDto.LicenseExpiry.Value;
                    }
                    if (!string.IsNullOrWhiteSpace(driverUpdateDto.Status))
                    {
                        existingDriver.Status = driverUpdateDto.Status;
                    }

                    existingDriver.UpdatedAt = DateTime.UtcNow;
                    // Entity is already tracked, just save changes
                    await _driverService.UpdateAsync(existingDriver);
                    var driverDto = _mapper.Map<DriverDto>(existingDriver);
                    
                    return Ok(new { 
                        message = $"Driver '{driverDto.FirstName} {driverDto.LastName}' has been successfully updated.",
                        data = driverDto 
                    });
                }
                catch (KeyNotFoundException)
                {
                    return NotFound(new { message = $"Driver with ID {id} not found." });
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

