# Fourteen10 Device Agent - Deployment Guide

## Overview

The Fourteen10 Device Agent is a Windows Service that runs an ASP.NET Core API on `http://127.0.0.1:12123`. It provides device information endpoints and is designed for localhost-only access.

**Project Name:** Fourteen10 Device Agent  
**API Port:** 12123  
**Access:** 127.0.0.1 (localhost only)  
**Service Name:** Fourteen10DeviceAgent  
**Framework:** .NET 8.0

## Project Structure

```
deviceagent/
├── Controllers/
│   └── DeviceInfoController.cs       # API endpoints
├── Properties/
│   └── launchSettings.json           # Launch configuration
├── Fourteen10.DeviceAgent.csproj    # Project file
├── Program.cs                        # Service setup & configuration
├── appsettings.json                 # Configuration settings
├── appsettings.Development.json     # Development overrides
├── manage-service.ps1               # Service management script
├── README.md                        # Quick reference
└── DEPLOYMENT.md                    # This file
```

## Building the Project

### Deployment Type Comparison

Choose based on your needs:

| Aspect | Framework-Dependent | Self-Contained |
|--------|-------------------|-----------------|
| **Output Size** | ~5 MB | ~150-200 MB |
| **.NET Runtime** | Required (install separately) | Included |
| **Installation** | 2 steps (install .NET + app) | 1 step (just copy) |
| **Security Updates** | Automatic from Windows | Manual (republish) |
| **Portability** | Less portable | More portable |
| **Use Case** | Enterprise/managed systems | Standalone/offline systems |

### Option 1: Framework-Dependent (Recommended for Most)

**Smaller output, requires .NET 8.0 runtime on target.**

```powershell
# Using build script (recommended)
.\build.ps1 -DeploymentType framework-dependent

# Or manually
dotnet publish -c Release -r win-x64 --self-contained false
```

**Target Setup:**
1. Install .NET 8.0 Runtime: https://dotnet.microsoft.com/download/dotnet/8.0
2. Copy published files
3. Run `.\manage-service.ps1 -Action install`

### Option 2: Self-Contained (Recommended for Standalone)

**Larger output, includes .NET runtime, no dependencies needed.**

```powershell
# Using build script (recommended)
.\build.ps1 -DeploymentType self-contained

# Or manually
dotnet publish -c Release -r win-x64 --self-contained true
```

**Target Setup:**
1. Copy published files (includes everything)
2. Run `.\manage-service.ps1 -Action install`

### Using the Build Script

Easiest way to build with all options:

```powershell
# Build framework-dependent (default, smallest)
.\build.ps1

# Build self-contained (standalone, largest)
.\build.ps1 -DeploymentType self-contained

# Build debug configuration
.\build.ps1 -Configuration Debug

# Combine options
.\build.ps1 -DeploymentType self-contained -Configuration Release
```

## Installation on Windows

### Prerequisites

**For Framework-Dependent Deployment:**
- Windows 10/11 or Windows Server 2016+
- .NET 8.0 Runtime installed: https://dotnet.microsoft.com/download/dotnet/8.0
- Administrator privileges

**For Self-Contained Deployment:**
- Windows 10/11 or Windows Server 2016+
- Administrator privileges
- **No .NET installation required** (included in package)

### Method 1: PowerShell Script (Recommended)

