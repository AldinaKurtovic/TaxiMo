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

        public DriverNotificationController(
            IDriverNotificationService driverNotificationService,
            AutoMapper.IMapper mapper,
            ILogger<DriverNotificationController> logger) 
            : base(driverNotificationService, mapper, logger)
        {
        }
    }
}

