using AutoMapper;
using Microsoft.AspNetCore.Mvc;
using TaxiMo.Services.Database.Entities;
using TaxiMo.Services.DTOs;
using TaxiMo.Services.Interfaces;

namespace TaxiMoWebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ReviewController : ControllerBase
    {
        private readonly IReviewService _reviewService;
        private readonly IMapper _mapper;
        private readonly ILogger<ReviewController> _logger;

        public ReviewController(IReviewService reviewService, IMapper mapper, ILogger<ReviewController> logger)
        {
            _reviewService = reviewService;
            _mapper = mapper;
            _logger = logger;
        }

        // GET: api/Review
        [HttpGet]
        public async Task<ActionResult<IEnumerable<ReviewDto>>> GetReviews()
        {
            try
            {
                var reviews = await _reviewService.GetAllAsync();
                var reviewDtos = _mapper.Map<List<ReviewDto>>(reviews);
                return Ok(reviewDtos);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving reviews");
                return StatusCode(500, new { message = "An error occurred while retrieving reviews" });
            }
        }

        // GET: api/Review/{id}
        [HttpGet("{id}")]
        public async Task<ActionResult<ReviewDto>> GetReview(int id)
        {
            try
            {
                var review = await _reviewService.GetByIdAsync(id);

                if (review == null)
                {
                    return NotFound(new { message = $"Review with ID {id} not found" });
                }

                var reviewDto = _mapper.Map<ReviewDto>(review);
                return Ok(reviewDto);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving review with ID {ReviewId}", id);
                return StatusCode(500, new { message = "An error occurred while retrieving the review" });
            }
        }

        // POST: api/Review
        [HttpPost]
        public async Task<ActionResult<ReviewDto>> CreateReview(ReviewCreateDto reviewCreateDto)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    return BadRequest(ModelState);
                }

                var review = _mapper.Map<Review>(reviewCreateDto);
                var createdReview = await _reviewService.CreateAsync(review);
                var reviewDto = _mapper.Map<ReviewDto>(createdReview);

                return CreatedAtAction(nameof(GetReview), new { id = reviewDto.ReviewId }, reviewDto);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating review");
                return StatusCode(500, new { message = "An error occurred while creating the review" });
            }
        }

        // PUT: api/Review/{id}
        [HttpPut("{id}")]
        public async Task<ActionResult<ReviewDto>> UpdateReview(int id, ReviewUpdateDto reviewUpdateDto)
        {
            try
            {
                if (id != reviewUpdateDto.ReviewId)
                {
                    return BadRequest(new { message = "Review ID mismatch" });
                }

                if (!ModelState.IsValid)
                {
                    return BadRequest(ModelState);
                }

                try
                {
                    var review = _mapper.Map<Review>(reviewUpdateDto);
                    var updatedReview = await _reviewService.UpdateAsync(review);
                    var reviewDto = _mapper.Map<ReviewDto>(updatedReview);
                    return Ok(reviewDto);
                }
                catch (KeyNotFoundException)
                {
                    return NotFound(new { message = $"Review with ID {id} not found" });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating review with ID {ReviewId}", id);
                return StatusCode(500, new { message = "An error occurred while updating the review" });
            }
        }

        // DELETE: api/Review/{id}
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteReview(int id)
        {
            try
            {
                var deleted = await _reviewService.DeleteAsync(id);
                if (!deleted)
                {
                    return NotFound(new { message = $"Review with ID {id} not found" });
                }

                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting review with ID {ReviewId}", id);
                return StatusCode(500, new { message = "An error occurred while deleting the review" });
            }
        }
    }
}

