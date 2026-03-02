using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Server.Kestrel.Core;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using System;
using System.IO;
using System.Net;
using System.Security.Cryptography.X509Certificates;

var builder = WebApplication.CreateBuilder(args);

// Configure services
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policyBuilder =>
    {
        policyBuilder
            .WithOrigins("http://127.0.0.1:12123", "https://127.0.0.1:12124", "https://localhost:12124", "https://home.frontiertoyota.com")
            .AllowAnyMethod()
            .AllowAnyHeader();
    });
});

// Configure Kestrel
builder.WebHost.UseKestrel(options =>
{
    options.Listen(IPAddress.Loopback, 12123, listenOptions =>
    {
        listenOptions.Protocols = HttpProtocols.Http1AndHttp2;
    });

    var certificateConfig = builder.Configuration.GetSection("Certificate");
    try
    {
        var certificate = LoadCertificate(certificateConfig);
        if (certificate != null)
        {
            options.Listen(IPAddress.Any, 12124, listenOptions =>
            {
                listenOptions.Protocols = HttpProtocols.Http1AndHttp2;
                listenOptions.UseHttps(certificate);
            });
            Console.WriteLine("HTTPS configured on port 12124");
        }
    }
    catch (Exception ex)
    {
        Console.WriteLine($"Warning: Failed to configure HTTPS: {ex.Message}. HTTPS endpoint will not be available.");
    }
});

// Use Windows service if applicable
builder.Host.UseWindowsService();

var app = builder.Build();

// Configure the HTTP request pipeline
if (app.Environment.IsDevelopment())
{
    app.UseDeveloperExceptionPage();
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseRouting();
app.UseCors();

app.MapControllers();

Console.WriteLine("Fourteen10 Device Agent starting...");
Console.WriteLine($"HTTP endpoint: http://127.0.0.1:12123");
Console.WriteLine($"HTTPS endpoint: https://127.0.0.1:12124");

await app.RunAsync();

// Helper method to load certificate from Windows certificate store or file
static X509Certificate2? LoadCertificate(IConfigurationSection certificateConfig)
{
    var certificateMode = certificateConfig.GetValue<string>("Mode", "development") ?? "development";
    
    if (certificateMode.Equals("store", StringComparison.OrdinalIgnoreCase))
    {
        // Load from Windows certificate store
        var storeName = certificateConfig.GetValue<string>("StoreName") ?? "My";
        var storeLocation = certificateConfig.GetValue<StoreLocation>("StoreLocation", StoreLocation.LocalMachine);
        var thumbprint = certificateConfig.GetValue<string>("Thumbprint");

        if (string.IsNullOrEmpty(thumbprint))
        {
            throw new InvalidOperationException("Certificate thumbprint must be specified when using store mode.");
        }

        var store = new X509Store(storeName, storeLocation);
        store.Open(OpenFlags.ReadOnly);
        
        var certs = store.Certificates.Find(X509FindType.FindByThumbprint, thumbprint, false);
        store.Close();

        if (certs.Count == 0)
        {
            throw new InvalidOperationException($"Certificate with thumbprint {thumbprint} not found in {storeLocation}\\{storeName}");
        }

        return certs[0];
    }
    else if (certificateMode.Equals("file", StringComparison.OrdinalIgnoreCase))
    {
        // Load from PFX file
        var certificatePath = certificateConfig.GetValue<string>("FilePath");
        var password = certificateConfig.GetValue<string>("Password");

        if (string.IsNullOrEmpty(certificatePath))
        {
            throw new InvalidOperationException("Certificate file path must be specified when using file mode.");
        }

        if (!File.Exists(certificatePath))
        {
            throw new InvalidOperationException($"Certificate file not found: {certificatePath}");
        }

        return new X509Certificate2(certificatePath, password);
    }
    else
    {
        // Development mode - use .NET development certificate
        return null; // Kestrel will use the development certificate automatically
    }
}
