using System.ComponentModel.DataAnnotations;

namespace TaxiMo.Services.DTOs
{
    public class AssignDriverDto
    {
        [Required(ErrorMessage = "Driver ID is required.")]
        public int DriverId { get; set; }
    }
}

