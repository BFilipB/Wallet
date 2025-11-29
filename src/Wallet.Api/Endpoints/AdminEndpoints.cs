using Wallet.Shared;

namespace Wallet.Api.Endpoints;

public static class AdminEndpoints
{
    public static RouteGroupBuilder MapAdminEndpoints(this IEndpointRouteBuilder routes)
    {
        var group = routes.MapGroup("/admin")
            .WithTags("Admin")
            .WithOpenApi();
            // .RequireAuthorization("AdminPolicy"); // Uncomment when auth is added

        group.MapGet("/poison-messages", GetPoisonMessagesAsync)
            .WithName("GetPoisonMessages")
            .WithDescription("Admin: Get list of poison messages")
            .Produces<IEnumerable<PoisonMessageRecord>>(200)
            .Produces<ErrorResponse>(500);

        return group;
    }

    private static async Task<IResult> GetPoisonMessagesAsync(
        IPoisonMessageRepository repository,
        int limit = 100,
        CancellationToken ct = default)
    {
        var messages = await repository.GetPoisonMessagesAsync(limit, ct);
        return Results.Ok(messages);
    }
}
