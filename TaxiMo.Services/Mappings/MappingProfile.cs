using AutoMapper;
using TaxiMo.Services.Database.Entities;
using TaxiMo.Services.DTOs;

namespace TaxiMo.Services.Mappings
{
    public class MappingProfile : Profile
    {
        public MappingProfile()
        {
            // User mappings
            CreateMap<User, UserDto>();
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
            CreateMap<Driver, DriverDto>();
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
            CreateMap<RideCreateDto, Ride>()
                .ForMember(dest => dest.RideId, opt => opt.Ignore())
                .ForMember(dest => dest.StartedAt, opt => opt.Ignore())
                .ForMember(dest => dest.CompletedAt, opt => opt.Ignore())
                .ForMember(dest => dest.FareEstimate, opt => opt.Ignore())
                .ForMember(dest => dest.FareFinal, opt => opt.Ignore())
                .ForMember(dest => dest.DistanceKm, opt => opt.Ignore())
                .ForMember(dest => dest.DurationMin, opt => opt.Ignore());
            CreateMap<RideUpdateDto, Ride>();

            // Review mappings
            CreateMap<Review, ReviewDto>();
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

