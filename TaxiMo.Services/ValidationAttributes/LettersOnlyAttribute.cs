using System.ComponentModel.DataAnnotations;
using System.Text.RegularExpressions;

namespace TaxiMo.Services.ValidationAttributes
{
    /// <summary>
    /// Validates that a string contains only letters (including spaces, hyphens, and apostrophes for names)
    /// </summary>
    public class LettersOnlyAttribute : ValidationAttribute
    {
        private static readonly Regex LettersRegex = new Regex(@"^[a-zA-Z\s\-']+$", RegexOptions.Compiled);

        public LettersOnlyAttribute()
        {
            ErrorMessage = "Name must contain only letters.";
        }

        public override bool IsValid(object? value)
        {
            // Allow null values (for optional fields in update DTOs)
            if (value == null)
            {
                return true;
            }

            if (value is not string name)
            {
                return false;
            }

            // Allow empty strings (for optional fields)
            if (string.IsNullOrWhiteSpace(name))
            {
                return true;
            }

            return LettersRegex.IsMatch(name);
        }
    }
}

