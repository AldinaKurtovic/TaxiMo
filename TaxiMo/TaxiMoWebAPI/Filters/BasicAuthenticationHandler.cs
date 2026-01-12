using Microsoft.AspNetCore.Authentication;
using Microsoft.Extensions.Options;
using System.Net.Http.Headers;
using System.Security.Claims;
using System.Text;
using System.Text.Encodings.Web;
using TaxiMo.Services.DTOs.Auth;
using TaxiMo.Services.Interfaces;

namespace TaxiMoWebAPI.Filters
{
    public class BasicAuthenticationHandler : AuthenticationHandler<AuthenticationSchemeOptions>
    {
        private readonly IUserService _userService;
        private readonly IDriverService _driverService;

        public BasicAuthenticationHandler(
            IOptionsMonitor<AuthenticationSchemeOptions> options,
            ILoggerFactory logger,
            UrlEncoder encoder,
            IUserService userService,
            IDriverService driverService)
            : base(options, logger, encoder)
        {
            _userService = userService;
            _driverService = driverService;
        }

        protected override async Task<AuthenticateResult> HandleAuthenticateAsync()
        {
            if (!Request.Headers.ContainsKey("Authorization"))
            {
                return AuthenticateResult.NoResult();
            }

            if (!AuthenticationHeaderValue.TryParse(Request.Headers["Authorization"], out AuthenticationHeaderValue? authHeader))
            {
                return AuthenticateResult.Fail("Invalid Authorization header");
            }

            if (authHeader.Scheme != "Basic")
            {
                return AuthenticateResult.NoResult();
            }

            try
            {
                var credentialBytes = Convert.FromBase64String(authHeader.Parameter ?? string.Empty);
                var credentials = Encoding.UTF8.GetString(credentialBytes).Split(':', 2);
                
                if (credentials.Length != 2)
                {
                    return AuthenticateResult.Fail("Invalid credentials format");
                }

                var username = credentials[0];
                var password = credentials[1];

                // Try to authenticate as user first
                var loginRequest = new UserLoginRequest { Username = username, Password = password };
                var userResponse = await _userService.AuthenticateAsync(loginRequest);

                if (userResponse != null)
                {
                    var claims = new List<Claim>
                    {
                        new Claim(ClaimTypes.NameIdentifier, userResponse.UserId.ToString()),
                        new Claim(ClaimTypes.Name, userResponse.Username),
                        new Claim(ClaimTypes.Email, userResponse.Email)
                    };

                    // Add role claims
                    foreach (var role in userResponse.Roles)
                    {
                        claims.Add(new Claim(ClaimTypes.Role, role.Name));
                    }

                    var identity = new ClaimsIdentity(claims, Scheme.Name);
                    var principal = new ClaimsPrincipal(identity);
                    var ticket = new AuthenticationTicket(principal, Scheme.Name);

                    return AuthenticateResult.Success(ticket);
                }

                // If user authentication fails, try driver authentication
                var driverLoginRequest = new DriverLoginRequest { Username = username, Password = password };
                var driverResponse = await _driverService.AuthenticateAsync(driverLoginRequest);

                if (driverResponse != null)
                {
                    var claims = new List<Claim>
                    {
                        new Claim(ClaimTypes.NameIdentifier, driverResponse.DriverId.ToString()),
                        new Claim(ClaimTypes.Name, driverResponse.Username),
                        new Claim(ClaimTypes.Email, driverResponse.Email)
                    };

                    // Add role claims
                    foreach (var role in driverResponse.Roles)
                    {
                        claims.Add(new Claim(ClaimTypes.Role, role.Name));
                    }

                    var identity = new ClaimsIdentity(claims, Scheme.Name);
                    var principal = new ClaimsPrincipal(identity);
                    var ticket = new AuthenticationTicket(principal, Scheme.Name);

                    return AuthenticateResult.Success(ticket);
                }

                return AuthenticateResult.Fail("Invalid username or password");
            }
            catch (Exception ex)
            {
                Logger.LogError(ex, "Error during authentication");
                return AuthenticateResult.Fail("Authentication error");
            }
        }
    }
}

