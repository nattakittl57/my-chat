using Azure;
using Azure.AI.OpenAI;
using backend.Interfaces;
using backend.Services;

var builder = WebApplication.CreateBuilder(args);

const string CorsPolicy = "AllowFrontend";

// CORS
var allowedOrigins = builder.Configuration.GetSection("AppSettings:AllowedOrigins").Get<string[]>() ?? [];
builder.Services.AddCors(options =>
{
    options.AddPolicy(CorsPolicy, policy =>
    {
        policy.WithOrigins(allowedOrigins)
              .AllowAnyHeader()
              .AllowAnyMethod();
    });
});

// Azure OpenAI client
builder.Services.AddSingleton(new AzureOpenAIClient(
    new Uri(builder.Configuration["AzureOpenAI:Endpoint"]!),
    new AzureKeyCredential(builder.Configuration["AzureOpenAI:ApiKey"]!)
));

builder.Services.AddScoped<IChatService, ChatService>();
builder.Services.AddControllers();

var app = builder.Build();

app.UseRouting();
app.UseCors(CorsPolicy);
app.MapControllers();

app.Run();
