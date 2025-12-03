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

        public VehicleController(IVehicleService vehicleService, IMapper mapper)
        {
            _vehicleService = vehicleService;
            _mapper = mapper;
        }

        // GET: api/Vehicle
        [HttpGet]
        public async Task<ActionResult<IEnumerable<VehicleDto>>> GetVehicles()
        {
            var vehicles = await _vehicleService.GetAllAsync();
            var vehicleDtos = _mapper.Map<List<VehicleDto>>(vehicles);
            return Ok(vehicleDtos);
        }

        // GET: api/Vehicle/{id}
        [HttpGet("{id}")]
        public async Task<ActionResult<VehicleDto>> GetVehicle(int id)
        {
            var vehicle = await _vehicleService.GetByIdAsync(id);

            if (vehicle == null)
            {
                return NotFound(new { message = $"Vehicle with ID {id} not found" });
            }

            var vehicleDto = _mapper.Map<VehicleDto>(vehicle);
            return Ok(vehicleDto);
        }

        // POST: api/Vehicle
        [HttpPost]
        public async Task<ActionResult<VehicleDto>> CreateVehicle(VehicleCreateDto vehicleCreateDto)
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

        // PUT: api/Vehicle/{id}
        [HttpPut("{id}")]
        public async Task<ActionResult<VehicleDto>> UpdateVehicle(int id, VehicleUpdateDto vehicleUpdateDto)
        {
            if (id != vehicleUpdateDto.VehicleId)
            {
                return BadRequest(new { message = "Vehicle ID mismatch" });
            }

            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            var vehicle = _mapper.Map<Vehicle>(vehicleUpdateDto);
            var updatedVehicle = await _vehicleService.UpdateAsync(vehicle);
            var vehicleDto = _mapper.Map<VehicleDto>(updatedVehicle);
            return Ok(vehicleDto);
        }

        // DELETE: api/Vehicle/{id}
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteVehicle(int id)
        {
            var deleted = await _vehicleService.DeleteAsync(id);
            if (!deleted)
            {
                return NotFound(new { message = $"Vehicle with ID {id} not found" });
            }

            return NoContent();
        }
    }
}
