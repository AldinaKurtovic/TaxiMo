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

     
    }
}

