using Confluent.Kafka;
using FluentValidation;
using StackExchange.Redis;
using Wallet.Infrastructure;
using Wallet.Shared;
using OpenTelemetry.Metrics;
using OpenTelemetry.Resources;
using OpenTelemetry.Trace;

namespace Wallet.Api.Extensions;

public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddWalletServices(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        // Configure Options
        services.Configure<DatabaseOptions>(configuration.GetSection("ConnectionStrings"));
        services.Configure<RedisOptions>(options =>
        {
            options.ConnectionString = configuration.GetConnectionString("Redis") ?? "localhost:6379";
        });
        services.Configure<KafkaOptions>(configuration.GetSection("Kafka"));
        services.Configure<OutboxOptions>(configuration.GetSection("Outbox"));

        // Redis
        var redisConnection = configuration.GetConnectionString("Redis") ?? "localhost:6379";
        var redis = ConnectionMultiplexer.Connect(redisConnection);
        services.AddSingleton<IConnectionMultiplexer>(redis);

        // Kafka Producer with proper lifecycle
        services.AddSingleton<IProducer<string, string>>(sp =>
        {
            var kafkaConfig = configuration.GetSection("Kafka");
            var producerConfig = new ProducerConfig
            {
                BootstrapServers = kafkaConfig["BootstrapServers"] ?? "localhost:9092",
                Acks = Acks.All, // Wait for all replicas
                EnableIdempotence = true, // Exactly-once semantics
                MaxInFlight = 5,
                MessageSendMaxRetries = 3
            };
            return new ProducerBuilder<string, string>(producerConfig).Build();
        });

        // Register application services
        services.AddSingleton<IOutboxPublisher, OutboxPublisher>();
        services.AddSingleton<ITopUpService, TopUpService>();
        services.AddSingleton<IWalletHistoryService, WalletHistoryService>();
        services.AddSingleton<IPoisonMessageRepository, PoisonMessageRepository>();

        // Register validators
        services.AddValidatorsFromAssemblyContaining<Program>();

        // Register background services
        services.AddHostedService<OutboxWorker>();

        return services;
    }

    public static IServiceCollection AddObservability(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        // Metrics
        var meter = new System.Diagnostics.Metrics.Meter("Wallet.Api");
        var topUpCounter = meter.CreateCounter<long>("wallet.topup.count", "requests", "Number of top-up requests");
        var topUpDuration = meter.CreateHistogram<double>("wallet.topup.duration", "ms", "Duration of top-up processing");

        services.AddSingleton(meter);
        services.AddSingleton(topUpCounter);
        services.AddSingleton(topUpDuration);

        // Activity Source for tracing
        var activitySource = new System.Diagnostics.ActivitySource("Wallet.Api");
        services.AddSingleton(activitySource);

        // OpenTelemetry
        services.AddOpenTelemetry()
            .ConfigureResource(resource => resource
                .AddService(serviceName: "Wallet.Api")
                .AddAttributes(new Dictionary<string, object>
                {
                    ["deployment.environment"] = Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT") ?? "Production",
                    ["service.version"] = "1.0.0"
                }))
            .WithMetrics(metrics => metrics
                .AddAspNetCoreInstrumentation()
                .AddHttpClientInstrumentation()
                .AddRuntimeInstrumentation()
                .AddMeter("Wallet.Api")
                .AddConsoleExporter()
                .AddOtlpExporter())
            .WithTracing(tracing => tracing
                .AddAspNetCoreInstrumentation()
                .AddHttpClientInstrumentation()
                .AddSource("Wallet.Api")
                .AddConsoleExporter()
                .AddOtlpExporter());

        return services;
    }
}
