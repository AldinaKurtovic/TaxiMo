namespace TaxiMo.Services.DTOs.Auth
{
    public class RoleResponse
    {
        public int RoleId { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
    }
}

