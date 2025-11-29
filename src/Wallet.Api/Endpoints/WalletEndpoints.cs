using Wallet.Shared;
using Dapper;
using Npgsql;
using Microsoft.Extensions.Options;
using FluentValidation;

namespace Wallet.Api.Endpoints;

public static class WalletEndpoints
{
    public static RouteGroupBuilder MapWalletEndpoints(this IEndpointRouteBuilder routes)
    {
        var group = routes.MapGroup("/wallet")
            .WithTags("Wallet")
            .WithOpenApi();

        group.MapPost("/topup", TopUpAsync)
            .WithName("TopUpWallet")
            .WithDescription("Process a wallet top-up with idempotency support")
            .Produces<TopUpResult>(200)
            .Produces<ErrorResponse>(400)
            .Produces<ErrorResponse>(500);

        group.MapGet("/{playerId}/balance", GetBalanceAsync)
            .WithName("GetWalletBalance")
            .WithDescription("Get current wallet balance for a player")
            .Produces<WalletBalanceResponse>(200)
            .Produces<ErrorResponse>(404)
            .Produces<ErrorResponse>(500);

        group.MapGet("/{playerId}/history", GetHistoryAsync)
            .WithName("GetWalletHistory")
            .WithDescription("Get wallet transaction history with Redis caching")
            .Produces<IEnumerable<WalletTransaction>>(200)
            .Produces<ErrorResponse>(500);

        return group;
    }

    private static async Task<IResult> TopUpAsync(
        TopUpRequest request,
        ITopUpService service,
        IValidator<TopUpRequest> validator,
        System.Diagnostics.ActivitySource activitySource,
        System.Diagnostics.Metrics.Counter<long> counter,
        System.Diagnostics.Metrics.Histogram<double> histogram,
        CancellationToken ct)
    {
        // Validate request
        var validationResult = await validator.ValidateAsync(request, ct);
        if (!validationResult.IsValid)
        {
            var errors = validationResult.Errors.Select(e => e.ErrorMessage);
            return Results.BadRequest(new ErrorResponse(
                "Validation Failed",
                string.Join("; ", errors)));
        }

        using var activity = activitySource.StartActivity("ProcessTopUp", System.Diagnostics.ActivityKind.Server);
        activity?.SetTag("playerId", request.PlayerId);
        activity?.SetTag("amount", request.Amount);
        activity?.SetTag("externalRef", request.ExternalRef);

        var stopwatch = System.Diagnostics.Stopwatch.StartNew();

        counter.Add(1, new KeyValuePair<string, object?>("endpoint", "/wallet/topup"));

        var result = await service.ProcessTopUpAsync(request, ct);

        stopwatch.Stop();
        histogram.Record(stopwatch.ElapsedMilliseconds,
            new KeyValuePair<string, object?>("success", "true"),
            new KeyValuePair<string, object?>("idempotent", result.Idempotent.ToString()));

        activity?.SetTag("transactionId", result.TransactionId);
        activity?.SetTag("idempotent", result.Idempotent);
        activity?.SetStatus(System.Diagnostics.ActivityStatusCode.Ok);

        return Results.Ok(result);
    }

    private static async Task<IResult> GetBalanceAsync(
        string playerId,
        IOptions<DatabaseOptions> dbOptions,
        CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(playerId))
            return Results.BadRequest(new ErrorResponse("PlayerId is required"));

        await using var connection = new NpgsqlConnection(dbOptions.Value.PostgreSQL);
        var balance = await connection.ExecuteScalarAsync<decimal?>(
            "SELECT Balance FROM Wallets WHERE PlayerId = @PlayerId",
            new { PlayerId = playerId });

        if (balance == null)
            return Results.NotFound(new ErrorResponse($"Wallet not found for player: {playerId}"));

        return Results.Ok(new WalletBalanceResponse(playerId, balance.Value));
    }

    private static async Task<IResult> GetHistoryAsync(
        string playerId,
        IWalletHistoryService service,
        CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(playerId))
            return Results.BadRequest(new ErrorResponse("PlayerId is required"));

        var history = await service.GetHistoryAsync(playerId, ct);
        return Results.Ok(history);
    }
}
