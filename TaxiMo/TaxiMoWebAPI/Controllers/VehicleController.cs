using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TaxiMo.Services.Database.Entities;
using TaxiMo.Services.DTOs;
using TaxiMo.Services.Interfaces;

namespace TaxiMoWebAPI.Controllers
{
    [Authorize(Roles = "Admin,Driver")]
    public class VehicleController : BaseCRUDController<Vehicle, VehicleDto, VehicleCreateDto, VehicleUpdateDto>
    {
        protected override string EntityName => "Vehicle";

        public VehicleController(
            IVehicleService vehicleService,
            AutoMapper.IMapper mapper,
            ILogger<VehicleController> logger) 
            : base(vehicleService, mapper, logger)
        {
        }
    }
}
