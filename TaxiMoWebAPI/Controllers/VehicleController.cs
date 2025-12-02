using AutoMapper;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TaxiMo.Services.Database.Entities;
using TaxiMo.Services.DTOs;
using TaxiMo.Services.Interfaces;

namespace TaxiMoWebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize(Roles = "Admin,Driver")]
    public class VehicleController : ControllerBase
    {
        private readonly IVehicleService _vehicleService;
        private readonly IMapper _mapper;
        private readonly ILogger<VehicleController> _logger;

        public VehicleController(IVehicleService vehicleService, IMapper mapper, ILogger<VehicleController> logger)
        {
            _vehicleService = vehicleService;
            _mapper = mapper;
            _logger = logger;
        }

        // GET: api/Vehicle
        [HttpGet]
        public async Task<ActionResult<IEnumerable<VehicleDto>>> GetVehicles()
        {
            try
            {
                var vehicles = await _vehicleService.GetAllAsync();
                var vehicleDtos = _mapper.Map<List<VehicleDto>>(vehicles);
                return Ok(vehicleDtos);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving vehicles");
                return StatusCode(500, new { message = "An error occurred while retrieving vehicles" });
            }
        }

        // GET: api/Vehicle/{id}
        [HttpGet("{id}")]
        public async Task<ActionResult<VehicleDto>> GetVehicle(int id)
        {
            try
            {
                var vehicle = await _vehicleService.GetByIdAsync(id);

                if (vehicle == null)
                {
                    return NotFound(new { message = $"Vehicle with ID {id} not found" });
                }

                var vehicleDto = _mapper.Map<VehicleDto>(vehicle);
                return Ok(vehicleDto);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving vehicle with ID {VehicleId}", id);
                return StatusCode(500, new { message = "An error occurred while retrieving the vehicle" });
            }
        }

        // POST: api/Vehicle
        [HttpPost]
        public async Task<ActionResult<VehicleDto>> CreateVehicle(VehicleCreateDto vehicleCreateDto)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    return BadRequest(ModelState);
                }

                var vehicle = _mapper.Map<Vehicle>(vehicleCreateDto);
                var createdVehicle = await _vehicleService.CreateAsync(vehicle);
                var vehicleDto = _mapper.Map<VehicleDto>(createdVehicle);

                return CreatedAtAction(nameof(GetVehicle), new { id = vehicleDto.VehicleId }, vehicleDto);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating vehicle");
                return StatusCode(500, new { message = "An error occurred while creating the vehicle" });
            }
        }

        // PUT: api/Vehicle/{id}
        [HttpPut("{id}")]
        public async Task<ActionResult<VehicleDto>> UpdateVehicle(int id, VehicleUpdateDto vehicleUpdateDto)
        {
            try
            {
                if (id != vehicleUpdateDto.VehicleId)
                {
                    return BadRequest(new { message = "Vehicle ID mismatch" });
                }

                if (!ModelState.IsValid)
                {
                    return BadRequest(ModelState);
                }

                try
                {
                    var vehicle = _mapper.Map<Vehicle>(vehicleUpdateDto);
                    var updatedVehicle = await _vehicleService.UpdateAsync(vehicle);
                    var vehicleDto = _mapper.Map<VehicleDto>(updatedVehicle);
                    return Ok(vehicleDto);
                }
                catch (KeyNotFoundException)
                {
                    return NotFound(new { message = $"Vehicle with ID {id} not found" });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating vehicle with ID {VehicleId}", id);
                return StatusCode(500, new { message = "An error occurred while updating the vehicle" });
            }
        }

        // DELETE: api/Vehicle/{id}
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteVehicle(int id)
        {
            try
            {
                var deleted = await _vehicleService.DeleteAsync(id);
                if (!deleted)
                {
                    return NotFound(new { message = $"Vehicle with ID {id} not found" });
                }

                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting vehicle with ID {VehicleId}", id);
                return StatusCode(500, new { message = "An error occurred while deleting the vehicle" });
            }
        }
    }
}

