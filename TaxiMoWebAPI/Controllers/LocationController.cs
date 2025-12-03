using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TaxiMo.Services.Database.Entities;
using TaxiMo.Services.DTOs;
using TaxiMo.Services.Interfaces;

namespace TaxiMoWebAPI.Controllers
{
    [Authorize(Roles = "User,Admin")]
    public class LocationController : BaseCRUDController<Location, LocationDto, LocationCreateDto, LocationUpdateDto>
    {
        protected override string EntityName => "Location";

        public LocationController(
            ILocationService locationService,
            AutoMapper.IMapper mapper,
            ILogger<LocationController> logger) 
            : base(locationService, mapper, logger)
        {
        }
    }
}
