using Wallet.Consumer;
using Wallet.Consumer.Extensions;

var builder = Host.CreateApplicationBuilder(args);

// Add services
builder.Services.AddConsumerServices(builder.Configuration);
builder.Services.AddConsumerObservability();

var host = builder.Build();
host.Run();
