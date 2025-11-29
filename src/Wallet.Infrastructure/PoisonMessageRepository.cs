using Dapper;
using Npgsql;
using Microsoft.Extensions.Options;
using Wallet.Shared;

namespace Wallet.Infrastructure;

public class PoisonMessageRepository : IPoisonMessageRepository
{
    private readonly string _connectionString;

    public PoisonMessageRepository(IOptions<DatabaseOptions> dbOptions)
    {
        _connectionString = dbOptions.Value.PostgreSQL;
    }

    public async Task SavePoisonMessageAsync(
        string topic,
        int partition,
        long offset,
        string? messageKey,
        string messageValue,
        string errorMessage,
        int retryCount,
        CancellationToken ct = default)
    {
        await using var connection = new NpgsqlConnection(_connectionString);

        await connection.ExecuteAsync(
            @"INSERT INTO PoisonMessages 
              (Topic, Partition, Offset, MessageKey, MessageValue, ErrorMessage, FailedAt, RetryCount, LastRetryAt)
              VALUES (@Topic, @Partition, @Offset, @MessageKey, @MessageValue, @ErrorMessage, @FailedAt, @RetryCount, @LastRetryAt)",
            new
            {
                Topic = topic,
                Partition = partition,
                Offset = offset,
                MessageKey = messageKey,
                MessageValue = messageValue,
                ErrorMessage = errorMessage,
                FailedAt = DateTime.UtcNow,
                RetryCount = retryCount,
                LastRetryAt = DateTime.UtcNow
            });
    }

    public async Task<IEnumerable<PoisonMessageRecord>> GetPoisonMessagesAsync(
        int limit = 100,
        CancellationToken ct = default)
    {
        await using var connection = new NpgsqlConnection(_connectionString);

        return await connection.QueryAsync<PoisonMessageRecord>(
            @"SELECT Id, Topic, Partition, Offset, MessageKey, MessageValue, ErrorMessage, FailedAt, RetryCount, LastRetryAt
              FROM PoisonMessages
              ORDER BY FailedAt DESC
              LIMIT @Limit",
            new { Limit = limit });
    }
}
