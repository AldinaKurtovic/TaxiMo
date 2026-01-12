using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TaxiMo.Services.Database.Entities;
using TaxiMo.Services.DTOs;
using TaxiMo.Services.Interfaces;

namespace TaxiMoWebAPI.Controllers
{
    [Authorize(Roles = "User,Admin")]
    public class UserNotificationController : BaseCRUDController<UserNotification, UserNotificationDto, UserNotificationCreateDto, UserNotificationUpdateDto>
    {
        protected override string EntityName => "UserNotification";
        private readonly IUserNotificationService _userNotificationService;

        public UserNotificationController(
            IUserNotificationService userNotificationService,
            AutoMapper.IMapper mapper,
            ILogger<UserNotificationController> logger) 
            : base(userNotificationService, mapper, logger)
        {
            _userNotificationService = userNotificationService;
        }

        // GET: api/notifications/user/{userId}
        [HttpGet("user/{userId}")]
        public async Task<ActionResult<IEnumerable<UserNotificationDto>>> GetNotificationsByUserId(int userId)
        {
            try
            {
                var notifications = await _userNotificationService.GetNotificationsByUserIdAsync(userId);
                var dtos = Mapper.Map<List<UserNotificationDto>>(notifications);
                return Ok(dtos);
            }
            catch (Exception ex)
            {
                Logger.LogError(ex, "Error retrieving notifications for user {UserId}", userId);
                return StatusCode(500, new { message = "An error occurred while retrieving notifications" });
            }
        }

        // GET: api/notifications/user/{userId}/unread-count
        [HttpGet("user/{userId}/unread-count")]
        public async Task<ActionResult<object>> GetUnreadCount(int userId)
        {
            try
            {
                var count = await _userNotificationService.GetUnreadCountByUserIdAsync(userId);
                return Ok(new { unreadCount = count });
            }
            catch (Exception ex)
            {
                Logger.LogError(ex, "Error retrieving unread count for user {UserId}", userId);
                return StatusCode(500, new { message = "An error occurred while retrieving unread count" });
            }
        }

        // POST: api/notifications/{notificationId}/mark-read
        [HttpPost("{notificationId}/mark-read")]
        public async Task<IActionResult> MarkAsRead(int notificationId)
        {
            try
            {
                var result = await _userNotificationService.MarkAsReadAsync(notificationId);
                if (!result)
                {
                    return NotFound(new { message = $"Notification with ID {notificationId} not found" });
                }
                return Ok(new { message = "Notification marked as read" });
            }
            catch (Exception ex)
            {
                Logger.LogError(ex, "Error marking notification {NotificationId} as read", notificationId);
                return StatusCode(500, new { message = "An error occurred while marking notification as read" });
            }
        }
    }
}

