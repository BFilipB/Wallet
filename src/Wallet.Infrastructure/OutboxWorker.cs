using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Wallet.Shared;

namespace Wallet.Infrastructure;

public class OutboxWorker : BackgroundService
{
    private readonly ILogger<OutboxWorker> _logger;
    private readonly IOutboxPublisher _outboxPublisher;
    private readonly TimeSpan _pollingInterval;

    public OutboxWorker(
        ILogger<OutboxWorker> logger,
        IOutboxPublisher outboxPublisher,
        IOptions<OutboxOptions> options)
    {
        _logger = logger;
        _outboxPublisher = outboxPublisher;
        _pollingInterval = TimeSpan.FromSeconds(options.Value.PollingIntervalSeconds);
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("Outbox Worker started. Polling interval: {Interval}s", _pollingInterval.TotalSeconds);

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await _outboxPublisher.PublishPendingAsync(stoppingToken);
                await Task.Delay(_pollingInterval, stoppingToken);
            }
            catch (OperationCanceledException)
            {
                _logger.LogInformation("Outbox Worker is stopping");
                break;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error processing outbox messages");
                await Task.Delay(TimeSpan.FromSeconds(10), stoppingToken);
            }
        }

        _logger.LogInformation("Outbox Worker stopped");
    }
}
