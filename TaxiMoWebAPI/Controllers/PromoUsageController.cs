using AutoMapper;
using Microsoft.AspNetCore.Mvc;
using TaxiMo.Services.Database.Entities;
using TaxiMo.Services.DTOs;
using TaxiMo.Services.Interfaces;

namespace TaxiMoWebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class PromoUsageController : ControllerBase
    {
        private readonly IPromoUsageService _promoUsageService;
        private readonly IMapper _mapper;
        private readonly ILogger<PromoUsageController> _logger;

        public PromoUsageController(IPromoUsageService promoUsageService, IMapper mapper, ILogger<PromoUsageController> logger)
        {
            _promoUsageService = promoUsageService;
            _mapper = mapper;
            _logger = logger;
        }

        // GET: api/PromoUsage
        [HttpGet]
        public async Task<ActionResult<IEnumerable<PromoUsageDto>>> GetPromoUsages()
        {
            try
            {
                var promoUsages = await _promoUsageService.GetAllAsync();
                var promoUsageDtos = _mapper.Map<List<PromoUsageDto>>(promoUsages);
                return Ok(promoUsageDtos);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving promoUsages");
                return StatusCode(500, new { message = "An error occurred while retrieving promoUsages" });
            }
        }

        // GET: api/PromoUsage/{id}
        [HttpGet("{id}")]
        public async Task<ActionResult<PromoUsageDto>> GetPromoUsage(int id)
        {
            try
            {
                var promoUsage = await _promoUsageService.GetByIdAsync(id);

                if (promoUsage == null)
                {
                    return NotFound(new { message = $"PromoUsage with ID {id} not found" });
                }

                var promoUsageDto = _mapper.Map<PromoUsageDto>(promoUsage);
                return Ok(promoUsageDto);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving promoUsage with ID {PromoUsageId}", id);
                return StatusCode(500, new { message = "An error occurred while retrieving the promoUsage" });
            }
        }

        // POST: api/PromoUsage
        [HttpPost]
        public async Task<ActionResult<PromoUsageDto>> CreatePromoUsage(PromoUsageCreateDto promoUsageCreateDto)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    return BadRequest(ModelState);
                }

                var promoUsage = _mapper.Map<PromoUsage>(promoUsageCreateDto);
                var createdPromoUsage = await _promoUsageService.CreateAsync(promoUsage);
                var promoUsageDto = _mapper.Map<PromoUsageDto>(createdPromoUsage);

                return CreatedAtAction(nameof(GetPromoUsage), new { id = promoUsageDto.PromoUsageId }, promoUsageDto);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating promoUsage");
                return StatusCode(500, new { message = "An error occurred while creating the promoUsage" });
            }
        }

        // PUT: api/PromoUsage/{id}
        [HttpPut("{id}")]
        public async Task<ActionResult<PromoUsageDto>> UpdatePromoUsage(int id, PromoUsageUpdateDto promoUsageUpdateDto)
        {
            try
            {
                if (id != promoUsageUpdateDto.PromoUsageId)
                {
                    return BadRequest(new { message = "PromoUsage ID mismatch" });
                }

                if (!ModelState.IsValid)
                {
                    return BadRequest(ModelState);
                }

                try
                {
                    var promoUsage = _mapper.Map<PromoUsage>(promoUsageUpdateDto);
                    var updatedPromoUsage = await _promoUsageService.UpdateAsync(promoUsage);
                    var promoUsageDto = _mapper.Map<PromoUsageDto>(updatedPromoUsage);
                    return Ok(promoUsageDto);
                }
                catch (KeyNotFoundException)
                {
                    return NotFound(new { message = $"PromoUsage with ID {id} not found" });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating promoUsage with ID {PromoUsageId}", id);
                return StatusCode(500, new { message = "An error occurred while updating the promoUsage" });
            }
        }

        // DELETE: api/PromoUsage/{id}
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeletePromoUsage(int id)
        {
            try
            {
                var deleted = await _promoUsageService.DeleteAsync(id);
                if (!deleted)
                {
                    return NotFound(new { message = $"PromoUsage with ID {id} not found" });
                }

                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting promoUsage with ID {PromoUsageId}", id);
                return StatusCode(500, new { message = "An error occurred while deleting the promoUsage" });
            }
        }
    }
}

