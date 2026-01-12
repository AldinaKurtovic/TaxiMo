using TaxiMo.Services.Database.Entities;

namespace TaxiMo.Services.Interfaces
{
    public interface ILocationService : IBaseCRUDService<Location>
    {
        /// <summary>
        /// Gets an existing location by latitude and longitude, or creates a new one if it doesn't exist.
        /// Prevents duplicate locations in the database.
        /// </summary>
        /// <param name="lat">Latitude of the location</param>
        /// <param name="lng">Longitude of the location</param>
        /// <param name="name">Name of the location</param>
        /// <param name="addressLine">Address line (optional)</param>
        /// <param name="city">City (optional)</param>
        /// <param name="userId">User ID (optional)</param>
        /// <returns>The existing or newly created location</returns>
        Task<Location> GetOrCreateLocationAsync(decimal lat, decimal lng, string name, string? addressLine = null, string? city = null, int? userId = null);
    }
}

