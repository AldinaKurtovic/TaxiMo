using AutoMapper;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TaxiMo.Model.Exceptions;
using TaxiMo.Services.Database.Entities;
using TaxiMo.Services.Interfaces;
using System.Reflection;

namespace TaxiMoWebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public abstract class BaseCRUDController<TEntity, TDto, TCreateDto, TUpdateDto> : BaseController
        where TEntity : class
        where TDto : class
        where TCreateDto : class
        where TUpdateDto : class
    {
        protected readonly IBaseCRUDService<TEntity> Service;
        protected abstract string EntityName { get; }

        protected BaseCRUDController(
            IBaseCRUDService<TEntity> service,
            IMapper mapper,
            ILogger logger) : base(mapper, logger)
        {
            Service = service;
        }

        // GET: api/{controller}
        [HttpGet]
        public virtual async Task<ActionResult<IEnumerable<TDto>>> GetAll()
        {
            try
            {
                var entities = await Service.GetAllAsync();
                var dtos = Mapper.Map<List<TDto>>(entities);
                return Ok(dtos);
            }
            catch (Exception ex)
            {
                Logger.LogError(ex, "Error retrieving {EntityName}", EntityName);
                return StatusCode(500, new { message = $"An error occurred while retrieving {EntityName}" });
            }
        }

        // GET: api/{controller}/{id}
        [HttpGet("{id}")]
        public virtual async Task<ActionResult<TDto>> GetById(int id)
        {
            try
            {
                var entity = await Service.GetByIdAsync(id);

                if (entity == null)
                {
                    return NotFound(new { message = $"{EntityName} with ID {id} not found" });
                }

                var dto = Mapper.Map<TDto>(entity);
                return Ok(dto);
            }
            catch (Exception ex)
            {
                Logger.LogError(ex, "Error retrieving {EntityName} with ID {Id}", EntityName, id);
                return StatusCode(500, new { message = $"An error occurred while retrieving the {EntityName}" });
            }
        }

        // POST: api/{controller}
        [HttpPost]
        public virtual async Task<ActionResult<TDto>> Create(TCreateDto createDto)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    return BadRequest(ModelState);
                }

                var entity = Mapper.Map<TEntity>(createDto);
                var createdEntity = await Service.CreateAsync(entity);
                var dto = Mapper.Map<TDto>(createdEntity);

                // Get the ID property from the DTO using reflection
                var idProperty = typeof(TDto).GetProperty($"{typeof(TEntity).Name}Id");
                if (idProperty == null)
                {
                    // Try alternative naming patterns
                    idProperty = typeof(TDto).GetProperty("Id") ?? 
                                typeof(TDto).GetProperties().FirstOrDefault(p => p.Name.EndsWith("Id"));
                }

                var id = idProperty?.GetValue(dto);
                return CreatedAtAction(nameof(GetById), new { id }, dto);
            }
            catch (Exception ex)
            {
                Logger.LogError(ex, "Error creating {EntityName}", EntityName);
                return StatusCode(500, new { message = $"An error occurred while creating the {EntityName}" });
            }
        }

        // PUT: api/{controller}/{id}
        [HttpPut("{id}")]
        public virtual async Task<ActionResult<TDto>> Update(int id, TUpdateDto updateDto)
        {
            try
            {
                // Get the ID property from the UpdateDto using reflection
                var idProperty = typeof(TUpdateDto).GetProperty($"{typeof(TEntity).Name}Id");
                if (idProperty == null)
                {
                    // Try alternative naming patterns
                    idProperty = typeof(TUpdateDto).GetProperty("Id") ?? 
                                typeof(TUpdateDto).GetProperties().FirstOrDefault(p => p.Name.EndsWith("Id"));
                }

                if (idProperty != null)
                {
                    var dtoId = idProperty.GetValue(updateDto);
                    if (dtoId != null && Convert.ToInt32(dtoId) != id)
                    {
                        return BadRequest(new { message = $"{EntityName} ID mismatch" });
                    }
                }

                if (!ModelState.IsValid)
                {
                    return BadRequest(ModelState);
                }

                try
                {
                    var entity = Mapper.Map<TEntity>(updateDto);
                    var updatedEntity = await Service.UpdateAsync(entity);
                    var dto = Mapper.Map<TDto>(updatedEntity);
                    return Ok(dto);
                }
                catch (UserException ex)
                {
                    return NotFound(new { message = ex.Message });
                }
            }
            catch (Exception ex)
            {
                Logger.LogError(ex, "Error updating {EntityName} with ID {Id}", EntityName, id);
                return StatusCode(500, new { message = $"An error occurred while updating the {EntityName}" });
            }
        }

        // DELETE: api/{controller}/{id}
        [HttpDelete("{id}")]
        public virtual async Task<IActionResult> Delete(int id)
        {
            try
            {
                var deleted = await Service.DeleteAsync(id);
                if (!deleted)
                {
                    return NotFound(new { message = $"{EntityName} with ID {id} not found" });
                }

                return NoContent();
            }
            catch (Exception ex)
            {
                Logger.LogError(ex, "Error deleting {EntityName} with ID {Id}", EntityName, id);
                return StatusCode(500, new { message = $"An error occurred while deleting the {EntityName}" });
            }
        }
    }
}

