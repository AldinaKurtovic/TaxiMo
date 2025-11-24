namespace TaxiMo.Services.DTOs
{
    public class DriverNotificationDto
    {
        public int NotificationId { get; set; }
        public int RecipientDriverId { get; set; }
        public string Title { get; set; } = string.Empty;
        public string? Body { get; set; }
        public string Type { get; set; } = string.Empty;
        public bool IsRead { get; set; }
        public DateTime SentAt { get; set; }
    }
}

