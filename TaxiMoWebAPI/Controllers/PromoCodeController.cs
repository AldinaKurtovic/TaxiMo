using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TaxiMo.Services.Database.Entities;
using TaxiMo.Services.DTOs;
using TaxiMo.Services.Interfaces;

namespace TaxiMoWebAPI.Controllers
{
    [Authorize(Roles = "Admin,User")]
    public class PromoCodeController : BaseCRUDController<PromoCode, PromoCodeDto, PromoCodeCreateDto, PromoCodeUpdateDto>
    {
        protected override string EntityName => "PromoCode";
        private readonly IPromoCodeService _promoCodeService;

        public PromoCodeController(
            IPromoCodeService promoCodeService,
            AutoMapper.IMapper mapper,
            ILogger<PromoCodeController> logger) 
            : base(promoCodeService, mapper, logger)
        {
            _promoCodeService = promoCodeService;
        }

    }
}

