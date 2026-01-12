using System.Reflection;
using Microsoft.AspNetCore.Authentication;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.OpenApi.Models;
using TaxiMo.Services.Database;
using TaxiMo.Services.Interfaces;
using TaxiMo.Services.Mappings;
using TaxiMo.Services.Services;
using TaxiMo.Services.Services.RideStateMachine;
using TaxiMoWebAPI.Filters;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.

builder.Services.AddControllers(options =>
{
    options.Filters.Add<ExceptionFilter>();
});
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo { Title = "TaxiMo API", Version = "v1" });

    // Resolve conflicting actions (prefer derived class methods over base class)
    c.ResolveConflictingActions(apiDescriptions =>
    {
        // Prefer the action from the derived class over the base class
        var descriptions = apiDescriptions.ToList();
        
        // Find action from derived class (not BaseCRUDController)
        var derivedClassAction = descriptions.FirstOrDefault(d =>
        {
            var actionDescriptor = d.ActionDescriptor as Microsoft.AspNetCore.Mvc.Controllers.ControllerActionDescriptor;
            if (actionDescriptor != null)
            {
                var declaringType = actionDescriptor.MethodInfo.DeclaringType;
                return declaringType != null && 
                       !declaringType.Name.Contains("BaseCRUDController") &&
                       !declaringType.Name.Contains("BaseController");
            }
            return false;
        });
        
        return derivedClassAction ?? descriptions.First();
    });

    // Add Basic Authentication to Swagger
    c.AddSecurityDefinition("BasicAuthentication", new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = SecuritySchemeType.Http,
        Scheme = "basic",
        In = ParameterLocation.Header,
        Description = "Basic Authorization header (Basic base64(username:password))."
    });

    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "BasicAuthentication"
                }
            },
            Array.Empty<string>()
        }
    });
});

// Register DbContext
builder.Services.AddDbContext<TaxiMoDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

// Register AutoMapper
var assembly = Assembly.GetAssembly(typeof(MappingProfile));
if (assembly != null)
{
    builder.Services.AddAutoMapper(typeof(MappingProfile));

}

// Register Authentication
builder.Services.AddAuthentication("BasicAuthentication")
    .AddScheme<AuthenticationSchemeOptions, BasicAuthenticationHandler>("BasicAuthentication", null);

// Register Authorization
builder.Services.AddAuthorization();

// Register Services
builder.Services.AddScoped<IUserService, UserService>();
builder.Services.AddScoped<IDriverService, DriverService>();
builder.Services.AddScoped<IRidePriceCalculator, RidePriceCalculator>();
builder.Services.AddScoped<IRideService, RideService>();
builder.Services.AddScoped<ILocationService, LocationService>();
builder.Services.AddScoped<IPaymentService, PaymentService>();
builder.Services.AddScoped<IReviewService, ReviewService>();
builder.Services.AddScoped<IVehicleService, VehicleService>();
builder.Services.AddScoped<IPromoCodeService, PromoCodeService>();
builder.Services.AddScoped<IDriverNotificationService, DriverNotificationService>();
builder.Services.AddScoped<IDriverAvailabilityService, DriverAvailabilityService>();
builder.Services.AddScoped<IUserNotificationService, UserNotificationService>();
builder.Services.AddScoped<IPromoUsageService, PromoUsageService>();
builder.Services.AddScoped<IRoleService, RoleService>();
builder.Services.AddScoped<IStatisticsService, StatisticsService>();
builder.Services.AddScoped<TaxiMo.Services.Interfaces.IDriverRecommendationService, TaxiMo.Services.Services.DriverRecommendationService>();
builder.Services.AddScoped<TaxiMo.Services.Interfaces.IStripeService, TaxiMo.Services.Services.StripeService>();

// Register ExceptionFilter for dependency injection
builder.Services.AddTransient<ExceptionFilter>();

// Register Ride State Machine states

