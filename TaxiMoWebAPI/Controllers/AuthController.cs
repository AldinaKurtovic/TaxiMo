using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TaxiMo.Services.DTOs.Auth;
using TaxiMo.Services.Interfaces;

namespace TaxiMoWebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly IUserService _userService;
        private readonly IDriverService _driverService;
        private readonly ILogger<AuthController> _logger;

        public AuthController(
            IUserService userService,
            IDriverService driverService,
            ILogger<AuthController> logger)
        {
            _userService = userService;
            _driverService = driverService;
            _logger = logger;
        }

        // USER LOGIN
        [AllowAnonymous]
        [HttpPost("User/Login")]
        public async Task<ActionResult<UserResponse>> UserLogin(UserLoginRequest request)
        {
            try
            {
                var user = await _userService.AuthenticateAsync(request);
                if (user == null)
                {
                    _logger.LogWarning("User login failed for username: {Username}", request.Username);
                    return Unauthorized(new { message = "Invalid username or password" });
                }

                _logger.LogInformation("User login successful. UserId: {UserId}, Username: {Username}", user.UserId, user.Username);
                return Ok(user);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error during user login for username: {Username}", request.Username);
                return StatusCode(500, new { message = "An error occurred during login" });
            }
        }

        // DRIVER LOGIN
        [AllowAnonymous]
        [HttpPost("Driver/Login")]
        public async Task<ActionResult<DriverResponse>> DriverLogin(DriverLoginRequest request)
        {
            try
            {
                var driver = await _driverService.AuthenticateAsync(request);
                if (driver == null)
                {
                    _logger.LogWarning("Driver login failed for username: {Username}", request.Username);
                    return Unauthorized(new { message = "Invalid username or password" });
                }

                _logger.LogInformation("Driver login successful. DriverId: {DriverId}, Username: {Username}", driver.DriverId, driver.Username);
                return Ok(driver);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error during driver login for username: {Username}", request.Username);
                return StatusCode(500, new { message = "An error occurred during login" });
            }
        }
    }
}

