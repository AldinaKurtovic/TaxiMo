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
        private readonly IPaymentService _paymentService;

        public PaymentController(
            IPaymentService paymentService,
            AutoMapper.IMapper mapper,
            ILogger<PaymentController> logger) 
            : base(paymentService, mapper, logger)
        {
            _paymentService = paymentService;
        }

        // GET: api/Payment
        [HttpGet]
        public override async Task<ActionResult<IEnumerable<PaymentDto>>> GetAll([FromQuery] string? search = null, [FromQuery] string? status = null)
        {
            try
            {
                // Parse pagination parameters from query string
                int page = 1;
                int limit = 7;
                if (Request.Query.ContainsKey("page") && int.TryParse(Request.Query["page"].ToString(), out int pageValue))
                {
                    page = pageValue;
                }
                if (Request.Query.ContainsKey("limit") && int.TryParse(Request.Query["limit"].ToString(), out int limitValue))
                {
                    limit = limitValue;
                }

                var pagedResult = await _paymentService.GetAllPagedAsync(page, limit, search);
                var dtos = Mapper.Map<List<PaymentDto>>(pagedResult.Data);
                
                return Ok(new
                {
                    data = dtos,
                    pagination = new
                    {
                        currentPage = pagedResult.Pagination.CurrentPage,
                        totalPages = pagedResult.Pagination.TotalPages,
                        totalItems = pagedResult.Pagination.TotalItems,
                        limit = pagedResult.Pagination.Limit
                    }
                });
            }
            catch (Exception ex)
            {
                Logger.LogError(ex, "Error retrieving {EntityName}", EntityName);
                return StatusCode(500, new { message = $"An error occurred while retrieving {EntityName}" });
            }
        }
    }
}

