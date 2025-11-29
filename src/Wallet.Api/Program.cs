using Wallet.Api.Endpoints;
using Wallet.Api.Extensions;
using Wallet.Api.Middleware;

var builder = WebApplication.CreateBuilder(args);

// Add services
builder.Services.AddWalletServices(builder.Configuration);
builder.Services.AddObservability(builder.Configuration);

// Add health checks
builder.Services.AddHealthChecks()
    .AddRedis(builder.Configuration.GetConnectionString("Redis") ?? "localhost:6379");

// Add problem details and exception handling
builder.Services.AddProblemDetails();
builder.Services.AddExceptionHandler<GlobalExceptionHandler>();

// Add OpenAPI
builder.Services.AddOpenApi();

// Add CORS
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.WithOrigins(builder.Configuration.GetSection("Cors:AllowedOrigins").Get<string[]>() ?? ["http://localhost:3000"])
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

var app = builder.Build();

// Configure middleware pipeline
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    app.UseDeveloperExceptionPage();
}

app.UseExceptionHandler(); // Use global exception handler
app.UseRequestLogging(); // Custom logging middleware
app.UseCors();
app.UseHttpsRedirection();

// Map endpoints
app.MapHealthChecks("/health");
app.MapWalletEndpoints();
app.MapAdminEndpoints();

app.Run();
