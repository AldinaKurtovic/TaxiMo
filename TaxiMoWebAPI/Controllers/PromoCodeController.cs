using AutoMapper;
using Microsoft.AspNetCore.Mvc;
using TaxiMo.Services.Database.Entities;
using TaxiMo.Services.DTOs;
using TaxiMo.Services.Interfaces;

namespace TaxiMoWebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class PromoCodeController : ControllerBase
    {
        private readonly IPromoCodeService _promoCodeService;
        private readonly IMapper _mapper;
        private readonly ILogger<PromoCodeController> _logger;

        public PromoCodeController(IPromoCodeService promoCodeService, IMapper mapper, ILogger<PromoCodeController> logger)
        {
            _promoCodeService = promoCodeService;
            _mapper = mapper;
            _logger = logger;
        }

        // GET: api/PromoCode
        [HttpGet]
        public async Task<ActionResult<IEnumerable<PromoCodeDto>>> GetPromoCodes()
        {
            try
            {
                var promoCodes = await _promoCodeService.GetAllAsync();
                var promoCodeDtos = _mapper.Map<List<PromoCodeDto>>(promoCodes);
                return Ok(promoCodeDtos);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving promoCodes");
                return StatusCode(500, new { message = "An error occurred while retrieving promoCodes" });
            }
        }

        // GET: api/PromoCode/{id}
        [HttpGet("{id}")]
        public async Task<ActionResult<PromoCodeDto>> GetPromoCode(int id)
        {
            try
            {
                var promoCode = await _promoCodeService.GetByIdAsync(id);

                if (promoCode == null)
                {
                    return NotFound(new { message = $"PromoCode with ID {id} not found" });
                }

                var promoCodeDto = _mapper.Map<PromoCodeDto>(promoCode);
                return Ok(promoCodeDto);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving promoCode with ID {PromoCodeId}", id);
                return StatusCode(500, new { message = "An error occurred while retrieving the promoCode" });
            }
        }

        // POST: api/PromoCode
        [HttpPost]
        public async Task<ActionResult<PromoCodeDto>> CreatePromoCode(PromoCodeCreateDto promoCodeCreateDto)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    return BadRequest(ModelState);
                }

                var promoCode = _mapper.Map<PromoCode>(promoCodeCreateDto);
                var createdPromoCode = await _promoCodeService.CreateAsync(promoCode);
                var promoCodeDto = _mapper.Map<PromoCodeDto>(createdPromoCode);

                return CreatedAtAction(nameof(GetPromoCode), new { id = promoCodeDto.PromoId }, promoCodeDto);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating promoCode");
                return StatusCode(500, new { message = "An error occurred while creating the promoCode" });
            }
        }

        // PUT: api/PromoCode/{id}
        [HttpPut("{id}")]
        public async Task<ActionResult<PromoCodeDto>> UpdatePromoCode(int id, PromoCodeUpdateDto promoCodeUpdateDto)
        {
            try
            {
                if (id != promoCodeUpdateDto.PromoId)
                {
                    return BadRequest(new { message = "PromoCode ID mismatch" });
                }

                if (!ModelState.IsValid)
                {
                    return BadRequest(ModelState);
                }

                try
                {
                    var promoCode = _mapper.Map<PromoCode>(promoCodeUpdateDto);
                    var updatedPromoCode = await _promoCodeService.UpdateAsync(promoCode);
                    var promoCodeDto = _mapper.Map<PromoCodeDto>(updatedPromoCode);
                    return Ok(promoCodeDto);
                }
                catch (KeyNotFoundException)
                {
                    return NotFound(new { message = $"PromoCode with ID {id} not found" });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating promoCode with ID {PromoCodeId}", id);
                return StatusCode(500, new { message = "An error occurred while updating the promoCode" });
            }
        }

        // DELETE: api/PromoCode/{id}
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeletePromoCode(int id)
        {
            try
            {
                var deleted = await _promoCodeService.DeleteAsync(id);
                if (!deleted)
                {
                    return NotFound(new { message = $"PromoCode with ID {id} not found" });
                }

                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting promoCode with ID {PromoCodeId}", id);
                return StatusCode(500, new { message = "An error occurred while deleting the promoCode" });
            }
        }
    }
}

