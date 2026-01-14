using System;

namespace TaxiMo.Model.Responses
{
    public class ReviewResponse
    {
        public int ReviewId { get; set; }

        public int RideId { get; set; }
        public int UserId { get; set; }
        public string UserName { get; set; } = null!;
        public string? UserPhotoUrl { get; set; }
        public string? UserFirstName { get; set; }

        public string DriverName { get; set; } = null!;
        public string? DriverPhotoUrl { get; set; }
        public string? DriverFirstName { get; set; }

        public string? Description { get; set; }

        public decimal Rating { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}

