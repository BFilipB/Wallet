using Dapper;
using Npgsql;
using StackExchange.Redis;
using System.Text.Json;
using Microsoft.Extensions.Options;
using Wallet.Shared;

namespace Wallet.Infrastructure;

public class WalletHistoryService : IWalletHistoryService
{
    private readonly string _connectionString;
    private readonly IConnectionMultiplexer _redis;

    public WalletHistoryService(IOptions<DatabaseOptions> dbOptions, IConnectionMultiplexer redis)
    {
        _connectionString = dbOptions.Value.PostgreSQL;
        _redis = redis;
    }

    public async Task<IEnumerable<WalletTransaction>> GetHistoryAsync(string playerId, CancellationToken ct = default)
    {
        var db = _redis.GetDatabase();
        var cacheKey = $"wallet:history:{playerId}";
        
        var cached = await db.StringGetAsync(cacheKey);
        if (cached.HasValue)
        {
            return JsonSerializer.Deserialize<List<WalletTransaction>>(cached.ToString())!;
        }

        await using var connection = new NpgsqlConnection(_connectionString);
        
        var transactions = (await connection.QueryAsync<WalletTransaction>(
            @"SELECT TransactionId, PlayerId, Amount, NewBalance, ExternalRef, ProcessedAt, TransactionType, CreatedAt 
              FROM WalletTransactions 
              WHERE PlayerId = @PlayerId 
              ORDER BY CreatedAt DESC 
              LIMIT 100",
            new { PlayerId = playerId })).ToList();

        await db.StringSetAsync(
            cacheKey,
            JsonSerializer.Serialize(transactions),
            TimeSpan.FromMinutes(2));

        return transactions;
    }

    public async Task InvalidateCacheAsync(string playerId)
    {
        var db = _redis.GetDatabase();
        await db.KeyDeleteAsync($"wallet:history:{playerId}");
        await db.KeyDeleteAsync($"wallet:balance:{playerId}");
    }
}
