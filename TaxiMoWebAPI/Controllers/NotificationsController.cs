using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TaxiMo.Services.DTOs;
using TaxiMo.Services.Interfaces;

namespace TaxiMoWebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class NotificationsController : ControllerBase
    {
        private readonly IUserNotificationService _userNotificationService;
        private readonly IDriverNotificationService _driverNotificationService;
        private readonly AutoMapper.IMapper _mapper;
        private readonly ILogger<NotificationsController> _logger;

        public NotificationsController(
            IUserNotificationService userNotificationService,
            IDriverNotificationService driverNotificationService,
            AutoMapper.IMapper mapper,
            ILogger<NotificationsController> logger)
        {
            _userNotificationService = userNotificationService;
            _driverNotificationService = driverNotificationService;
            _mapper = mapper;
            _logger = logger;
        }

        // GET: api/notifications/user/{userId}
        [HttpGet("user/{userId}")]
        [Authorize(Roles = "User,Admin")]
        public async Task<ActionResult<IEnumerable<UserNotificationDto>>> GetUserNotifications(int userId)
        {
            try
            {
                var notifications = await _userNotificationService.GetNotificationsByUserIdAsync(userId);
                var dtos = _mapper.Map<List<UserNotificationDto>>(notifications);
                return Ok(dtos);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving notifications for user {UserId}", userId);
                return StatusCode(500, new { message = "An error occurred while retrieving notifications" });
            }
        }

        // GET: api/notifications/driver/{driverId}
        [HttpGet("driver/{driverId}")]
        [Authorize(Roles = "Driver,Admin")]
        public async Task<ActionResult<IEnumerable<DriverNotificationDto>>> GetDriverNotifications(int driverId)
        {
            try
            {
                var notifications = await _driverNotificationService.GetNotificationsByDriverIdAsync(driverId);
                var dtos = _mapper.Map<List<DriverNotificationDto>>(notifications);
                return Ok(dtos);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving notifications for driver {DriverId}", driverId);
                return StatusCode(500, new { message = "An error occurred while retrieving notifications" });
            }
        }

        // GET: api/notifications/user/{userId}/unread-count
        [HttpGet("user/{userId}/unread-count")]
        [Authorize(Roles = "User,Admin")]
        public async Task<ActionResult<object>> GetUserUnreadCount(int userId)
        {
            try
            {
                var count = await _userNotificationService.GetUnreadCountByUserIdAsync(userId);
                return Ok(new { unreadCount = count });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving unread count for user {UserId}", userId);
                return StatusCode(500, new { message = "An error occurred while retrieving unread count" });
            }
        }

        // POST: api/notifications/{notificationId}/mark-read
        [HttpPost("{notificationId}/mark-read")]
        [Authorize(Roles = "User,Driver,Admin")]
        public async Task<IActionResult> MarkAsRead(int notificationId, [FromQuery] string? type = null)
        {
            try
            {
                bool result;
                // If type is specified, use it; otherwise try user first, then driver
                if (!string.IsNullOrEmpty(type) && type.ToLower() == "driver")
                {
                    result = await _driverNotificationService.MarkAsReadAsync(notificationId);
                }
                else
                {
                    // Try user notification first
                    result = await _userNotificationService.MarkAsReadAsync(notificationId);
                    if (!result)
                    {
                        // If not found in user notifications, try driver notifications
                        result = await _driverNotificationService.MarkAsReadAsync(notificationId);
                    }
                }

                if (!result)
                {
                    return NotFound(new { message = $"Notification with ID {notificationId} not found" });
                }
                return Ok(new { message = "Notification marked as read" });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error marking notification {NotificationId} as read", notificationId);
                return StatusCode(500, new { message = "An error occurred while marking notification as read" });
            }
        }
    }
}
