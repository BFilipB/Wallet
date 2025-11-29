using Confluent.Kafka;
using Dapper;
using Npgsql;
using Microsoft.Extensions.Options;
using Wallet.Shared;

namespace Wallet.Infrastructure;

public class OutboxPublisher : IOutboxPublisher
{
    private readonly string _connectionString;
    private readonly IProducer<string, string> _producer;
    private readonly int _batchSize;

    public OutboxPublisher(
        IOptions<DatabaseOptions> dbOptions,
        IOptions<OutboxOptions> outboxOptions,
        IProducer<string, string> producer)
    {
        _connectionString = dbOptions.Value.PostgreSQL;
        _producer = producer;
        _batchSize = outboxOptions.Value.BatchSize;
    }

    public async Task PublishPendingAsync(CancellationToken ct)
    {
        await using var connection = new NpgsqlConnection(_connectionString);
        await connection.OpenAsync(ct);

        var pendingEvents = await connection.QueryAsync<OutboxRecord>(
            @"SELECT Id, EventType, Payload, CreatedAt 
              FROM Outbox 
              WHERE Published = false 
              ORDER BY CreatedAt 
              LIMIT @BatchSize",
            new { BatchSize = _batchSize });

        foreach (var evt in pendingEvents)
        {
            try
            {
                await _producer.ProduceAsync(
                    "wallet-events",
                    new Message<string, string>
                    {
                        Key = evt.Id.ToString(),
                        Value = evt.Payload
                    },
                    ct);

                await connection.ExecuteAsync(
                    "UPDATE Outbox SET Published = true, PublishedAt = @PublishedAt WHERE Id = @Id",
                    new { Id = evt.Id, PublishedAt = DateTime.UtcNow });
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Failed to publish event {evt.Id}: {ex.Message}");
            }
        }
    }

    private record OutboxRecord(Guid Id, string EventType, string Payload, DateTime CreatedAt);
}
