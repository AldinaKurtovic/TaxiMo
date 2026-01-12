using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace TaxiMo.Services.Database.Entities
{
    [Table("DriverRoles")]
    public class DriverRole
    {
        [Key]
        public int DriverRoleId { get; set; }

        [Required]
        public int DriverId { get; set; }

        [Required]
        public int RoleId { get; set; }

        [Required]
        public DateTime DateAssigned { get; set; }

        // Navigation properties
        [ForeignKey("DriverId")]
        public virtual Driver Driver { get; set; } = null!;

        [ForeignKey("RoleId")]
        public virtual Role Role { get; set; } = null!;
    }
}

