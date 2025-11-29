namespace Wallet.Shared;

public record TopUpRequest(string PlayerId, decimal Amount, string ExternalRef);

public record TopUpResult(
    string PlayerId, 
    decimal Amount, 
    decimal NewBalance, 
    string ExternalRef, 
    Guid TransactionId, 
    DateTime ProcessedAt, 
    bool Idempotent);

public record WalletTopUpCompletedEvent(
    Guid TransactionId, 
    string PlayerId, 
    decimal Amount, 
    decimal NewBalance, 
    string ExternalRef, 
    DateTime ProcessedAt);

public interface ITopUpService
{
    Task<TopUpResult> ProcessTopUpAsync(TopUpRequest request, CancellationToken ct = default);
}

public interface IOutboxPublisher
{
    Task PublishPendingAsync(CancellationToken ct);
}
