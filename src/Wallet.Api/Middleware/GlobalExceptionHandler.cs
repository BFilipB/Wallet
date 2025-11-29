using Microsoft.AspNetCore.Diagnostics;
using System.Net;
using System.Text.Json;
using Wallet.Shared;

namespace Wallet.Api.Middleware;

public class GlobalExceptionHandler : IExceptionHandler
{
    private readonly ILogger<GlobalExceptionHandler> _logger;

    public GlobalExceptionHandler(ILogger<GlobalExceptionHandler> logger)
    {
        _logger = logger;
    }

    public async ValueTask<bool> TryHandleAsync(
        HttpContext httpContext,
        Exception exception,
        CancellationToken cancellationToken)
    {
        var traceId = httpContext.TraceIdentifier;
        
        _logger.LogError(
            exception,
            "An unhandled exception occurred. TraceId: {TraceId}",
            traceId);

        var (statusCode, title, details) = exception switch
        {
            ArgumentException argEx => (HttpStatusCode.BadRequest, "Bad Request", argEx.Message),
            InvalidOperationException invOp => (HttpStatusCode.BadRequest, "Invalid Operation", invOp.Message),
            _ => (HttpStatusCode.InternalServerError, "Internal Server Error", "An unexpected error occurred")
        };

        var errorResponse = new ErrorResponse(
            title,
            details,
            traceId);

        httpContext.Response.ContentType = "application/json";
        httpContext.Response.StatusCode = (int)statusCode;

        await httpContext.Response.WriteAsJsonAsync(errorResponse, cancellationToken);

        return true;
    }
}