1. Copy the published files to your desired location (e.g., `C:\Services\Fourteen10DeviceAgent\`)
2. Copy `manage-service.ps1` to the same directory
3. Open PowerShell as Administrator
4. Navigate to the service directory
5. Run: `.\manage-service.ps1 -Action install`
6. Run: `.\manage-service.ps1 -Action start`

### Method 2: Manual SC Command

```powershell
# As Administrator
$exePath = "C:\Services\Fourteen10DeviceAgent\Fourteen10.DeviceAgent.exe"
sc create Fourteen10DeviceAgent binPath= "$exePath" start= auto DisplayName= "Fourteen10 Device Agent"
net start Fourteen10DeviceAgent
```

### Method 3: Using NSSM (Non-Sucking Service Manager)

Download NSSM from: https://nssm.cc/download

```bash
nssm install "Fourteen10DeviceAgent" "C:\Services\Fourteen10DeviceAgent\Fourteen10.DeviceAgent.exe"
nssm set "Fourteen10DeviceAgent" AppDirectory "C:\Services\Fourteen10DeviceAgent"
nssm start "Fourteen10DeviceAgent"
```

## Managing the Service

### PowerShell Script Commands

```powershell
# Check if service is installed and running
.\manage-service.ps1 -Action status

# Start the service
.\manage-service.ps1 -Action start

# Stop the service
.\manage-service.ps1 -Action stop

# Restart the service
.\manage-service.ps1 -Action restart

# Uninstall the service
.\manage-service.ps1 -Action uninstall
```

### Using Windows Services Manager

1. Press `Win+R`, type `services.msc`, and press Enter
2. Find "Fourteen10 Device Agent" in the list
3. Right-click to start, stop, restart, or access properties

### Using Command Line

```bash
# Check status
sc query Fourteen10DeviceAgent

# Start
net start Fourteen10DeviceAgent

# Stop
net stop Fourteen10DeviceAgent

# Restart
net stop Fourteen10DeviceAgent
net start Fourteen10DeviceAgent

# Delete service
net stop Fourteen10DeviceAgent
sc delete Fourteen10DeviceAgent
```

## API Testing

### Using PowerShell

```powershell
# Get device info
Invoke-WebRequest -Uri "http://127.0.0.1:12123/deviceinfo" | ConvertFrom-Json

# Health check
Invoke-WebRequest -Uri "http://127.0.0.1:12123/health" | ConvertFrom-Json
```

### Using cURL

```bash
# Get device info
curl http://127.0.0.1:12123/deviceinfo

# Health check
curl http://127.0.0.1:12123/health
```

### Using Swagger UI (Development)

When running in Development mode with Swagger enabled:
- Navigate to: `http://127.0.0.1:12123/swagger/index.html`

## Example Response

### /deviceinfo

```json
{
  "computerName": "MYCOMPUTER",
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

### /health

```json
{
  "status": "healthy",
  "timestamp": "2026-02-17T12:34:56.789Z"
}
```

## Configuration

### Environment Variables

Edit service properties to set environment variables:

```
ASPNETCORE_ENVIRONMENT=Production
```

### Configuration Files

Edit `appsettings.json` in the service directory to configure:

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

## Logging

### Event Viewer (When Running as Service)

1. Open Event Viewer (`eventvwr.msc`)
2. Navigate to **Windows Logs** → **Application**
3. Filter events by Source: "Fourteen10DeviceAgent"

### Console Output (When Running Manually)

Logs are written to the console window if run interactively.

## Troubleshooting

### Service Won't Start

1. Check Event Viewer for error messages
2. Verify .NET 8.0 runtime is installed: `dotnet --version`
3. Ensure the executable path is correct in the service configuration
4. Check port 12123 is not in use: `netstat -ano | findstr 12123`

### Port 12123 Already in Use

Find what's using the port:
```powershell
Get-NetTCPConnection -LocalPort 12123 | Select-Object -Property State, OwningProcess
Get-Process -Id <PID>
```

To change the port, edit `Program.cs` and recompile.

### Permissions Issues

- Run Command Prompt/PowerShell as Administrator
- Ensure the service account has read/write permissions to the service directory

### .NET Runtime Not Found

Install .NET 8.0 Runtime:
```powershell
# Check installed versions
dotnet --list-runtimes

# If .NET 8.0 is missing, download and install from:
# https://dotnet.microsoft.com/download/dotnet/8.0
```

## Security Considerations

- ✅ **Localhost Only:** API only listens on 127.0.0.1 for security
- ✅ **No Authentication:** Should only be accessible on localhost
- ⚠️ **Device Information:** Endpoint returns system information - appropriate for internal use only
- ⚠️ **Firewall:** Ensure Windows Firewall rules don't expose the port externally

## Performance Notes

- Minimal memory footprint (~50-100 MB at rest)
- CPU usage minimal when idle
- Responses typically < 10ms

## Updating the Service

1. Stop the service: `net stop Fourteen10DeviceAgent`
2. Backup the current installation folder
3. Replace the executable and DLL files with new version
4. Restart the service: `net start Fourteen10DeviceAgent`

## Uninstallation

```powershell
# Using PowerShell script
.\manage-service.ps1 -Action uninstall

# Or manually
net stop Fourteen10DeviceAgent
sc delete Fourteen10DeviceAgent
```

Delete the service directory afterward.

## Support & Troubleshooting

- Check the [README.md](README.md) for quick reference
- Review Event Viewer logs for detailed error information
- Verify configuration in `appsettings.json`
- Test API endpoints directly from localhost

## Next Steps

1. ✅ Build project: `dotnet publish -c Release -r win-x64`
2. ✅ Copy published files to target Windows machine
3. ✅ Run `manage-service.ps1 -Action install` as Administrator
4. ✅ Start service: `manage-service.ps1 -Action start`
5. ✅ Test endpoint: `curl http://127.0.0.1:12123/deviceinfo`
