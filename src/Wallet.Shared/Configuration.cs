namespace Wallet.Shared;

// Configuration Options
public class DatabaseOptions
{
    public string PostgreSQL { get; set; } = string.Empty;
}

public class RedisOptions
{
    public string ConnectionString { get; set; } = string.Empty;
}

public class KafkaOptions
{
    public string BootstrapServers { get; set; } = string.Empty;
    public string GroupId { get; set; } = string.Empty;
}

public class OutboxOptions
{
    public int PollingIntervalSeconds { get; set; } = 5;
    public int BatchSize { get; set; } = 100;
}

// Response DTOs
public record WalletBalanceResponse(string PlayerId, decimal Balance);

public record ErrorResponse(string Error, string? Details = null, string? TraceId = null);

// Interfaces for better abstraction
public interface IWalletHistoryService
{
    Task<IEnumerable<WalletTransaction>> GetHistoryAsync(string playerId, CancellationToken ct = default);
    Task InvalidateCacheAsync(string playerId);
}

public interface IPoisonMessageRepository
{
    Task SavePoisonMessageAsync(
        string topic,
        int partition,
        long offset,
        string? messageKey,
        string messageValue,
        string errorMessage,
        int retryCount,
        CancellationToken ct = default);

    Task<IEnumerable<PoisonMessageRecord>> GetPoisonMessagesAsync(
        int limit = 100,
        CancellationToken ct = default);
}

public record PoisonMessageRecord(
    Guid Id,
    string Topic,
    int Partition,
    long Offset,
    string? MessageKey,
    string MessageValue,
    string ErrorMessage,
    DateTime FailedAt,
    int RetryCount,
    DateTime? LastRetryAt);

public record WalletTransaction(
    Guid TransactionId,
    string PlayerId,
    decimal Amount,
    decimal NewBalance,
    string ExternalRef,
    DateTime ProcessedAt,
    string TransactionType,
    DateTime CreatedAt);
