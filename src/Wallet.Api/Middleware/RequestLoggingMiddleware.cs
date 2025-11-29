using Microsoft.Extensions.Options;
using Wallet.Shared;

namespace Wallet.Api.Middleware;

public class RequestLoggingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<RequestLoggingMiddleware> _logger;

    public RequestLoggingMiddleware(RequestDelegate next, ILogger<RequestLoggingMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        var requestId = context.TraceIdentifier;
        var method = context.Request.Method;
        var path = context.Request.Path;

        _logger.LogInformation(
            "HTTP {Method} {Path} started. RequestId: {RequestId}",
            method,
            path,
            requestId);

        var sw = System.Diagnostics.Stopwatch.StartNew();

        try
        {
            await _next(context);
        }
        finally
        {
            sw.Stop();
            
            _logger.LogInformation(
                "HTTP {Method} {Path} completed with {StatusCode} in {ElapsedMs}ms. RequestId: {RequestId}",
                method,
                path,
                context.Response.StatusCode,
                sw.ElapsedMilliseconds,
                requestId);
        }
    }
}

public static class RequestLoggingMiddlewareExtensions
{
    public static IApplicationBuilder UseRequestLogging(this IApplicationBuilder builder)
    {
        return builder.UseMiddleware<RequestLoggingMiddleware>();
    }
}
