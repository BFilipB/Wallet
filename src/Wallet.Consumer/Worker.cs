using Confluent.Kafka;
using System.Text.Json;
using Wallet.Shared;
using Wallet.Infrastructure;
using System.Diagnostics;
using System.Diagnostics.Metrics;
using Microsoft.Extensions.Options;

namespace Wallet.Consumer;

public class Worker : BackgroundService
{
    private readonly ILogger<Worker> _logger;
    private readonly ITopUpService _topUpService;
    private readonly IConsumer<string, string> _consumer;
    private readonly IPoisonMessageRepository _poisonMessageRepository;
    private readonly Meter _meter;
    private readonly Counter<long> _messagesProcessedCounter;
    private readonly Counter<long> _messageFailedCounter;
    private readonly Histogram<double> _processingDuration;
    private readonly ActivitySource _activitySource;
    private const int MaxRetries = 3;

    public Worker(
        ILogger<Worker> logger,
        ITopUpService topUpService,
        IPoisonMessageRepository poisonMessageRepository,
        Meter meter,
        IOptions<KafkaOptions> kafkaOptions)
    {
        _logger = logger;
        _topUpService = topUpService;
        _poisonMessageRepository = poisonMessageRepository;
        _meter = meter;
        
        _messagesProcessedCounter = _meter.CreateCounter<long>("kafka.messages.processed", "messages", "Number of Kafka messages processed");
        _messageFailedCounter = _meter.CreateCounter<long>("kafka.messages.failed", "messages", "Number of Kafka messages failed");
        _processingDuration = _meter.CreateHistogram<double>("kafka.message.processing.duration", "ms", "Duration of message processing");
        _activitySource = new ActivitySource("Wallet.Consumer");

        var config = new ConsumerConfig
        {
            BootstrapServers = kafkaOptions.Value.BootstrapServers,
            GroupId = kafkaOptions.Value.GroupId,
            AutoOffsetReset = AutoOffsetReset.Earliest,
            EnableAutoCommit = false,
            MaxPollIntervalMs = 300000,
            SessionTimeoutMs = 45000,
            HeartbeatIntervalMs = 3000
        };

        _consumer = new ConsumerBuilder<string, string>(config).Build();
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _consumer.Subscribe("wallet-topup-requests");

        _logger.LogInformation("Kafka consumer started. Listening for messages...");

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                var consumeResult = _consumer.Consume(TimeSpan.FromSeconds(1));
                
                if (consumeResult == null)
                    continue;

                _logger.LogInformation("Received message: {Key} at offset {Offset}", 
                    consumeResult.Message.Key, 
                    consumeResult.TopicPartitionOffset);

                var stopwatch = Stopwatch.StartNew();
                
                await ProcessMessageAsync(consumeResult, stoppingToken);
                
                _consumer.Commit(consumeResult);
                
                stopwatch.Stop();
                _processingDuration.Record(stopwatch.ElapsedMilliseconds);
                _messagesProcessedCounter.Add(1, 
                    new KeyValuePair<string, object?>("topic", consumeResult.Topic),
                    new KeyValuePair<string, object?>("partition", consumeResult.Partition.Value));
                
                _logger.LogInformation("Message processed successfully: {Key}", consumeResult.Message.Key);
            }
            catch (ConsumeException ex)
            {
                _logger.LogError(ex, "Error consuming message: {Reason}", ex.Error.Reason);
                _messageFailedCounter.Add(1, new KeyValuePair<string, object?>("error_type", "ConsumeException"));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Unexpected error in consumer loop");
                _messageFailedCounter.Add(1, new KeyValuePair<string, object?>("error_type", ex.GetType().Name));
                await Task.Delay(TimeSpan.FromSeconds(5), stoppingToken);
            }
        }
    }

    private async Task ProcessMessageAsync(ConsumeResult<string, string> consumeResult, CancellationToken ct)
    {
        using var activity = _activitySource.StartActivity("ProcessMessage", ActivityKind.Consumer);
        activity?.SetTag("messaging.system", "kafka");
        activity?.SetTag("messaging.destination", consumeResult.Topic);
        activity?.SetTag("messaging.kafka.partition", consumeResult.Partition.Value);
        activity?.SetTag("messaging.kafka.offset", consumeResult.Offset.Value);
        
        var retryCount = 0;
        
        while (retryCount < MaxRetries)
        {
            try
            {
                var request = JsonSerializer.Deserialize<TopUpRequest>(consumeResult.Message.Value);
                
                if (request == null)
                {
                    _logger.LogWarning("Received null or invalid message, saving to poison messages table");
                    await SavePoisonMessageAsync(consumeResult, "Invalid or null message after deserialization", retryCount);
                    activity?.SetStatus(ActivityStatusCode.Error, "Invalid message");
                    return;
                }

                activity?.SetTag("playerId", request.PlayerId);
                activity?.SetTag("externalRef", request.ExternalRef);

                var result = await _topUpService.ProcessTopUpAsync(request, ct);
                
                if (result.Idempotent)
                {
                    _logger.LogInformation("Message {ExternalRef} was already processed (idempotent)", 
                        request.ExternalRef);
                }
                
                activity?.SetStatus(ActivityStatusCode.Ok);
                return;
            }
            catch (JsonException ex)
            {
                _logger.LogError(ex, "Invalid JSON format, saving to poison messages table");
                await SavePoisonMessageAsync(consumeResult, $"JSON parsing error: {ex.Message}", retryCount);
                activity?.SetStatus(ActivityStatusCode.Error, "JSON parsing error");
                activity?.AddEvent(new ActivityEvent("exception", 
                    tags: new ActivityTagsCollection { { "exception.type", ex.GetType().Name }, { "exception.message", ex.Message } }));
                return;
            }
            catch (Exception ex)
            {
                retryCount++;
                _logger.LogError(ex, "Error processing message (attempt {Attempt}/{MaxRetries})", 
                    retryCount, MaxRetries);
                
                if (retryCount >= MaxRetries)
                {
                    _logger.LogError("Max retries reached, saving message to poison messages table");
                    await SavePoisonMessageAsync(consumeResult, $"Max retries exceeded: {ex.Message}", retryCount);
                    activity?.SetStatus(ActivityStatusCode.Error, "Max retries exceeded");
                    activity?.AddEvent(new ActivityEvent("exception", 
                        tags: new ActivityTagsCollection { { "exception.type", ex.GetType().Name }, { "exception.message", ex.Message } }));
                    return;
                }
                
                await Task.Delay(TimeSpan.FromSeconds(Math.Pow(2, retryCount)), ct);
            }
        }
    }

    private async Task SavePoisonMessageAsync(
        ConsumeResult<string, string> consumeResult, 
        string errorMessage, 
        int retryCount)
    {
        try
        {
            await _poisonMessageRepository.SavePoisonMessageAsync(
                consumeResult.Topic,
                consumeResult.Partition.Value,
                consumeResult.Offset.Value,
                consumeResult.Message.Key,
                consumeResult.Message.Value,
                errorMessage,
                retryCount,
                CancellationToken.None);

            _logger.LogWarning(
                "Poison message saved. Topic: {Topic}, Partition: {Partition}, Offset: {Offset}, Error: {Error}",
                consumeResult.Topic,
                consumeResult.Partition.Value,
                consumeResult.Offset.Value,
                errorMessage);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to save poison message to database");
        }
    }

    public override async Task StopAsync(CancellationToken cancellationToken)
    {
        _logger.LogInformation("Consumer stopping...");
        _consumer.Close();
        _consumer.Dispose();
        _activitySource.Dispose();
        await base.StopAsync(cancellationToken);
    }
}
