using AutoMapper;
using Microsoft.AspNetCore.Mvc;
using TaxiMo.Services.Database.Entities;
using TaxiMo.Services.DTOs;
using TaxiMo.Services.Interfaces;

namespace TaxiMoWebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class DriverNotificationController : ControllerBase
    {
        private readonly IDriverNotificationService _driverNotificationService;
        private readonly IMapper _mapper;
        private readonly ILogger<DriverNotificationController> _logger;

        public DriverNotificationController(IDriverNotificationService driverNotificationService, IMapper mapper, ILogger<DriverNotificationController> logger)
        {
            _driverNotificationService = driverNotificationService;
            _mapper = mapper;
            _logger = logger;
        }

        // GET: api/DriverNotification
        [HttpGet]
        public async Task<ActionResult<IEnumerable<DriverNotificationDto>>> GetDriverNotifications()
        {
            try
            {
                var driverNotifications = await _driverNotificationService.GetAllAsync();
                var driverNotificationDtos = _mapper.Map<List<DriverNotificationDto>>(driverNotifications);
                return Ok(driverNotificationDtos);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving driverNotifications");
                return StatusCode(500, new { message = "An error occurred while retrieving driverNotifications" });
            }
        }

        // GET: api/DriverNotification/{id}
        [HttpGet("{id}")]
        public async Task<ActionResult<DriverNotificationDto>> GetDriverNotification(int id)
        {
            try
            {
                var driverNotification = await _driverNotificationService.GetByIdAsync(id);

                if (driverNotification == null)
                {
                    return NotFound(new { message = $"DriverNotification with ID {id} not found" });
                }

                var driverNotificationDto = _mapper.Map<DriverNotificationDto>(driverNotification);
                return Ok(driverNotificationDto);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving driverNotification with ID {DriverNotificationId}", id);
                return StatusCode(500, new { message = "An error occurred while retrieving the driverNotification" });
            }
        }

        // POST: api/DriverNotification
        [HttpPost]
        public async Task<ActionResult<DriverNotificationDto>> CreateDriverNotification(DriverNotificationCreateDto driverNotificationCreateDto)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    return BadRequest(ModelState);
                }

                var driverNotification = _mapper.Map<DriverNotification>(driverNotificationCreateDto);
                var createdDriverNotification = await _driverNotificationService.CreateAsync(driverNotification);
                var driverNotificationDto = _mapper.Map<DriverNotificationDto>(createdDriverNotification);

                return CreatedAtAction(nameof(GetDriverNotification), new { id = driverNotificationDto.NotificationId }, driverNotificationDto);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating driverNotification");
                return StatusCode(500, new { message = "An error occurred while creating the driverNotification" });
            }
        }

        // PUT: api/DriverNotification/{id}
        [HttpPut("{id}")]
        public async Task<ActionResult<DriverNotificationDto>> UpdateDriverNotification(int id, DriverNotificationUpdateDto driverNotificationUpdateDto)
        {
            try
            {
                if (id != driverNotificationUpdateDto.NotificationId)
                {
                    return BadRequest(new { message = "DriverNotification ID mismatch" });
                }

                if (!ModelState.IsValid)
                {
                    return BadRequest(ModelState);
                }

                try
                {
                    var driverNotification = _mapper.Map<DriverNotification>(driverNotificationUpdateDto);
                    var updatedDriverNotification = await _driverNotificationService.UpdateAsync(driverNotification);
                    var driverNotificationDto = _mapper.Map<DriverNotificationDto>(updatedDriverNotification);
                    return Ok(driverNotificationDto);
                }
                catch (KeyNotFoundException)
                {
                    return NotFound(new { message = $"DriverNotification with ID {id} not found" });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating driverNotification with ID {DriverNotificationId}", id);
                return StatusCode(500, new { message = "An error occurred while updating the driverNotification" });
            }
        }

        // DELETE: api/DriverNotification/{id}
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteDriverNotification(int id)
        {
            try
            {
                var deleted = await _driverNotificationService.DeleteAsync(id);
                if (!deleted)
                {
                    return NotFound(new { message = $"DriverNotification with ID {id} not found" });
                }

                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting driverNotification with ID {DriverNotificationId}", id);
                return StatusCode(500, new { message = "An error occurred while deleting the driverNotification" });
            }
        }
    }
}

