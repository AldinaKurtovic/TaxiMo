using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TaxiMo.Services.Database.Entities;
using TaxiMo.Services.DTOs;
using TaxiMo.Services.Interfaces;

namespace TaxiMoWebAPI.Controllers
{
    [Authorize(Roles = "User,Admin")]
    public class UserNotificationController : BaseCRUDController<UserNotification, UserNotificationDto, UserNotificationCreateDto, UserNotificationUpdateDto>
    {
        protected override string EntityName => "UserNotification";

        public UserNotificationController(
            IUserNotificationService userNotificationService,
            AutoMapper.IMapper mapper,
            ILogger<UserNotificationController> logger) 
            : base(userNotificationService, mapper, logger)
        {
        }
    }
}

