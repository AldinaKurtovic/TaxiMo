namespace TaxiMo.Services.DTOs
{
    public class LocationDto
    {
        public int LocationId { get; set; }
        public int? UserId { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? AddressLine { get; set; }
        public string? City { get; set; }
        public decimal Lat { get; set; }
        public decimal Lng { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
    }
}

