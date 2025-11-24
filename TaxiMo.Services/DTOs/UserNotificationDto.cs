namespace TaxiMo.Services.DTOs
{
    public class UserNotificationDto
    {
        public int NotificationId { get; set; }
        public int RecipientUserId { get; set; }
        public string Title { get; set; } = string.Empty;
        public string? Body { get; set; }
        public string Type { get; set; } = string.Empty;
        public bool IsRead { get; set; }
        public DateTime SentAt { get; set; }
    }
}

