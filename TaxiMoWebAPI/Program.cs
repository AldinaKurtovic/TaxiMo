using System.Reflection;
using Microsoft.AspNetCore.Authentication;
using Microsoft.EntityFrameworkCore;
using Microsoft.OpenApi.Models;
using TaxiMo.Services.Database;
using TaxiMo.Services.Interfaces;
using TaxiMo.Services.Mappings;
using TaxiMo.Services.Services;
using TaxiMoWebAPI.Filters;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.

builder.Services.AddControllers();
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo { Title = "TaxiMo API", Version = "v1" });

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

var app = builder.Build();

// Ensure database is created and seed roles/users
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<TaxiMoDbContext>();
    db.Database.EnsureCreated();

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
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

app.UseRouting();

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.Run();