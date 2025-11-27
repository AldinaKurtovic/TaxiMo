using System.ComponentModel.DataAnnotations;

namespace TaxiMo.Services.ValidationAttributes
{
    /// <summary>
    /// Validates that a date of birth is not in the future
    /// </summary>
    public class DateOfBirthNotInFutureAttribute : ValidationAttribute
    {
        public DateOfBirthNotInFutureAttribute()
        {
            ErrorMessage = "Date of birth cannot be in the future.";
        }

        public override bool IsValid(object? value)
        {
            if (value == null)
            {
                return true; // Allow null values (optional field)
            }

            if (value is not DateTime dateOfBirth)
            {
                return false;
            }

            return dateOfBirth <= DateTime.UtcNow;
        }
    }
}

