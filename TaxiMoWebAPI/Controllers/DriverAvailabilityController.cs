using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TaxiMo.Services.Database.Entities;
using TaxiMo.Services.DTOs;
using TaxiMo.Services.Interfaces;

namespace TaxiMoWebAPI.Controllers
{
    [Authorize(Roles = "Admin,Driver")]
    public class DriverAvailabilityController : BaseCRUDController<DriverAvailability, DriverAvailabilityDto, DriverAvailabilityCreateDto, DriverAvailabilityUpdateDto>
    {
        protected override string EntityName => "DriverAvailability";

        public DriverAvailabilityController(
            IDriverAvailabilityService driverAvailabilityService,
            AutoMapper.IMapper mapper,
            ILogger<DriverAvailabilityController> logger) 
            : base(driverAvailabilityService, mapper, logger)
        {
        }
    }
}

