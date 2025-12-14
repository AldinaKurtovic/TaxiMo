using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TaxiMo.Model.Responses;
using TaxiMo.Services.Database.Entities;
using TaxiMo.Services.DTOs;
using TaxiMo.Services.Interfaces;

namespace TaxiMoWebAPI.Controllers
{
    [Authorize(Roles = "User,Driver,Admin")]
    public class ReviewController : BaseCRUDController<Review, ReviewDto, ReviewCreateDto, ReviewUpdateDto>
    {
        protected override string EntityName => "Review";
        private readonly IReviewService _reviewService;

        public ReviewController(
            IReviewService reviewService,
            AutoMapper.IMapper mapper,
            ILogger<ReviewController> logger) 
            : base(reviewService, mapper, logger)
        {
            _reviewService = reviewService;
        }

        // GET: api/Review
        [HttpGet]
        public override async Task<ActionResult<IEnumerable<ReviewDto>>> GetAll([FromQuery] string? search = null, [FromQuery] string? status = null)
        {
            try
            {
                var entities = await _reviewService.GetAllAsync();
                var responses = Mapper.Map<List<ReviewResponse>>(entities);
                return Ok(responses);
            }
            catch (Exception ex)
            {
                Logger.LogError(ex, "Error retrieving {EntityName}", EntityName);
                return StatusCode(500, new { message = $"An error occurred while retrieving {EntityName}" });
            }
        }

        // GET: api/Review/{id}
        [HttpGet("{id}")]
        public override async Task<ActionResult<ReviewDto>> GetById(int id)
        {
            try
            {
                var entity = await _reviewService.GetByIdAsync(id);

                if (entity == null)
                {
                    return NotFound(new { message = $"{EntityName} with ID {id} not found" });
                }

                var response = Mapper.Map<ReviewResponse>(entity);
                return Ok(response);
            }
            catch (Exception ex)
            {
                Logger.LogError(ex, "Error retrieving {EntityName} with ID {Id}", EntityName, id);
                return StatusCode(500, new { message = $"An error occurred while retrieving the {EntityName}" });
            }
        }
    }
}

