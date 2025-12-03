using Microsoft.EntityFrameworkCore;
using TaxiMo.Model.Exceptions;
using TaxiMo.Services.Database;
using TaxiMo.Services.Database.Entities;
using TaxiMo.Services.Interfaces;

namespace TaxiMo.Services.Services
{
    public abstract class BaseCRUDService<TEntity> : BaseService, IBaseCRUDService<TEntity> where TEntity : class
    {
        protected BaseCRUDService(TaxiMoDbContext context) : base(context)
        {
        }

        protected DbSet<TEntity> DbSet => Context.Set<TEntity>();

        public virtual async Task<List<TEntity>> GetAllAsync()
        {
            return await DbSet.ToListAsync();
        }

        public virtual async Task<TEntity?> GetByIdAsync(int id)
        {
            return await DbSet.FindAsync(id);
        }

        public virtual async Task<TEntity> CreateAsync(TEntity entity)
        {
            DbSet.Add(entity);
            await Context.SaveChangesAsync();
            return entity;
        }

        public virtual async Task<TEntity> UpdateAsync(TEntity entity)
        {
            // Get the primary key value using reflection
            var entityType = Context.Model.FindEntityType(typeof(TEntity));
            if (entityType == null)
            {
                throw new InvalidOperationException($"Entity type {typeof(TEntity).Name} not found in model");
            }

            var primaryKey = entityType.FindPrimaryKey();
            if (primaryKey == null || primaryKey.Properties.Count != 1)
            {
                throw new InvalidOperationException($"Entity type {typeof(TEntity).Name} must have a single primary key property");
            }

            var keyProperty = primaryKey.Properties[0];
            var keyPropertyInfo = typeof(TEntity).GetProperty(keyProperty.Name);
            if (keyPropertyInfo == null)
            {
                throw new InvalidOperationException($"Primary key property {keyProperty.Name} not found on {typeof(TEntity).Name}");
            }

            var keyValue = keyPropertyInfo.GetValue(entity);
            if (keyValue == null)
            {
                throw new ArgumentException("Entity must have a primary key value");
            }

            var existingEntity = await DbSet.FindAsync(keyValue);
            if (existingEntity == null)
            {
                throw new UserException($"{typeof(TEntity).Name} with ID {keyValue} not found.");
            }

            // Update properties using reflection
            Context.Entry(existingEntity).CurrentValues.SetValues(entity);
            await Context.SaveChangesAsync();

            return existingEntity;
        }

        public virtual async Task<bool> DeleteAsync(int id)
        {
            var entity = await DbSet.FindAsync(id);
            if (entity == null)
            {
                return false;
            }

            DbSet.Remove(entity);
            await Context.SaveChangesAsync();
            return true;
        }
    }
}

