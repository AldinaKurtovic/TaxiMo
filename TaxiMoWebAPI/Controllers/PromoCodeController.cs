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

        // Override GetAll to use custom service method with search, isActive, and sorting parameters
        // Accept base class signature but also support additional query parameters
        [HttpGet]
        public override async Task<ActionResult<IEnumerable<PromoCodeDto>>> GetAll([FromQuery] string? search = null, [FromQuery] string? status = null)
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

                // Convert status string to bool? for service method
                bool? isActive = null;
                if (!string.IsNullOrWhiteSpace(status))
                {
                    if (status.Equals("active", StringComparison.OrdinalIgnoreCase) || 
                        status.Equals("true", StringComparison.OrdinalIgnoreCase))
                    {
                        isActive = true;
                    }
                    else if (status.Equals("inactive", StringComparison.OrdinalIgnoreCase) || 
                             status.Equals("false", StringComparison.OrdinalIgnoreCase))
                    {
                        isActive = false;
                    }
                }

                // Also check for isActive query parameter (for frontend compatibility)
                if (Request.Query.ContainsKey("isActive"))
                {
                    if (bool.TryParse(Request.Query["isActive"].ToString(), out bool isActiveValue))
                    {
                        isActive = isActiveValue;
                    }
                }

                // Get sorting parameters
                string? sortBy = Request.Query.ContainsKey("sortBy") ? Request.Query["sortBy"].ToString() : null;
                string? sortOrder = Request.Query.ContainsKey("sortOrder") ? Request.Query["sortOrder"].ToString() : null;

                var pagedResult = await _promoCodeService.GetAllPagedAsync(page, limit, search, isActive, sortBy, sortOrder);
                var dtos = Mapper.Map<List<PromoCodeDto>>(pagedResult.Data);
                
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

        // Override Create to return proper response format
        [HttpPost]
        public override async Task<ActionResult<PromoCodeDto>> Create(PromoCodeCreateDto createDto)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    return BadRequest(new { message = "Validation failed.", errors = ModelState });
                }

                var entity = Mapper.Map<PromoCode>(createDto);
                var createdEntity = await _promoCodeService.CreateAsync(entity);
                var dto = Mapper.Map<PromoCodeDto>(createdEntity);

                // Return Ok with custom object - ActionResult<T> can wrap any object
                return Ok(new
                {
                    message = $"Promo code '{createdEntity.Code}' successfully created.",
                    data = dto
                });
            }
            catch (Exception ex)
            {
                Logger.LogError(ex, "Error creating {EntityName}", EntityName);
                return StatusCode(500, new { message = $"An error occurred while creating the {EntityName}" });
            }
        }

        // Override Update to return proper response format
        [HttpPut("{id}")]
        public override async Task<ActionResult<PromoCodeDto>> Update(int id, PromoCodeUpdateDto updateDto)
        {
            try
            {
                if (id != updateDto.PromoId)
                {
                    return BadRequest(new { message = "Promo code ID mismatch." });
                }

                if (!ModelState.IsValid)
                {
                    return BadRequest(new { message = "Validation failed.", errors = ModelState });
                }

                var entity = Mapper.Map<PromoCode>(updateDto);
                var updatedEntity = await _promoCodeService.UpdateAsync(entity);
                var dto = Mapper.Map<PromoCodeDto>(updatedEntity);

                // Return Ok with custom object - ActionResult<T> can wrap any object
                return Ok(new
                {
                    message = $"Promo code '{updatedEntity.Code}' successfully updated.",
                    data = dto
                });
            }
            catch (TaxiMo.Model.Exceptions.UserException ex)
            {
                return NotFound(new { message = ex.Message });
            }
            catch (Exception ex)
            {
                Logger.LogError(ex, "Error updating {EntityName} with ID {Id}", EntityName, id);
                return StatusCode(500, new { message = $"An error occurred while updating the {EntityName}" });
            }
        }
    }
}

