using TaxiMo.Services.Database.Entities;

namespace TaxiMo.Services.Interfaces
{
    public interface IRideService : IBaseCRUDService<Ride>
    {
        Task<List<Ride>> GetAllAsync(string? search = null, string? status = null);
        Task<(Ride Ride, Payment Payment)> CreateRideWithPaymentAsync(Ride ride, string paymentMethod);
        Task<Ride> AcceptRideAsync(int rideId, int driverId);
        Task<Ride> RejectRideAsync(int rideId, int driverId);
        Task<Ride> StartRideAsync(int rideId);
        Task<Ride> CompleteRideAsync(int rideId);
        Task<Ride> CancelRideAsync(int rideId, bool isAdmin);
        Task<Ride> AssignDriverAsync(int rideId, int driverId);
    }
}

