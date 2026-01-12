namespace TaxiMo.Services.DTOs.Auth
{
    public class UserResponse
    {
        public int UserId { get; set; }
        public string Username { get; set; } = string.Empty;
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string? Phone { get; set; }
        public string Status { get; set; } = string.Empty;
        public string PhotoUrl { get; set; } = "images/default-avatar.png"; // Never null - defaults to avatar
        public List<RoleResponse> Roles { get; set; } = new List<RoleResponse>();
    }
}

