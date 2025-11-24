using AutoMapper;
using Microsoft.AspNetCore.Mvc;
using TaxiMo.Services.Database.Entities;
using TaxiMo.Services.DTOs;
using TaxiMo.Services.Interfaces;

namespace TaxiMoWebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class PaymentController : ControllerBase
    {
        private readonly IPaymentService _paymentService;
        private readonly IMapper _mapper;
        private readonly ILogger<PaymentController> _logger;

        public PaymentController(IPaymentService paymentService, IMapper mapper, ILogger<PaymentController> logger)
        {
            _paymentService = paymentService;
            _mapper = mapper;
            _logger = logger;
        }

        // GET: api/Payment
        [HttpGet]
        public async Task<ActionResult<IEnumerable<PaymentDto>>> GetPayments()
        {
            try
            {
                var payments = await _paymentService.GetAllAsync();
                var paymentDtos = _mapper.Map<List<PaymentDto>>(payments);
                return Ok(paymentDtos);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving payments");
                return StatusCode(500, new { message = "An error occurred while retrieving payments" });
            }
        }

        // GET: api/Payment/{id}
        [HttpGet("{id}")]
        public async Task<ActionResult<PaymentDto>> GetPayment(int id)
        {
            try
            {
                var payment = await _paymentService.GetByIdAsync(id);

                if (payment == null)
                {
                    return NotFound(new { message = $"Payment with ID {id} not found" });
                }

                var paymentDto = _mapper.Map<PaymentDto>(payment);
                return Ok(paymentDto);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving payment with ID {PaymentId}", id);
                return StatusCode(500, new { message = "An error occurred while retrieving the payment" });
            }
        }

        // POST: api/Payment
        [HttpPost]
        public async Task<ActionResult<PaymentDto>> CreatePayment(PaymentCreateDto paymentCreateDto)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    return BadRequest(ModelState);
                }

                var payment = _mapper.Map<Payment>(paymentCreateDto);
                var createdPayment = await _paymentService.CreateAsync(payment);
                var paymentDto = _mapper.Map<PaymentDto>(createdPayment);

                return CreatedAtAction(nameof(GetPayment), new { id = paymentDto.PaymentId }, paymentDto);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating payment");
                return StatusCode(500, new { message = "An error occurred while creating the payment" });
            }
        }

        // PUT: api/Payment/{id}
        [HttpPut("{id}")]
        public async Task<ActionResult<PaymentDto>> UpdatePayment(int id, PaymentUpdateDto paymentUpdateDto)
        {
            try
            {
                if (id != paymentUpdateDto.PaymentId)
                {
                    return BadRequest(new { message = "Payment ID mismatch" });
                }

                if (!ModelState.IsValid)
                {
                    return BadRequest(ModelState);
                }

                try
                {
                    var payment = _mapper.Map<Payment>(paymentUpdateDto);
                    var updatedPayment = await _paymentService.UpdateAsync(payment);
                    var paymentDto = _mapper.Map<PaymentDto>(updatedPayment);
                    return Ok(paymentDto);
                }
                catch (KeyNotFoundException)
                {
                    return NotFound(new { message = $"Payment with ID {id} not found" });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating payment with ID {PaymentId}", id);
                return StatusCode(500, new { message = "An error occurred while updating the payment" });
            }
        }

        // DELETE: api/Payment/{id}
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeletePayment(int id)
        {
            try
            {
                var deleted = await _paymentService.DeleteAsync(id);
                if (!deleted)
                {
                    return NotFound(new { message = $"Payment with ID {id} not found" });
                }

                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting payment with ID {PaymentId}", id);
                return StatusCode(500, new { message = "An error occurred while deleting the payment" });
            }
        }
    }
}

