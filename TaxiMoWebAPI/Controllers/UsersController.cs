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
        public async Task<ActionResult<IEnumerable<UserDto>>> GetUsers([FromQuery] string? search = null, [FromQuery] bool? isActive = null)
        {
            var users = await _userService.GetAllAsync(search, isActive);
            return Ok(_mapper.Map<List<UserDto>>(users));
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
    }
}
