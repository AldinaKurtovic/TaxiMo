using AutoMapper;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Cryptography;
using System.Text;
using TaxiMo.Services.Database;
using TaxiMo.Services.Database.Entities;
using TaxiMo.Services.DTOs;
using TaxiMo.Services.Interfaces;

namespace TaxiMoWebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
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

        // GET: api/users
        [HttpGet]
        public async Task<ActionResult<IEnumerable<UserDto>>> GetUsers([FromQuery] string? search = null, [FromQuery] bool? isActive = null)
        {
            try
            {
                var users = await _userService.GetAllAsync(search, isActive);
                var userDtos = _mapper.Map<List<UserDto>>(users);
                return Ok(userDtos);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving users");
                return StatusCode(500, new { message = "An error occurred while retrieving users" });
            }
        }

        // GET: api/users/{id}
        [HttpGet("{id}")]
        public async Task<ActionResult<UserDto>> GetUser(int id)
        {
            try
            {
                var user = await _userService.GetByIdAsync(id);

                if (user == null)
                {
                    return NotFound(new { message = $"User with ID {id} not found" });
                }

                var userDto = _mapper.Map<UserDto>(user);
                return Ok(userDto);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving user with ID {UserId}", id);
                return StatusCode(500, new { message = "An error occurred while retrieving the user" });
            }
        }

        // POST: api/users
        [HttpPost]
        public async Task<ActionResult<object>> CreateUser(UserCreateDto userCreateDto)
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
                var existingUser = await _userService.GetByEmailAsync(userCreateDto.Email);
                if (existingUser != null)
                {
                    return BadRequest(new { message = "A user with this email address already exists." });
                }

                var user = _mapper.Map<User>(userCreateDto);
                user.PasswordHash = HashPassword(userCreateDto.Password);
                
                var createdUser = await _userService.CreateAsync(user);
                var userDto = _mapper.Map<UserDto>(createdUser);

                return CreatedAtAction(
                    nameof(GetUser), 
                    new { id = userDto.UserId }, 
                    new { 
                        message = $"User '{userDto.FirstName} {userDto.LastName}' has been successfully created.",
                        data = userDto 
                    });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating user");
                return StatusCode(500, new { message = "An error occurred while creating the user" });
            }
        }

        // PUT: api/users/{id}
        [HttpPut("{id}")]
        public async Task<ActionResult<object>> UpdateUser(int id, UserUpdateDto userUpdateDto, [FromQuery] bool isSelfUpdate = false)
        {
            try
            {
                if (id != userUpdateDto.UserId)
                {
                    return BadRequest(new { message = "User ID mismatch." });
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
                    var existingUser = await _userService.GetByIdAsync(id);
                    if (existingUser == null)
                    {
                        return NotFound(new { message = $"User with ID {id} not found." });
                    }

                    // Handle password change
                    if (userUpdateDto.ChangePassword && !string.IsNullOrWhiteSpace(userUpdateDto.NewPassword))
                    {
                        // If user is updating their own password, verify old password
                        if (isSelfUpdate)
                        {
                            if (string.IsNullOrWhiteSpace(userUpdateDto.OldPassword))
                            {
                                return BadRequest(new { message = "Old password is required when changing your own password." });
                            }

                            if (!VerifyPassword(userUpdateDto.OldPassword, existingUser.PasswordHash))
                            {
                                return BadRequest(new { message = "Old password is incorrect." });
                            }
                        }

                        existingUser.PasswordHash = HashPassword(userUpdateDto.NewPassword);
                    }

                    // Update other properties only if provided (partial update support)
                    if (!string.IsNullOrWhiteSpace(userUpdateDto.FirstName))
                    {
                        existingUser.FirstName = userUpdateDto.FirstName;
                    }
                    if (!string.IsNullOrWhiteSpace(userUpdateDto.LastName))
                    {
                        existingUser.LastName = userUpdateDto.LastName;
                    }
                    if (!string.IsNullOrWhiteSpace(userUpdateDto.Email))
                    {
                        // Check if email is already taken by another user
                        var emailUser = await _userService.GetByEmailAsync(userUpdateDto.Email);
                        if (emailUser != null && emailUser.UserId != id)
                        {
                            return BadRequest(new { message = "A user with this email address already exists." });
                        }
                        existingUser.Email = userUpdateDto.Email;
                    }
                    if (userUpdateDto.Phone != null)
                    {
                        existingUser.Phone = userUpdateDto.Phone;
                    }
                    if (userUpdateDto.DateOfBirth.HasValue)
                    {
                        existingUser.DateOfBirth = userUpdateDto.DateOfBirth;
                    }
                    if (!string.IsNullOrWhiteSpace(userUpdateDto.Status))
                    {
                        existingUser.Status = userUpdateDto.Status;
                    }

                    existingUser.UpdatedAt = DateTime.UtcNow;
                    // Entity is already tracked, just save changes
                    await _userService.UpdateAsync(existingUser);
                    var userDto = _mapper.Map<UserDto>(existingUser);
                    
                    return Ok(new { 
                        message = $"User '{userDto.FirstName} {userDto.LastName}' has been successfully updated.",
                        data = userDto 
                    });
                }
                catch (KeyNotFoundException)
                {
                    return NotFound(new { message = $"User with ID {id} not found." });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating user with ID {UserId}", id);
                return StatusCode(500, new { message = "An error occurred while updating the user" });
            }
        }

        // DELETE: api/users/{id}
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteUser(int id)
        {
            try
            {
                var deleted = await _userService.DeleteAsync(id);
                if (!deleted)
                {
                    return NotFound(new { message = $"User with ID {id} not found" });
                }

                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting user with ID {UserId}", id);
                return StatusCode(500, new { message = "An error occurred while deleting the user" });
            }
        }
    }
}

