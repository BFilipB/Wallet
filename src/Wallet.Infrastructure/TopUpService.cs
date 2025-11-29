using Dapper;
using Npgsql;
using StackExchange.Redis;
using System.Text.Json;
using Microsoft.Extensions.Options;
using Wallet.Shared;

namespace Wallet.Infrastructure;

public class TopUpService : ITopUpService
{
    private readonly string _connectionString;
    private readonly IConnectionMultiplexer _redis;
    private readonly IOutboxPublisher _outboxPublisher;

    public TopUpService(
        IOptions<DatabaseOptions> dbOptions,
        IConnectionMultiplexer redis,
        IOutboxPublisher outboxPublisher)
    {
        _connectionString = dbOptions.Value.PostgreSQL;
        _redis = redis;
        _outboxPublisher = outboxPublisher;
    }

    public async Task<TopUpResult> ProcessTopUpAsync(TopUpRequest request, CancellationToken ct = default)
    {
        await using var connection = new NpgsqlConnection(_connectionString);
        await connection.OpenAsync(ct);
        await using var transaction = await connection.BeginTransactionAsync(ct);

        try
        {
            var existingTransaction = await connection.QuerySingleOrDefaultAsync<TransactionRecord>(
                @"SELECT TransactionId, PlayerId, Amount, NewBalance, ExternalRef, ProcessedAt, TransactionType
                  FROM WalletTransactions 
                  WHERE ExternalRef = @ExternalRef",
                new { request.ExternalRef },
                transaction);

            if (existingTransaction != null)
            {
                return new TopUpResult(
                    existingTransaction.PlayerId,
                    existingTransaction.Amount,
                    existingTransaction.NewBalance,
                    existingTransaction.ExternalRef,
                    existingTransaction.TransactionId,
                    existingTransaction.ProcessedAt,
                    Idempotent: true);
            }

            var currentBalance = await connection.ExecuteScalarAsync<decimal?>(
                "SELECT Balance FROM Wallets WHERE PlayerId = @PlayerId",
                new { request.PlayerId },
                transaction) ?? 0;

            var newBalance = currentBalance + request.Amount;
            
            await connection.ExecuteAsync(
                @"INSERT INTO Wallets (PlayerId, Balance, UpdatedAt) 
                  VALUES (@PlayerId, @Balance, @UpdatedAt)
                  ON CONFLICT (PlayerId) 
                  DO UPDATE SET Balance = @Balance, UpdatedAt = @UpdatedAt",
                new { request.PlayerId, Balance = newBalance, UpdatedAt = DateTime.UtcNow },
                transaction);

            var transactionId = Guid.NewGuid();
            var processedAt = DateTime.UtcNow;

            await connection.ExecuteAsync(
                @"INSERT INTO WalletTransactions 
                  (TransactionId, PlayerId, Amount, NewBalance, ExternalRef, ProcessedAt, TransactionType, CreatedAt) 
                  VALUES (@TransactionId, @PlayerId, @Amount, @NewBalance, @ExternalRef, @ProcessedAt, @TransactionType, @CreatedAt)",
                new
                {
                    TransactionId = transactionId,
                    request.PlayerId,
                    request.Amount,
                    NewBalance = newBalance,
                    request.ExternalRef,
                    ProcessedAt = processedAt,
                    TransactionType = "TopUp",
                    CreatedAt = DateTime.UtcNow
                },
                transaction);

            var eventData = new WalletTopUpCompletedEvent(
                transactionId,
                request.PlayerId,
                request.Amount,
                newBalance,
                request.ExternalRef,
                processedAt);

            await connection.ExecuteAsync(
                @"INSERT INTO Outbox (Id, EventType, Payload, CreatedAt, Published)
                  VALUES (@Id, @EventType, @Payload::jsonb, @CreatedAt, false)",
                new
                {
                    Id = Guid.NewGuid(),
                    EventType = nameof(WalletTopUpCompletedEvent),
                    Payload = JsonSerializer.Serialize(eventData),
                    CreatedAt = DateTime.UtcNow
                },
                transaction);

            await transaction.CommitAsync(ct);

            var db = _redis.GetDatabase();
            
            // Update balance cache
            await db.StringSetAsync(
                $"wallet:balance:{request.PlayerId}",
                newBalance.ToString(),
                TimeSpan.FromMinutes(5));
            
            // Invalidate history cache to ensure fresh data on next read
            await db.KeyDeleteAsync($"wallet:history:{request.PlayerId}");

            // Note: Outbox processing is handled by OutboxWorker background service
            // No need for fire-and-forget Task.Run here

            return new TopUpResult(
                request.PlayerId,
                request.Amount,
                newBalance,
                request.ExternalRef,
                transactionId,
                processedAt,
                Idempotent: false);
        }
        catch
        {
            await transaction.RollbackAsync(ct);
            throw;
        }
    }

    private record TransactionRecord(
        Guid TransactionId,
        string PlayerId,
        decimal Amount,
        decimal NewBalance,
        string ExternalRef,
        DateTime ProcessedAt,
        string TransactionType);
}
