using AutoMapper;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TaxiMo.Services.Database.Entities;
using TaxiMo.Services.DTOs;
using TaxiMo.Services.Interfaces;

namespace TaxiMoWebAPI.Controllers
{
    [Authorize(Roles = "User,Driver,Admin")]
    public class RideController : BaseCRUDController<Ride, RideDto, RideCreateDto, RideUpdateDto>
    {
        protected override string EntityName => "Ride";
        private readonly IRideService _rideService;

        public RideController(
            IRideService rideService,
            AutoMapper.IMapper mapper,
            ILogger<RideController> logger) 
            : base(rideService, mapper, logger)
        {
            _rideService = rideService;
        }

        // GET: api/Ride?search=xxx&status=xxx
        // Override base GetAll to use IRideService.GetAllAsync with search and status parameters
        [HttpGet]
        public override async Task<ActionResult<IEnumerable<RideDto>>> GetAll([FromQuery] string? search = null, [FromQuery] string? status = null)
        {
            try
            {
                var rides = await _rideService.GetAllAsync(search, status);
                var responses = Mapper.Map<List<RideResponse>>(rides);
                // Return RideResponse list (will be serialized correctly by ASP.NET Core)
                return new OkObjectResult(responses);
            }
            catch (Exception ex)
            {
                Logger.LogError(ex, "Error retrieving rides");
                return StatusCode(500, new { message = "An error occurred while retrieving rides" });
            }
        }
    }
}

