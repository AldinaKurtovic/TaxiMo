using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TaxiMo.Services.Database.Entities;
using TaxiMo.Services.DTOs;
using TaxiMo.Services.Interfaces;

namespace TaxiMoWebAPI.Controllers
{
    [Authorize(Roles = "User,Admin")]
    public class PaymentController : BaseCRUDController<Payment, PaymentDto, PaymentCreateDto, PaymentUpdateDto>
    {
        protected override string EntityName => "Payment";

        public PaymentController(
            IPaymentService paymentService,
            AutoMapper.IMapper mapper,
            ILogger<PaymentController> logger) 
            : base(paymentService, mapper, logger)
        {
        }
    }
}

