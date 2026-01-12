using AutoMapper;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TaxiMo.Services.Database.Entities;
using TaxiMo.Services.DTOs;
using TaxiMo.Services.DTOs.Auth;
using TaxiMo.Services.Helpers;
using TaxiMo.Services.Interfaces;

namespace TaxiMoWebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize(Roles = "Admin,User")]
    public class UsersController : ControllerBase
    {
        private readonly IUserService _userService;
        private readonly IMapper _mapper;
        private readonly ILogger<UsersController> _logger;

        public UsersController(IUserService userService, IMapper mapper, ILogger<UsersController> logger)
        {
            _userService = userService;
            _mapper = mapper;
            _logger = logger;
        }


        // GET ALL USERS
        [HttpGet]
        public async Task<ActionResult<object>> GetUsers(
            [FromQuery] int page = 1, 
            [FromQuery] int limit = 7, 
            [FromQuery] string? search = null, 
            [FromQuery] bool? isActive = null)
        {
            var pagedResult = await _userService.GetAllPagedAsync(page, limit, search, isActive);
            var userDtos = _mapper.Map<List<UserDto>>(pagedResult.Data);
            
            return Ok(new
            {
                data = userDtos,
                pagination = new
                {
                    currentPage = pagedResult.Pagination.CurrentPage,
                    totalPages = pagedResult.Pagination.TotalPages,
                    totalItems = pagedResult.Pagination.TotalItems,
                    limit = pagedResult.Pagination.Limit
                }
            });
        }

        // GET CURRENT USER (ME)
        [HttpGet("me")]
        public async Task<ActionResult<UserDto>> GetCurrentUser()
        {
            // Get username from claims
            var username = User.Identity?.Name;
            if (string.IsNullOrEmpty(username))
            {
                return Unauthorized(new { message = "User not authenticated" });
            }

            // Get user by username (this will work for both Admin and User roles)
            var user = await _userService.GetByUsernameAsync(username);
            if (user == null)
                return NotFound(new { message = "User not found" });

            return Ok(_mapper.Map<UserDto>(user));
        }

        // GET USER BY ID
        [HttpGet("{id}")]
        public async Task<ActionResult<UserDto>> GetUser(int id)
        {
            var user = await _userService.GetByIdAsync(id);
            if (user == null)
                return NotFound(new { message = $"User with ID {id} not found" });

            return Ok(_mapper.Map<UserDto>(user));
        }

        // CREATE USER
        [HttpPost]
        public async Task<ActionResult<object>> CreateUser(UserCreateDto dto)
        {
            _logger.LogInformation("CreateUser request received. Email: {Email}, Username: {Username}", dto.Email, dto.Username);
            
            if (!ModelState.IsValid)
            {
                _logger.LogWarning("ModelState is invalid: {ModelState}", ModelState);
                return BadRequest(ModelState);
            }

            try
            {
                // Use the DTO-based CreateAsync which handles password hashing and role assignment
                var userResponse = await _userService.CreateAsync(dto);
                _logger.LogInformation("User created successfully. UserId: {UserId}", userResponse.UserId);
                return Ok(new { message = "User created.", data = userResponse });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating user. Email: {Email}, Username: {Username}", dto.Email, dto.Username);
                throw; // Re-throw to let ExceptionFilter handle it
            }
        }

        // UPDATE USER
        [HttpPut("{id}")]
        public async Task<ActionResult<object>> UpdateUser(int id, UserUpdateDto dto)
        {
            _logger.LogInformation("UpdateUser request received. Id: {Id}, Dto.UserId: {UserId}", id, dto.UserId);
            
            if (id != dto.UserId)
            {
                _logger.LogWarning("User ID mismatch. Route id: {RouteId}, DTO id: {DtoId}", id, dto.UserId);
                return BadRequest(new { message = "User ID mismatch." });
            }

            try
            {
                // Use the DTO-based UpdateAsync which handles all the logic properly
                var userResponse = await _userService.UpdateAsync(dto);
                _logger.LogInformation("User updated successfully. UserId: {UserId}", userResponse.UserId);
                return Ok(new { message = "User updated.", data = userResponse });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating user. UserId: {UserId}", dto.UserId);
                throw; // Re-throw to let ExceptionFilter handle it
            }
        }

        // DELETE
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteUser(int id)
        {
            _logger.LogInformation("DeleteUser request received. Id: {Id}", id);
            
            try
            {
                var deleted = await _userService.DeleteAsync(id);
                if (!deleted)
                {
                    _logger.LogWarning("User not found for deletion. UserId: {UserId}", id);
                    return NotFound(new { message = "User not found" });
                }

                _logger.LogInformation("User deleted successfully. UserId: {UserId}", id);
                return NoContent();
            }
            catch (InvalidOperationException ex)
            {
                // Business logic error - user cannot be deleted due to related records
                _logger.LogWarning("User deletion blocked: {Message}. UserId: {UserId}", ex.Message, id);
                return BadRequest(new { message = ex.Message });
            }
            catch (Exception ex)
            {
                // Log the full exception details
                _logger.LogError(ex, "Error deleting user. UserId: {UserId}. Exception: {ExceptionType} - {Message}. StackTrace: {StackTrace}", 
                    id, ex.GetType().FullName, ex.Message, ex.StackTrace);
                throw; // Re-throw to let ExceptionFilter handle it
            }
        }

        // FIX USERS WITHOUT ROLES
        /// <summary>
        /// Finds all users without any roles and assigns them the default "User" role.
        /// This is a utility endpoint to fix existing data.
        /// </summary>
        [HttpPost("fix-users-without-roles")]
        public async Task<ActionResult<object>> FixUsersWithoutRoles()
        {
            var fixedCount = await _userService.FixUsersWithoutRolesAsync();
            return Ok(new 
            { 
                message = $"Successfully assigned default 'User' role to {fixedCount} user(s).",
                usersFixed = fixedCount
            });
        }

        /// <summary>
        /// Upload user photo
        /// Accepts multipart/form-data with a file parameter named "file"
        /// Example cURL:
        /// curl -X POST "https://localhost:5000/api/users/1/photo" \
        ///   -H "Authorization: Basic base64encodedcredentials" \
        ///   -F "file=@/path/to/user-photo.jpg"
        /// </summary>
        /// <param name="id">User ID</param>
        /// <param name="file">Image file (jpg, jpeg, png, gif, webp, max 5MB)</param>
        /// <returns>Updated UserDto with PhotoUrl</returns>
        // POST: api/users/{id}/photo
        [HttpPost("{id:int}/photo")]
        public async Task<ActionResult<UserDto>> UploadUserPhoto(int id, IFormFile file)
        {
            _logger.LogInformation("UploadUserPhoto request received. UserId: {UserId}", id);

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
                // Verify user exists
                var user = await _userService.GetByIdAsync(id);
                if (user == null)
                {
                    _logger.LogWarning("User not found. UserId: {UserId}", id);
                    return NotFound(new { message = $"User with ID {id} not found" });
                }

                // Ensure wwwroot/users directory exists
                var wwwrootPath = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot");
                var usersPath = Path.Combine(wwwrootPath, "users");
                
                if (!Directory.Exists(usersPath))
                {
                    Directory.CreateDirectory(usersPath);
                    _logger.LogInformation("Created users directory at {UsersPath}", usersPath);
                }

                // Generate unique filename (Guid + extension)
                var uniqueFileName = $"{Guid.NewGuid()}{fileExtension}";
                var filePath = Path.Combine(usersPath, uniqueFileName);

                // Delete old photo if exists
                if (!string.IsNullOrEmpty(user.PhotoUrl))
                {
                    var oldFilePath = Path.Combine(wwwrootPath, user.PhotoUrl);
                    if (System.IO.File.Exists(oldFilePath))
                    {
                        try
                        {
                            System.IO.File.Delete(oldFilePath);
                            _logger.LogInformation("Deleted old user photo: {OldPhotoPath}", oldFilePath);
                        }
                        catch (Exception ex)
                        {
                            _logger.LogWarning(ex, "Failed to delete old user photo: {OldPhotoPath}", oldFilePath);
                        }
                    }
                }

                // Save the file
                using (var stream = new System.IO.FileStream(filePath, System.IO.FileMode.Create))
                {
                    await file.CopyToAsync(stream);
                }

                // Update user's PhotoUrl (relative path: users/filename.ext)
                user.PhotoUrl = $"users/{uniqueFileName}";
                user.UpdatedAt = DateTime.UtcNow;

                // Update user in database (using UpdateAsync(User) which handles PhotoUrl)
                var updatedUser = await _userService.UpdateAsync(user);
                
                _logger.LogInformation("User photo uploaded successfully. UserId: {UserId}, PhotoUrl: {PhotoUrl}", 
                    id, updatedUser.PhotoUrl);

                return Ok(_mapper.Map<UserDto>(updatedUser));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error uploading user photo. UserId: {UserId}", id);
                return StatusCode(500, new { message = "An error occurred while uploading the photo" });
            }
        }

        /// <summary>
        /// Delete user photo
        /// Removes the photo file from wwwroot/users and sets User.PhotoUrl to null
        /// </summary>
        /// <param name="id">User ID</param>
        /// <returns>Updated UserDto with PhotoUrl set to default avatar</returns>
        // DELETE: api/users/{id}/photo
        [HttpDelete("{id:int}/photo")]
        public async Task<ActionResult<UserDto>> DeleteUserPhoto(int id)
        {
            _logger.LogInformation("DeleteUserPhoto request received. UserId: {UserId}", id);

            try
            {
                // Verify user exists
                var user = await _userService.GetByIdAsync(id);
                if (user == null)
                {
                    _logger.LogWarning("User not found. UserId: {UserId}", id);
                    return NotFound(new { message = $"User with ID {id} not found" });
                }

                // Delete photo file if exists
                if (!string.IsNullOrWhiteSpace(user.PhotoUrl))
                {
                    var wwwrootPath = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot");
                    var filePath = Path.Combine(wwwrootPath, user.PhotoUrl);
                    
                    if (System.IO.File.Exists(filePath))
                    {
                        try
                        {
                            System.IO.File.Delete(filePath);
                            _logger.LogInformation("Deleted user photo file: {FilePath}", filePath);
                        }
                        catch (Exception ex)
                        {
                            _logger.LogWarning(ex, "Failed to delete user photo file: {FilePath}", filePath);
                            // Continue even if file deletion fails
                        }
                    }
                }

                // Set PhotoUrl to null
                user.PhotoUrl = null;
                user.UpdatedAt = DateTime.UtcNow;

                // Update user in database
                var updatedUser = await _userService.UpdateAsync(user);
                
                _logger.LogInformation("User photo deleted successfully. UserId: {UserId}", id);

                return Ok(_mapper.Map<UserDto>(updatedUser));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting user photo. UserId: {UserId}", id);
                return StatusCode(500, new { message = "An error occurred while deleting the photo" });
            }
        }
    }
}
