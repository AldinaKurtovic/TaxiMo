using TaxiMo.Services.Database;

namespace TaxiMo.Services.Services
{
    public abstract class BaseService
    {
        protected readonly TaxiMoDbContext Context;

        protected BaseService(TaxiMoDbContext context)
        {
            Context = context;
        }
    }
}

