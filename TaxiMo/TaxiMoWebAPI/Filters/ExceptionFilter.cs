using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using System.Net;
using TaxiMo.Model.Exceptions;

namespace TaxiMoWebAPI.Filters
{
    public class ExceptionFilter : ExceptionFilterAttribute
    {
        private readonly ILogger<ExceptionFilter> _logger;

        public ExceptionFilter(ILogger<ExceptionFilter> logger)
        {
            _logger = logger;
        }

        public override void OnException(ExceptionContext context)
        {
            // Log full exception details including inner exception and stack trace
            _logger.LogError(context.Exception, 
                "Exception: {ExceptionType}\nMessage: {Message}\nStackTrace: {StackTrace}\nInnerException: {InnerException}",
                context.Exception.GetType().FullName,
                context.Exception.Message,
                context.Exception.StackTrace,
                context.Exception.InnerException?.ToString() ?? "None");

            if (context.Exception is UserException)
            {
                context.ModelState.AddModelError("userError", context.Exception.Message);
                context.HttpContext.Response.StatusCode = (int)HttpStatusCode.BadRequest;
            }
            else
            {
                // TEMPORARY: Return actual exception details for debugging
                var exceptionDetails = new
                {
                    error = context.Exception.Message,
                    exceptionType = context.Exception.GetType().FullName,
                    stackTrace = context.Exception.StackTrace,
                    innerException = context.Exception.InnerException != null ? new
                    {
                        message = context.Exception.InnerException.Message,
                        type = context.Exception.InnerException.GetType().FullName,
                        stackTrace = context.Exception.InnerException.StackTrace
                    } : null
                };

                context.HttpContext.Response.StatusCode = (int)HttpStatusCode.InternalServerError;
                context.Result = new JsonResult(exceptionDetails);
                return;
            }

            var errors = context.ModelState
                .Where(x => x.Value.Errors.Count > 0)
                .ToDictionary(
                    x => x.Key,
                    x => x.Value.Errors.Select(e => e.ErrorMessage).ToList()
                );

            context.Result = new JsonResult(new { errors });
        }
    }
}

