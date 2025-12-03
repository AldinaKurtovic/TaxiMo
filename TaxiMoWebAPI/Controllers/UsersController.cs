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
    [Authorize(Roles = "Admin")]
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

        // LOGIN
        [AllowAnonymous]
        [HttpPost("login")]
        public async Task<ActionResult<UserResponse>> Login(UserLoginRequest request)
        {
            var user = await _userService.AuthenticateAsync(request);
            if (user == null)
                return Unauthorized(new { message = "Invalid username or password" });

            return Ok(user);
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
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            // Use the DTO-based CreateAsync which handles password hashing and role assignment
            var userResponse = await _userService.CreateAsync(dto);
            return Ok(new { message = "User created.", data = userResponse });
        }

        // UPDATE USER
        [HttpPut("{id}")]
        public async Task<ActionResult<object>> UpdateUser(int id, UserUpdateDto dto)
        {
            if (id != dto.UserId)
                return BadRequest(new { message = "User ID mismatch." });

            var existing = await _userService.GetByIdAsync(id);
            if (existing == null)
                return NotFound(new { message = "User not found." });

            // PASSWORD CHANGE
            if (dto.ChangePassword && !string.IsNullOrWhiteSpace(dto.NewPassword))
            {
                PasswordHelper.CreatePasswordHash(dto.NewPassword, out string hash, out string salt);
                existing.PasswordHash = hash;
                existing.PasswordSalt = salt;
            }

            // UPDATE OTHER FIELDS
            _mapper.Map(dto, existing);

            await _userService.UpdateAsync(existing);

            return Ok(new { message = "User updated.", data = _mapper.Map<UserDto>(existing) });
        }

        // DELETE
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteUser(int id)
        {
            var deleted = await _userService.DeleteAsync(id);
            if (!deleted)
                return NotFound(new { message = "User not found" });

            return NoContent();
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
