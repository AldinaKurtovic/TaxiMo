using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
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

        
    }
}

