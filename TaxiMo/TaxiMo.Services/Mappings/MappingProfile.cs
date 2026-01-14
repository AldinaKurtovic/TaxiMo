using AutoMapper;
using TaxiMo.Model.Responses;
using TaxiMo.Services.Database.Entities;
using TaxiMo.Services.DTOs;

namespace TaxiMo.Services.Mappings
{
    public class MappingProfile : Profile
    {
        public MappingProfile()
        {
            // User mappings
            CreateMap<User, UserDto>()
                .ForMember(dest => dest.PhotoUrl, opt => opt.MapFrom(src => src.PhotoUrl ?? "images/default-avatar.png"))
                .AfterMap((src, dest) =>
                {
                    // Ensure PhotoUrl is never null or empty
                    if (string.IsNullOrEmpty(dest.PhotoUrl))
                    {
                        dest.PhotoUrl = "images/default-avatar.png";
                    }
                });
            CreateMap<UserCreateDto, User>()
                .ForMember(dest => dest.UserId, opt => opt.Ignore())
                .ForMember(dest => dest.PasswordHash, opt => opt.Ignore())
                .ForMember(dest => dest.CreatedAt, opt => opt.Ignore())
                .ForMember(dest => dest.UpdatedAt, opt => opt.Ignore());
            CreateMap<UserUpdateDto, User>()
                .ForMember(dest => dest.PasswordHash, opt => opt.Ignore())
                .ForMember(dest => dest.CreatedAt, opt => opt.Ignore())
                .ForMember(dest => dest.UpdatedAt, opt => opt.Ignore());

            // Driver mappings
            CreateMap<Driver, DriverDto>()
                .AfterMap((src, dest) =>
                {
                    if (src.DriverAvailabilities != null && src.DriverAvailabilities.Any())
                    {
                        var latestAvailability = src.DriverAvailabilities
                            .OrderByDescending(da => da.LastLocationUpdate ?? da.UpdatedAt)
                            .FirstOrDefault();
                        
                        if (latestAvailability != null)
                        {
                            dest.CurrentLatitude = latestAvailability.CurrentLat.HasValue 
                                ? (double?)latestAvailability.CurrentLat.Value 
                                : null;
                            dest.CurrentLongitude = latestAvailability.CurrentLng.HasValue 
                                ? (double?)latestAvailability.CurrentLng.Value 
                                : null;
                        }
                    }
                    
                    // Set VehicleId from first vehicle
                    if (src.Vehicles != null && src.Vehicles.Any())
                    {
                        var firstVehicle = src.Vehicles.FirstOrDefault();
                        if (firstVehicle != null)
                        {
                            dest.VehicleId = firstVehicle.VehicleId;
                        }
                    }
                    
                    // Set default avatar if PhotoUrl is null or empty
                    if (string.IsNullOrWhiteSpace(dest.PhotoUrl))
                    {
                        dest.PhotoUrl = "images/default-avatar.png";
                    }
                });
            CreateMap<DriverCreateDto, Driver>()
                .ForMember(dest => dest.DriverId, opt => opt.Ignore())
                .ForMember(dest => dest.PasswordHash, opt => opt.Ignore())
                .ForMember(dest => dest.RatingAvg, opt => opt.Ignore())
                .ForMember(dest => dest.TotalRides, opt => opt.Ignore())
                .ForMember(dest => dest.CreatedAt, opt => opt.Ignore())
                .ForMember(dest => dest.UpdatedAt, opt => opt.Ignore());
            CreateMap<DriverUpdateDto, Driver>()
                .ForMember(dest => dest.PasswordHash, opt => opt.Ignore())
                .ForMember(dest => dest.RatingAvg, opt => opt.Ignore())
                .ForMember(dest => dest.TotalRides, opt => opt.Ignore())
                .ForMember(dest => dest.CreatedAt, opt => opt.Ignore())
                .ForMember(dest => dest.UpdatedAt, opt => opt.Ignore());

            // Vehicle mappings
            CreateMap<Vehicle, VehicleDto>();
            CreateMap<VehicleCreateDto, Vehicle>()
                .ForMember(dest => dest.VehicleId, opt => opt.Ignore())
                .ForMember(dest => dest.CreatedAt, opt => opt.Ignore())
                .ForMember(dest => dest.UpdatedAt, opt => opt.Ignore());
            CreateMap<VehicleUpdateDto, Vehicle>()
                .ForMember(dest => dest.CreatedAt, opt => opt.Ignore())
                .ForMember(dest => dest.UpdatedAt, opt => opt.Ignore());

            // Ride mappings
            CreateMap<Ride, RideDto>();
            CreateMap<Ride, RideResponse>()
                .AfterMap((src, dest) =>
                {
                    if (src.Driver != null && src.Driver.DriverAvailabilities != null && src.Driver.DriverAvailabilities.Any())
                    {
                        var latestAvailability = src.Driver.DriverAvailabilities
                            .OrderByDescending(da => da.LastLocationUpdate ?? da.UpdatedAt)
                            .FirstOrDefault();
                        
                        if (latestAvailability != null)
                        {
                            dest.DriverLatitude = latestAvailability.CurrentLat.HasValue 
                                ? (double?)latestAvailability.CurrentLat.Value 
                                : null;
                            dest.DriverLongitude = latestAvailability.CurrentLng.HasValue 
                                ? (double?)latestAvailability.CurrentLng.Value 
                                : null;
                        }
                    }
                });
            CreateMap<RideCreateDto, Ride>()
                .ForMember(dest => dest.RideId, opt => opt.Ignore())
                .ForMember(dest => dest.StartedAt, opt => opt.Ignore())
                .ForMember(dest => dest.CompletedAt, opt => opt.Ignore())
                .ForMember(dest => dest.FareEstimate, opt => opt.Ignore())
                .ForMember(dest => dest.FareFinal, opt => opt.Ignore())
                .ForMember(dest => dest.DistanceKm, opt => opt.MapFrom(src => src.DistanceKm.HasValue ? (decimal?)src.DistanceKm.Value : null))
                .ForMember(dest => dest.DurationMin, opt => opt.MapFrom(src => src.DurationMin));
            CreateMap<RideUpdateDto, Ride>();

            // Review mappings
            CreateMap<Review, ReviewDto>()
                .ForMember(dest => dest.UserName,
                    opt => opt.MapFrom(src =>
                        src.Rider != null ? src.Rider.FirstName + " " + src.Rider.LastName : null))
                .ForMember(dest => dest.UserPhotoUrl,
                    opt => opt.MapFrom(src => 
                        src.Rider != null
                            ? (string.IsNullOrWhiteSpace(src.Rider.PhotoUrl) 
                                ? "images/default-avatar.png" 
                                : src.Rider.PhotoUrl)
                            : null))
                .ForMember(dest => dest.UserFirstName,
                    opt => opt.MapFrom(src => src.Rider != null ? src.Rider.FirstName : null))
                .ForMember(dest => dest.DriverName,
                    opt => opt.MapFrom(src =>
                        src.Driver != null ? src.Driver.FirstName + " " + src.Driver.LastName : null))
                .ForMember(dest => dest.DriverPhotoUrl,
                    opt => opt.MapFrom(src => 
                        src.Driver != null
                            ? (string.IsNullOrWhiteSpace(src.Driver.PhotoUrl) 
                                ? "images/default-avatar.png" 
                                : src.Driver.PhotoUrl)
                            : null))
                .ForMember(dest => dest.DriverFirstName,
                    opt => opt.MapFrom(src => src.Driver != null ? src.Driver.FirstName : null));
            CreateMap<Review, ReviewResponse>()
                .ForMember(dest => dest.UserId,
                    opt => opt.MapFrom(src => src.RiderId))
                .ForMember(dest => dest.UserName,
                    opt => opt.MapFrom(src =>
                        src.Rider.FirstName + " " + src.Rider.LastName))
                .ForMember(dest => dest.UserPhotoUrl,
                    opt => opt.MapFrom(src => 
                        string.IsNullOrWhiteSpace(src.Rider.PhotoUrl) 
                            ? "images/default-avatar.png" 
                            : src.Rider.PhotoUrl))
                .ForMember(dest => dest.UserFirstName,
                    opt => opt.MapFrom(src => src.Rider.FirstName))
                .ForMember(dest => dest.DriverName,
                    opt => opt.MapFrom(src =>
                        src.Driver.FirstName + " " + src.Driver.LastName))
                .ForMember(dest => dest.DriverPhotoUrl,
                    opt => opt.MapFrom(src => 
                        string.IsNullOrWhiteSpace(src.Driver.PhotoUrl) 
                            ? "images/default-avatar.png" 
                            : src.Driver.PhotoUrl))
                .ForMember(dest => dest.DriverFirstName,
                    opt => opt.MapFrom(src => src.Driver.FirstName))
                .ForMember(dest => dest.Description,
                    opt => opt.MapFrom(src => src.Comment));
            CreateMap<ReviewCreateDto, Review>()
                .ForMember(dest => dest.ReviewId, opt => opt.Ignore())
                .ForMember(dest => dest.CreatedAt, opt => opt.Ignore());
            CreateMap<ReviewUpdateDto, Review>()
                .ForMember(dest => dest.CreatedAt, opt => opt.Ignore());

            // PromoUsage mappings
            CreateMap<PromoUsage, PromoUsageDto>();
            CreateMap<PromoUsageCreateDto, PromoUsage>()
                .ForMember(dest => dest.PromoUsageId, opt => opt.Ignore());
            CreateMap<PromoUsageUpdateDto, PromoUsage>();

            // Location mappings
            CreateMap<Location, LocationDto>();
            CreateMap<LocationCreateDto, Location>()
                .ForMember(dest => dest.LocationId, opt => opt.Ignore())
                .ForMember(dest => dest.CreatedAt, opt => opt.Ignore())
                .ForMember(dest => dest.UpdatedAt, opt => opt.Ignore());
            CreateMap<LocationUpdateDto, Location>()
                .ForMember(dest => dest.CreatedAt, opt => opt.Ignore())
                .ForMember(dest => dest.UpdatedAt, opt => opt.Ignore());

            // UserNotification mappings
            CreateMap<UserNotification, UserNotificationDto>();
            CreateMap<UserNotificationCreateDto, UserNotification>()
                .ForMember(dest => dest.NotificationId, opt => opt.Ignore());
            CreateMap<UserNotificationUpdateDto, UserNotification>();

            // PromoCode mappings
            CreateMap<PromoCode, PromoCodeDto>();
            CreateMap<PromoCodeCreateDto, PromoCode>()
                .ForMember(dest => dest.PromoId, opt => opt.Ignore())
                .ForMember(dest => dest.CreatedAt, opt => opt.Ignore());
            CreateMap<PromoCodeUpdateDto, PromoCode>()
                .ForMember(dest => dest.CreatedAt, opt => opt.Ignore());

            // DriverAvailability mappings
            CreateMap<DriverAvailability, DriverAvailabilityDto>();
            CreateMap<DriverAvailabilityCreateDto, DriverAvailability>()
                .ForMember(dest => dest.AvailabilityId, opt => opt.Ignore())
                .ForMember(dest => dest.UpdatedAt, opt => opt.Ignore());
            CreateMap<DriverAvailabilityUpdateDto, DriverAvailability>()
                .ForMember(dest => dest.UpdatedAt, opt => opt.Ignore());

            // DriverNotification mappings
            CreateMap<DriverNotification, DriverNotificationDto>();
            CreateMap<DriverNotificationCreateDto, DriverNotification>()
                .ForMember(dest => dest.NotificationId, opt => opt.Ignore());
            CreateMap<DriverNotificationUpdateDto, DriverNotification>();

            // Payment mappings
            CreateMap<Payment, PaymentDto>();
            CreateMap<PaymentCreateDto, Payment>()
                .ForMember(dest => dest.PaymentId, opt => opt.Ignore());
            CreateMap<PaymentUpdateDto, Payment>();
        }
    }
}

