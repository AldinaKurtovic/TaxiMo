namespace TaxiMo.Services.DTOs
{
    public class DriverDto
    {
        public int DriverId { get; set; }
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string? Phone { get; set; }
        public string LicenseNumber { get; set; } = string.Empty;
        public string? Username { get; set; }=string.Empty;
        public DateTime LicenseExpiry { get; set; }
        public decimal? RatingAvg { get; set; }
        public int TotalRides { get; set; }
        public string Status { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
        public List<string> Roles { get; set; } = new();
    }
}