builder.Services.AddTransient<InitialRideState>();
builder.Services.AddTransient<RequestedRideState>();
builder.Services.AddTransient<AcceptedRideState>();
builder.Services.AddTransient<ActiveRideState>();
builder.Services.AddTransient<CompletedRideState>();
builder.Services.AddTransient<CancelledRideState>();
builder.Services.AddTransient<RideStateFactory>();

var app = builder.Build();

// Ensure required directories exist
var wwwrootPath = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot");
var driversPath = Path.Combine(wwwrootPath, "drivers");
var usersPath = Path.Combine(wwwrootPath, "users");
var imagesPath = Path.Combine(wwwrootPath, "images");

if (!Directory.Exists(wwwrootPath))
{
    Directory.CreateDirectory(wwwrootPath);
    Console.WriteLine($"Created wwwroot directory at {wwwrootPath}");
}

if (!Directory.Exists(driversPath))
{
    Directory.CreateDirectory(driversPath);
    Console.WriteLine($"Created drivers directory at {driversPath}");
}

if (!Directory.Exists(usersPath))
{
    Directory.CreateDirectory(usersPath);
    Console.WriteLine($"Created users directory at {usersPath}");
}

if (!Directory.Exists(imagesPath))
{
    Directory.CreateDirectory(imagesPath);
    Console.WriteLine($"Created images directory at {imagesPath}");
}

// Ensure database is created and migrations are applied
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<TaxiMoDbContext>();
    
    // Apply pending migrations (this will create the database if it doesn't exist)
    try
    {
        await db.Database.MigrateAsync();
        Console.WriteLine("Database migrations applied successfully.");
    }
    catch (Exception ex)
    {
        Console.WriteLine($"Error applying migrations: {ex.Message}");
        throw;
    }

    // Ensure PhotoUrl column exists in Drivers table (fix for databases created with EnsureCreated)
    try
    {
        await db.Database.ExecuteSqlRawAsync(@"
            IF NOT EXISTS (
                SELECT 1 FROM sys.columns 
                WHERE object_id = OBJECT_ID(N'[Drivers]') 
                AND name = 'PhotoUrl'
            )
            BEGIN
                ALTER TABLE [Drivers] ADD [PhotoUrl] nvarchar(255) NULL;
            END");
        Console.WriteLine("Verified PhotoUrl column exists in Drivers table.");
    }
    catch (Exception ex)
    {
        Console.WriteLine($"Warning: Could not verify PhotoUrl column in Drivers table: {ex.Message}");
        // Don't throw - this is a best-effort fix
    }

    // Ensure PhotoUrl column exists in Users table (fix for databases created with EnsureCreated)
    try
    {
        await db.Database.ExecuteSqlRawAsync(@"
            IF NOT EXISTS (
                SELECT 1 FROM sys.columns 
                WHERE object_id = OBJECT_ID(N'[Users]') 
                AND name = 'PhotoUrl'
            )
            BEGIN
                ALTER TABLE [Users] ADD [PhotoUrl] nvarchar(255) NULL;
            END");
        Console.WriteLine("Verified PhotoUrl column exists in Users table.");
    }
    catch (Exception ex)
    {
        Console.WriteLine($"Warning: Could not verify PhotoUrl column in Users table: {ex.Message}");
        // Don't throw - this is a best-effort fix
    }

    // Seed data
    await DataSeed.SeedAsync(scope.ServiceProvider);

    // Optional: Fix existing users without roles (uncomment to enable automatic fixing on startup)
    // var userService = scope.ServiceProvider.GetRequiredService<IUserService>();
    // var fixedCount = await userService.FixUsersWithoutRolesAsync();
    // if (fixedCount > 0)
    // {
    //     Console.WriteLine($"DataSeed: Fixed {fixedCount} user(s) without roles.");
    // }
}

// Configure the HTTP request pipeline.
// if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

// Enable static file serving for wwwroot
app.UseStaticFiles();

app.UseRouting();

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.Run();