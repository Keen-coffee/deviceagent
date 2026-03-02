# Fourteen10 Device Agent - Windows Service

A .NET 8.0 Windows Service that hosts a REST API providing device information.

## Features

- Runs as a Windows Service
- RESTful API endpoints available via HTTP and HTTPS
- **HTTP:** `http://127.0.0.1:12123` (localhost only)
- **HTTPS:** `https://127.0.0.1:12124` (configurable with local machine certificate)
- `/deviceinfo` endpoint returns system information
- `/health` endpoint for health checks
- Local network accessible (when HTTPS configured)
- Event Log integration for service monitoring
- Support for custom certificates from Windows certificate store or PFX files

## Prerequisites

- Windows OS (Windows 10, Windows Server 2016 or newer)
- Administrator privileges to install/uninstall the service

**For Framework-Dependent Deployment:**
- .NET 8.0 Runtime (download: https://dotnet.microsoft.com/download/dotnet/8.0)

**For Self-Contained Deployment:**
- No .NET installation required (included in package)

## Building the Project

**Make sure you're in the project directory first:**
```powershell
cd C:\path\to\deviceagent
```

### Option 1: Framework-Dependent (Recommended for Small Size)
Requires .NET 8.0 runtime installed on target machine (~5 MB output)

```powershell
# Using build script
.\build.ps1 -DeploymentType framework-dependent

# Or manually
dotnet publish Fourteen10.DeviceAgent.csproj -c Release -r win-x64 --self-contained false
```

### Option 2: Self-Contained (Recommended for Standalone)
Includes .NET runtime, no dependencies required (~150-200 MB output)

```powershell
# Using build script
.\build.ps1 -DeploymentType self-contained

# Or manually
dotnet publish Fourteen10.DeviceAgent.csproj -c Release -r win-x64 --self-contained true
```

### Quick Build (Default: Framework-Dependent)

```powershell
# Simplest option - builds framework-dependent release
.\build.ps1
```

> **Troubleshooting:** If you get an error about multiple projects, see [BUILD-TROUBLESHOOTING.md](BUILD-TROUBLESHOOTING.md)

## Installation as Windows Service

### Using SC Command (Recommended)
```bash
# Navigate to the publish directory
cd bin\Release\net8.0-windows\publish

# Install the service
sc create Fourteen10DeviceAgent binPath= "%CD%\Fourteen10.DeviceAgent.exe"

# Start the service
net start Fourteen10DeviceAgent

# Stop the service
net stop Fourteen10DeviceAgent

# Delete the service
sc delete Fourteen10DeviceAgent
```

### Using PowerShell (Requires Admin)
```powershell
$serviceName = "Fourteen10DeviceAgent"
$servicePath = "C:\path\to\Fourteen10.DeviceAgent.exe"

# Install
New-Service -Name $serviceName -BinaryPathName $servicePath -StartupType Automatic -DisplayName "Fourteen10 Device Agent"

# Start
Start-Service -Name $serviceName

# Stop
Stop-Service -Name $serviceName

# Remove
Remove-Service -Name $serviceName
```

## API Endpoints

### Device Information
**GET** `http://127.0.0.1:12123/deviceinfo` (HTTP - localhost only)  
**GET** `https://127.0.0.1:12124/deviceinfo` (HTTPS - from local network)

Response:
```json
{
  "computerName": "COMPUTER-NAME",
  "osVersion": "Microsoft Windows NT 10.0.22621.0",
  "processorCount": 8,
  "systemDirectory": "C:\\Windows\\System32",
  "timestamp": "2026-02-17T12:34:56.789Z",
  "isWindows": true,
  "osDescription": "Windows 10 21H2",
  "runtimeIdentifier": "win-x64",
  "frameWorkDescription": ".NET 8.0.0",
  "totalMemory": 1234567890
}
```

### Health Check
**GET** `http://127.0.0.1:12123/health` (HTTP - localhost only)  
**GET** `https://127.0.0.1:12124/health` (HTTPS - from local network)

Response:
```json
{
  "status": "healthy",
  "timestamp": "2026-02-17T12:34:56.789Z"
}
```

## Configuration

### Ports

- **HTTP:** 12123 (localhost only, for internal use)
- **HTTPS:** 12124 (configured for network access with certificate)

### Certificate Configuration

Edit `appsettings.json` to configure HTTPS certificate:

#### Development Mode (Default - Uses .NET Development Certificate)
```json
{
  "Certificate": {
    "Mode": "development"
  }
}
```

#### Windows Certificate Store Mode
```json
{
  "Certificate": {
    "Mode": "store",
    "StoreName": "My",
    "StoreLocation": "LocalMachine",
    "Thumbprint": "YOUR_CERTIFICATE_THUMBPRINT"
  }
}
```

#### PFX File Mode
```json
{
  "Certificate": {
    "Mode": "file",
    "FilePath": "C:\\path\\to\\certificate.pfx",
    "Password": "certificate_password"
  }
}
```

### Certificate Setup (Windows)

Use the provided PowerShell script to generate and configure a self-signed certificate:

```powershell
# Generate a self-signed certificate (Run as Administrator)
.\setup-certificate.ps1 -Action generate

# Bind certificate to port 12124
.\setup-certificate.ps1 -Action bind

# View certificate and binding information
.\setup-certificate.ps1 -Action info

# Remove certificate and binding
.\setup-certificate.ps1 -Action remove
```

### Logging

Edit `appsettings.json` to configure logging levels:

```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  }
}
```

Edit `appsettings.json` to configure:
- Logging levels
- CORS settings (currently only allows localhost)

## Logs

Service logs are written to:
- **Event Viewer** -> Windows Logs -> Application (when running as service)
- **Console** (when running in development)

## Running in Development

```bash
dotnet run
```

The service will listen on `http://127.0.0.1:12123`

## Troubleshooting

### Service Won't Start
- Check Event Viewer for detailed error messages
- Ensure the executable path is correct when installing
- Run command prompt as Administrator

### Port Already in Use
- Change port 12123 in `Program.cs` Kestrel configuration
- Port 12123 must be available on localhost

### Permission Denied
- Ensure running as Administrator
- Check that the service account has appropriate permissions

## Notes

- **HTTP:** Only listens on 127.0.0.1 (localhost) for security
- **HTTPS:** Listens on 0.0.0.0 (all interfaces) for network access, requires valid certificate
- API is accessible on localhost via HTTP, or from local network via HTTPS (with certificate configured)
- The service requires .NET 8.0 runtime
- For self-contained deployment, use the `--self-contained true` flag during publish
- HTTPS certificate must be configured before accessing from external servers
- Default HTTPS port is 12124 (to avoid conflicts with HTTP on 12123)

## Service Management

### Check Service Status
```bash
sc query Fourteen10DeviceAgent
```

### View Service Details
```bash
wmic service get name,displayname,state,startmode | findstr "Fourteen10"
```

### Set to Auto Start
```bash
sc config Fourteen10DeviceAgent start= auto
```

### Set to Manual Start
```bash
sc config Fourteen10DeviceAgent start= demand
```
