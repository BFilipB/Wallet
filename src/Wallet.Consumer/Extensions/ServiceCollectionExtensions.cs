using Confluent.Kafka;
using StackExchange.Redis;
using Wallet.Infrastructure;
using Wallet.Shared;
using OpenTelemetry.Metrics;
using OpenTelemetry.Resources;
using OpenTelemetry.Trace;

namespace Wallet.Consumer.Extensions;

public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddConsumerServices(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        // Configure Options
        services.Configure<DatabaseOptions>(configuration.GetSection("ConnectionStrings"));
        services.Configure<KafkaOptions>(configuration.GetSection("Kafka"));

        // Redis
        var redisConnection = configuration.GetConnectionString("Redis") ?? "localhost:6379";
        var redis = ConnectionMultiplexer.Connect(redisConnection);
        services.AddSingleton<IConnectionMultiplexer>(redis);

        // Kafka Producer (for outbox publishing)
        services.AddSingleton<IProducer<string, string>>(sp =>
        {
            var kafkaConfig = configuration.GetSection("Kafka");
            var producerConfig = new ProducerConfig
            {
                BootstrapServers = kafkaConfig["BootstrapServers"] ?? "localhost:9092",
                Acks = Acks.All,
                EnableIdempotence = true
            };
            return new ProducerBuilder<string, string>(producerConfig).Build();
        });

        // Register application services
        services.AddSingleton<IOutboxPublisher, OutboxPublisher>();
        services.AddSingleton<ITopUpService, TopUpService>();
        services.AddSingleton<IPoisonMessageRepository, PoisonMessageRepository>();

        // Register background worker
        services.AddHostedService<Worker>();

        return services;
    }

    public static IServiceCollection AddConsumerObservability(
        this IServiceCollection services)
    {
        // Metrics
        var meter = new System.Diagnostics.Metrics.Meter("Wallet.Consumer");
        services.AddSingleton(meter);

        // OpenTelemetry
        services.AddOpenTelemetry()
            .ConfigureResource(resource => resource
                .AddService(serviceName: "Wallet.Consumer")
                .AddAttributes(new Dictionary<string, object>
                {
                    ["deployment.environment"] = Environment.GetEnvironmentVariable("DOTNET_ENVIRONMENT") ?? "Production",
                    ["service.version"] = "1.0.0"
                }))
            .WithMetrics(metrics => metrics
                .AddRuntimeInstrumentation()
                .AddMeter("Wallet.Consumer")
                .AddConsoleExporter()
                .AddOtlpExporter())
            .WithTracing(tracing => tracing
                .AddSource("Wallet.Consumer")
                .AddConsoleExporter()
                .AddOtlpExporter());

        return services;
    }
}
