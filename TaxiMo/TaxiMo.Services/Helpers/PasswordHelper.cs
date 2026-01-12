using System.Security.Cryptography;
using System.Text;

namespace TaxiMo.Services.Helpers
{
    public static class PasswordHelper
    {
        private const int SaltSize = 16; // 128 bits
        private const int HashSize = 32; // 256 bits
        private const int Iterations = 10000; // PBKDF2 iterations

        /// <summary>
        /// Generates a random salt and returns it as a base64 string
        /// </summary>
        public static string GenerateSalt()
        {
            using var rng = RandomNumberGenerator.Create();
            var saltBytes = new byte[SaltSize];
            rng.GetBytes(saltBytes);
            return Convert.ToBase64String(saltBytes);
        }

        /// <summary>
        /// Hashes a password using PBKDF2 with the provided salt
        /// </summary>
        public static string HashPassword(string password, string salt)
        {
            if (string.IsNullOrWhiteSpace(password))
                throw new ArgumentException("Password cannot be null or empty.", nameof(password));
            if (string.IsNullOrWhiteSpace(salt))
                throw new ArgumentException("Salt cannot be null or empty.", nameof(salt));

            var saltBytes = Convert.FromBase64String(salt);
            var passwordBytes = Encoding.UTF8.GetBytes(password);

            using var pbkdf2 = new Rfc2898DeriveBytes(passwordBytes, saltBytes, Iterations, HashAlgorithmName.SHA256);
            var hashBytes = pbkdf2.GetBytes(HashSize);
            return Convert.ToBase64String(hashBytes);
        }

        /// <summary>
        /// Creates a password hash and salt from a password
        /// </summary>
        public static void CreatePasswordHash(string password, out string hash, out string salt)
        {
            if (string.IsNullOrWhiteSpace(password))
                throw new ArgumentException("Password cannot be null or empty.", nameof(password));

            salt = GenerateSalt();
            hash = HashPassword(password, salt);
        }

        /// <summary>
        /// Verifies a password against a stored hash and salt
        /// </summary>
        public static bool VerifyPassword(string password, string hash, string salt)
        {
            if (string.IsNullOrWhiteSpace(password) || string.IsNullOrWhiteSpace(hash) || string.IsNullOrWhiteSpace(salt))
                return false;

            try
            {
                var computedHash = HashPassword(password, salt);
                return computedHash == hash;
            }
            catch
            {
                return false;
            }
        }
    }
}

