namespace TaxiMo.Services.DTOs
{
    public class PromoUsageDto
    {
        public int PromoUsageId { get; set; }
        public int PromoId { get; set; }
        public int UserId { get; set; }
        public int RideId { get; set; }
        public DateTime UsedAt { get; set; }
    }
}

