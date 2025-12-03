using AutoMapper;
using Microsoft.AspNetCore.Mvc;

namespace TaxiMoWebAPI.Controllers
{
    [ApiController]
    public abstract class BaseController : ControllerBase
    {
        protected readonly IMapper Mapper;
        protected readonly ILogger Logger;

        protected BaseController(IMapper mapper, ILogger logger)
        {
            Mapper = mapper;
            Logger = logger;
        }
    }
}

