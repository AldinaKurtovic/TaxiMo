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
            if (id != dto.DriverId)
                return BadRequest(new { message = "Driver ID mismatch." });

            var existing = await _driverService.GetByIdAsync(id);
            if (existing == null)
                return NotFound(new { message = $"Driver with ID {id} not found." });

            // Email update check
            if (!string.IsNullOrWhiteSpace(dto.Email) &&
                await _driverService.EmailExistsAsync(dto.Email, id))
            {
                return BadRequest(new { message = "A driver with this email already exists." });
            }

            // Password change (uses PasswordHelper like UsersController)
            if (dto.ChangePassword && !string.IsNullOrWhiteSpace(dto.NewPassword))
            {
                if (isSelfUpdate)
                {
                    // Verify old password using helper (assumes PasswordHelper has VerifyPassword method)
                    var ok = PasswordHelper.VerifyPassword(dto.OldPassword, existing.PasswordHash, existing.PasswordSalt);
                    if (!ok)
                        return BadRequest(new { message = "Old password is incorrect." });
                }

                // Create new hash+salt and store
                PasswordHelper.CreatePasswordHash(dto.NewPassword, out string newHash, out string newSalt);
                existing.PasswordHash = newHash;
                existing.PasswordSalt = newSalt;
            }

            // Map other fields (AutoMapper ignores nulls)
            _mapper.Map(dto, existing);

            existing.UpdatedAt = DateTime.UtcNow;
            await _driverService.UpdateAsync(existing);

            return Ok(new
            {
                message = $"Driver '{existing.FirstName} {existing.LastName}' successfully updated.",
                data = _mapper.Map<DriverDto>(existing)
            });
        }

        // DELETE: api/driver/{id}
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteDriver(int id)
        {
            var deleted = await _driverService.DeleteAsync(id);
            if (!deleted)
                return NotFound(new { message = $"Driver with ID {id} not found" });

            return NoContent();
        }
    }
}
