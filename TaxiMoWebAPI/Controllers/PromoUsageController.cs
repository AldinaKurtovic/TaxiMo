using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TaxiMo.Services.Database.Entities;
using TaxiMo.Services.DTOs;
using TaxiMo.Services.Interfaces;

namespace TaxiMoWebAPI.Controllers
{
    [Authorize(Roles = "Admin,User")]
    public class PromoUsageController : BaseCRUDController<PromoUsage, PromoUsageDto, PromoUsageCreateDto, PromoUsageUpdateDto>
    {
        protected override string EntityName => "PromoUsage";

        public PromoUsageController(
            IPromoUsageService promoUsageService,
            AutoMapper.IMapper mapper,
            ILogger<PromoUsageController> logger) 
            : base(promoUsageService, mapper, logger)
        {
        }
    }
}

