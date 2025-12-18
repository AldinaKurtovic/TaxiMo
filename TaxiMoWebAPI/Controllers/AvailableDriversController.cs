using AutoMapper;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TaxiMo.Services.DTOs;
using TaxiMo.Services.Interfaces;

namespace TaxiMoWebAPI.Controllers
{
    [ApiController]
    [Route("api/rides/available-drivers")]
    [Authorize(Roles = "User")]
    public class AvailableDriversController : ControllerBase
    {
        private readonly IDriverService _driverService;
        private readonly IMapper _mapper;
        private readonly ILogger<AvailableDriversController> _logger;

        public AvailableDriversController(
            IDriverService driverService,
            IMapper mapper,
            ILogger<AvailableDriversController> logger)
        {
            _driverService = driverService;
            _mapper = mapper;
            _logger = logger;
        }

        // GET: api/rides/available-drivers
        [HttpGet]
        public async Task<ActionResult<IEnumerable<DriverDto>>> GetAvailableDrivers()
        {
            try
            {
                var freeDrivers = await _driverService.GetFreeDriversAsync();
                var driverDtos = _mapper.Map<List<DriverDto>>(freeDrivers);
                return Ok(driverDtos);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving available drivers");
                return StatusCode(500, new { message = "An error occurred while retrieving available drivers" });
            }
        }
    }
}

