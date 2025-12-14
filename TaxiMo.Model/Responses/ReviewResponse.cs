namespace TaxiMo.Model.Responses
{
    public class ReviewResponse
    {
        public int ReviewId { get; set; }

        public int UserId { get; set; }
        public string UserName { get; set; } = null!;

        public string DriverName { get; set; } = null!;

        public string? Description { get; set; }

        public decimal Rating { get; set; }
    }
}

