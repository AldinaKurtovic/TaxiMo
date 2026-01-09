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
        private readonly IVehicleService _vehicleService;
        private readonly IReviewService _reviewService;
        private readonly IMapper _mapper;
        private readonly ILogger<DriverController> _logger;

        public DriverController(
            IDriverService driverService,
            IVehicleService vehicleService,
            IReviewService reviewService,
            IMapper mapper,
            ILogger<DriverController> logger)
        {
            _driverService = driverService;
            _vehicleService = vehicleService;
            _reviewService = reviewService;
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
        [HttpGet("{id:int}")]
        public async Task<ActionResult<DriverDto>> GetDriver(int id)
        {
            var driver = await _driverService.GetByIdAsync(id);
            if (driver == null)
                return NotFound(new { message = $"Driver with ID {id} not found" });

            return Ok(_mapper.Map<DriverDto>(driver));
        }

        // GET: api/driver/{id}/stats
        [HttpGet("{id:int}/stats")]
        public async Task<ActionResult<object>> GetDriverStats(int id)
        {
            try
            {
                var driver = await _driverService.GetByIdAsync(id);
                if (driver == null)
                    return NotFound(new { message = $"Driver with ID {id} not found" });

                var (averageRating, totalReviews) = await _reviewService.GetDriverReviewStatsAsync(id);
                var (totalCompletedRides, totalEarnings) = await _reviewService.GetDriverRideStatsAsync(id);

                return Ok(new
                {
                    driverId = id,
                    averageRating = averageRating,
                    totalReviews = totalReviews,
                    totalCompletedRides = totalCompletedRides,
                    totalEarnings = totalEarnings
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving driver stats for driver {DriverId}", id);
                return StatusCode(500, new { message = $"An error occurred while retrieving driver stats" });
            }
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
        [HttpPut("{id:int}")]
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
        [HttpDelete("{id:int}")]
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

        /// <summary>
        /// Upload driver photo
        /// 
        /// Example cURL call:
        /// curl -X POST "https://localhost:5000/api/drivers/1/photo" \
        ///   -H "Authorization: Basic <base64_credentials>" \
        ///   -F "file=@/path/to/driver-photo.jpg"
        /// 
        /// Form-data parameter name: "file"
        /// Supported formats: jpg, jpeg, png, gif, webp
        /// Max file size: 5MB
        /// </summary>
        /// <param name="id">Driver ID</param>
        /// <param name="file">Image file (form-data parameter name: "file")</param>
        /// <returns>Updated DriverDto with PhotoUrl</returns>
        // POST: api/driver/{id}/photo
        [HttpPost("{id:int}/photo")]
        public async Task<ActionResult<DriverDto>> UploadDriverPhoto(int id, IFormFile file)
        {
            _logger.LogInformation("UploadDriverPhoto request received. DriverId: {DriverId}", id);

            if (file == null || file.Length == 0)
            {
                return BadRequest(new { message = "No file uploaded." });
            }

            // Validate file type (images only)
            var allowedExtensions = new[] { ".jpg", ".jpeg", ".png", ".gif", ".webp" };
            var fileExtension = Path.GetExtension(file.FileName).ToLowerInvariant();
            if (!allowedExtensions.Contains(fileExtension))
            {
                return BadRequest(new { message = "Invalid file type. Only image files (jpg, jpeg, png, gif, webp) are allowed." });
            }

            // Validate file size (max 5MB)
            const long maxFileSize = 5 * 1024 * 1024; // 5MB
            if (file.Length > maxFileSize)
            {
                return BadRequest(new { message = "File size exceeds the maximum allowed size of 5MB." });
            }

            try
            {
                // Verify driver exists
                var driver = await _driverService.GetByIdAsync(id);
                if (driver == null)
                {
                    _logger.LogWarning("Driver not found. DriverId: {DriverId}", id);
                    return NotFound(new { message = $"Driver with ID {id} not found" });
                }

                // Ensure wwwroot/drivers directory exists
                var wwwrootPath = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot");
                var driversPath = Path.Combine(wwwrootPath, "drivers");
                
                if (!Directory.Exists(driversPath))
                {
                    Directory.CreateDirectory(driversPath);
                    _logger.LogInformation("Created drivers directory at {DriversPath}", driversPath);
                }

                // Generate unique filename (Guid + extension)
                var uniqueFileName = $"{Guid.NewGuid()}{fileExtension}";
                var filePath = Path.Combine(driversPath, uniqueFileName);

                // Delete old photo if exists
                if (!string.IsNullOrEmpty(driver.PhotoUrl))
                {
                    var oldFilePath = Path.Combine(wwwrootPath, driver.PhotoUrl);
                    if (System.IO.File.Exists(oldFilePath))
                    {
                        try
                        {
                            System.IO.File.Delete(oldFilePath);
                            _logger.LogInformation("Deleted old driver photo: {OldPhotoPath}", oldFilePath);
                        }
                        catch (Exception ex)
                        {
                            _logger.LogWarning(ex, "Failed to delete old driver photo: {OldPhotoPath}", oldFilePath);
                        }
                    }
                }

                // Save the file
                using (var stream = new System.IO.FileStream(filePath, System.IO.FileMode.Create))
                {
                    await file.CopyToAsync(stream);
                }

                // Update driver's PhotoUrl (relative path: drivers/filename.ext)
                driver.PhotoUrl = $"drivers/{uniqueFileName}";
                driver.UpdatedAt = DateTime.UtcNow;

                // Update driver in database (using UpdateAsync(Driver) which handles PhotoUrl)
                var updatedDriver = await _driverService.UpdateAsync(driver);
                
                _logger.LogInformation("Driver photo uploaded successfully. DriverId: {DriverId}, PhotoUrl: {PhotoUrl}", 
                    id, updatedDriver.PhotoUrl);

                return Ok(_mapper.Map<DriverDto>(updatedDriver));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error uploading driver photo. DriverId: {DriverId}", id);
                return StatusCode(500, new { message = "An error occurred while uploading the photo" });
            }
        }

        /// <summary>
        /// Delete driver photo
        /// Removes the photo file from wwwroot/drivers and sets Driver.PhotoUrl to null
        /// </summary>
        /// <param name="id">Driver ID</param>
        /// <returns>Updated DriverDto with PhotoUrl set to default avatar</returns>
        // DELETE: api/driver/{id}/photo
        [HttpDelete("{id:int}/photo")]
        public async Task<ActionResult<DriverDto>> DeleteDriverPhoto(int id)
        {
            _logger.LogInformation("DeleteDriverPhoto request received. DriverId: {DriverId}", id);

            try
            {
                // Verify driver exists
                var driver = await _driverService.GetByIdAsync(id);
                if (driver == null)
                {
                    _logger.LogWarning("Driver not found. DriverId: {DriverId}", id);
                    return NotFound(new { message = $"Driver with ID {id} not found" });
                }

                // Delete photo file if exists
                if (!string.IsNullOrWhiteSpace(driver.PhotoUrl))
                {
                    var wwwrootPath = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot");
                    var filePath = Path.Combine(wwwrootPath, driver.PhotoUrl);
                    
                    if (System.IO.File.Exists(filePath))
                    {
                        try
                        {
                            System.IO.File.Delete(filePath);
                            _logger.LogInformation("Deleted driver photo file: {FilePath}", filePath);
                        }
                        catch (Exception ex)
                        {
                            _logger.LogWarning(ex, "Failed to delete driver photo file: {FilePath}", filePath);
                            // Continue even if file deletion fails
                        }
                    }
                }

                // Set PhotoUrl to null
                driver.PhotoUrl = null;
                driver.UpdatedAt = DateTime.UtcNow;

                // Update driver in database
                var updatedDriver = await _driverService.UpdateAsync(driver);
                
                _logger.LogInformation("Driver photo deleted successfully. DriverId: {DriverId}", id);

                return Ok(_mapper.Map<DriverDto>(updatedDriver));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting driver photo. DriverId: {DriverId}", id);
                return StatusCode(500, new { message = "An error occurred while deleting the photo" });
            }
        }

        // POST: api/driver/{id}/assign-vehicle
        // Helper endpoint to assign a vehicle to a driver
        [HttpPost("{id:int}/assign-vehicle")]
        public async Task<ActionResult<object>> AssignVehicleToDriver(int id, VehicleCreateDto vehicleDto)
        {
            _logger.LogInformation("AssignVehicleToDriver request received. DriverId: {DriverId}", id);

            if (id != vehicleDto.DriverId)
            {
                _logger.LogWarning("Driver ID mismatch. Route id: {RouteId}, DTO DriverId: {DtoDriverId}", id, vehicleDto.DriverId);
                return BadRequest(new { message = "Driver ID mismatch." });
            }

            if (!ModelState.IsValid)
            {
                _logger.LogWarning("ModelState is invalid: {ModelState}", ModelState);
                return BadRequest(new { message = "Validation failed.", errors = ModelState });
            }

            try
            {
                // Verify driver exists
                var driver = await _driverService.GetByIdAsync(id);
                if (driver == null)
                {
                    _logger.LogWarning("Driver not found. DriverId: {DriverId}", id);
                    return NotFound(new { message = $"Driver with ID {id} not found" });
                }

                // Create vehicle
                var vehicle = _mapper.Map<Vehicle>(vehicleDto);
                var createdVehicle = await _vehicleService.CreateAsync(vehicle);

                _logger.LogInformation("Vehicle assigned successfully. DriverId: {DriverId}, VehicleId: {VehicleId}", id, createdVehicle.VehicleId);

                return CreatedAtAction(
                    nameof(GetDriver),
                    new { id },
                    new
                    {
                        message = $"Vehicle '{createdVehicle.Make} {createdVehicle.Model}' successfully assigned to driver '{driver.FirstName} {driver.LastName}'.",
                        data = _mapper.Map<VehicleDto>(createdVehicle)
                    });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error assigning vehicle to driver. DriverId: {DriverId}", id);
                return StatusCode(500, new { message = "An error occurred while assigning vehicle to driver" });
            }
        }
    }
}
