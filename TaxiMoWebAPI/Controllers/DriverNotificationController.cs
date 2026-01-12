using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TaxiMo.Services.Database.Entities;
using TaxiMo.Services.DTOs;
using TaxiMo.Services.Interfaces;

namespace TaxiMoWebAPI.Controllers
{
    [Authorize(Roles = "Admin,Driver")]
    public class DriverNotificationController : BaseCRUDController<DriverNotification, DriverNotificationDto, DriverNotificationCreateDto, DriverNotificationUpdateDto>
    {
        protected override string EntityName => "DriverNotification";
        private readonly IDriverNotificationService _driverNotificationService;

        public DriverNotificationController(
            IDriverNotificationService driverNotificationService,
            AutoMapper.IMapper mapper,
            ILogger<DriverNotificationController> logger) 
            : base(driverNotificationService, mapper, logger)
        {
            _driverNotificationService = driverNotificationService;
        }

        // GET: api/notifications/driver/{driverId}
        [HttpGet("driver/{driverId}")]
        public async Task<ActionResult<IEnumerable<DriverNotificationDto>>> GetNotificationsByDriverId(int driverId)
        {
            try
            {
                var notifications = await _driverNotificationService.GetNotificationsByDriverIdAsync(driverId);
                var dtos = Mapper.Map<List<DriverNotificationDto>>(notifications);
                return Ok(dtos);
            }
            catch (Exception ex)
            {
                Logger.LogError(ex, "Error retrieving notifications for driver {DriverId}", driverId);
                return StatusCode(500, new { message = "An error occurred while retrieving notifications" });
            }
        }

        // POST: api/notifications/{notificationId}/mark-read
        [HttpPost("{notificationId}/mark-read")]
        public async Task<IActionResult> MarkAsRead(int notificationId)
        {
            try
            {
                var result = await _driverNotificationService.MarkAsReadAsync(notificationId);
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

