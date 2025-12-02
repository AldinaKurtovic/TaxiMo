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
    [Authorize(Roles = "User,Admin")]
    public class UserNotificationController : ControllerBase
    {
        private readonly IUserNotificationService _userNotificationService;
        private readonly IMapper _mapper;
        private readonly ILogger<UserNotificationController> _logger;

        public UserNotificationController(IUserNotificationService userNotificationService, IMapper mapper, ILogger<UserNotificationController> logger)
        {
            _userNotificationService = userNotificationService;
            _mapper = mapper;
            _logger = logger;
        }

        // GET: api/UserNotification
        [HttpGet]
        public async Task<ActionResult<IEnumerable<UserNotificationDto>>> GetUserNotifications()
        {
            try
            {
                var userNotifications = await _userNotificationService.GetAllAsync();
                var userNotificationDtos = _mapper.Map<List<UserNotificationDto>>(userNotifications);
                return Ok(userNotificationDtos);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving userNotifications");
                return StatusCode(500, new { message = "An error occurred while retrieving userNotifications" });
            }
        }

        // GET: api/UserNotification/{id}
        [HttpGet("{id}")]
        public async Task<ActionResult<UserNotificationDto>> GetUserNotification(int id)
        {
            try
            {
                var userNotification = await _userNotificationService.GetByIdAsync(id);

                if (userNotification == null)
                {
                    return NotFound(new { message = $"UserNotification with ID {id} not found" });
                }

                var userNotificationDto = _mapper.Map<UserNotificationDto>(userNotification);
                return Ok(userNotificationDto);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving userNotification with ID {UserNotificationId}", id);
                return StatusCode(500, new { message = "An error occurred while retrieving the userNotification" });
            }
        }

        // POST: api/UserNotification
        [HttpPost]
        public async Task<ActionResult<UserNotificationDto>> CreateUserNotification(UserNotificationCreateDto userNotificationCreateDto)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    return BadRequest(ModelState);
                }

                var userNotification = _mapper.Map<UserNotification>(userNotificationCreateDto);
                var createdUserNotification = await _userNotificationService.CreateAsync(userNotification);
                var userNotificationDto = _mapper.Map<UserNotificationDto>(createdUserNotification);

                return CreatedAtAction(nameof(GetUserNotification), new { id = userNotificationDto.NotificationId }, userNotificationDto);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating userNotification");
                return StatusCode(500, new { message = "An error occurred while creating the userNotification" });
            }
        }

        // PUT: api/UserNotification/{id}
        [HttpPut("{id}")]
        public async Task<ActionResult<UserNotificationDto>> UpdateUserNotification(int id, UserNotificationUpdateDto userNotificationUpdateDto)
        {
            try
            {
                if (id != userNotificationUpdateDto.NotificationId)
                {
                    return BadRequest(new { message = "UserNotification ID mismatch" });
                }

                if (!ModelState.IsValid)
                {
                    return BadRequest(ModelState);
                }

                try
                {
                    var userNotification = _mapper.Map<UserNotification>(userNotificationUpdateDto);
                    var updatedUserNotification = await _userNotificationService.UpdateAsync(userNotification);
                    var userNotificationDto = _mapper.Map<UserNotificationDto>(updatedUserNotification);
                    return Ok(userNotificationDto);
                }
                catch (KeyNotFoundException)
                {
                    return NotFound(new { message = $"UserNotification with ID {id} not found" });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating userNotification with ID {UserNotificationId}", id);
                return StatusCode(500, new { message = "An error occurred while updating the userNotification" });
            }
        }

        // DELETE: api/UserNotification/{id}
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteUserNotification(int id)
        {
            try
            {
                var deleted = await _userNotificationService.DeleteAsync(id);
                if (!deleted)
                {
                    return NotFound(new { message = $"UserNotification with ID {id} not found" });
                }

                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting userNotification with ID {UserNotificationId}", id);
                return StatusCode(500, new { message = "An error occurred while deleting the userNotification" });
            }
        }
    }
}

