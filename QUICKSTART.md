# Quick Start Guide

## 1. Build the Project

**Make sure you're in the project directory** (`deviceagent` folder)

### Option A: Small Size (Framework-Dependent - Requires .NET on Target)
```powershell
cd C:\path\to\deviceagent
.\build.ps1 -DeploymentType framework-dependent
# Output: ~5 MB
```

### Option B: Standalone (Self-Contained - No .NET Required)
```powershell
cd C:\path\to\deviceagent
.\build.ps1 -DeploymentType self-contained
# Output: ~150-200 MB
```

### Option C: Default (Framework-Dependent)
```powershell
cd C:\path\to\deviceagent
.\build.ps1
```

Output will be in: `bin/Release/net8.0/win-x64/publish/`

## 2. Copy to Windows Machine

Copy the entire `publish` folder to your Windows machine, e.g., `C:\Services\Fourteen10DeviceAgent\`

Also copy:
- `manage-service.ps1`
- `setup-certificate.ps1`
- `appsettings.json`
- `appsettings.Development.json`

## 3. Set Up HTTPS (Optional but Recommended)

Run PowerShell as Administrator:

```powershell
cd "C:\Services\Fourteen10DeviceAgent"

# Generate self-signed certificate
.\setup-certificate.ps1 -Action generate

# View certificate info and get thumbprint
.\setup-certificate.ps1 -Action info

# Bind certificate to port 12124
.\setup-certificate.ps1 -Action bind
```

Then update `appsettings.json` with the certificate thumbprint from the info output:

```json
{
  "Certificate": {
    "Mode": "store",
    "StoreName": "My",
    "StoreLocation": "LocalMachine",
    "Thumbprint": "YOUR_THUMBPRINT_HERE"
  }
}
```

## 4. Install as Service (Run PowerShell as Administrator)

```powershell
cd "C:\Services\Fourteen10DeviceAgent"

# Install service
.\manage-service.ps1 -Action install

# Start service
.\manage-service.ps1 -Action start
```

## 5. Test the API

```powershell
# HTTP endpoint (local only)
Invoke-WebRequest http://127.0.0.1:12123/deviceinfo | ConvertFrom-Json

# HTTPS endpoint (if configured)
Invoke-WebRequest https://127.0.0.1:12124/deviceinfo -SkipCertificateCheck | ConvertFrom-Json
```

## Available PowerShell Commands

### Service Management
```powershell
.\manage-service.ps1 -Action install      # Install service
.\manage-service.ps1 -Action start        # Start service
.\manage-service.ps1 -Action stop         # Stop service
.\manage-service.ps1 -Action restart      # Restart service
.\manage-service.ps1 -Action status       # Show service status
.\manage-service.ps1 -Action uninstall    # Remove service
```

### Certificate Management
```powershell
.\setup-certificate.ps1 -Action generate  # Generate self-signed cert
.\setup-certificate.ps1 -Action bind      # Bind cert to port 12124
.\setup-certificate.ps1 -Action info      # Show cert info and thumbprint
.\setup-certificate.ps1 -Action remove    # Remove cert and binding
```

## API Endpoints

- **HTTP Device Info:** `GET http://127.0.0.1:12123/deviceinfo`
- **HTTP Health Check:** `GET http://127.0.0.1:12123/health`
- **HTTPS Device Info:** `GET https://127.0.0.1:12124/deviceinfo` (when configured)
- **HTTPS Health Check:** `GET https://127.0.0.1:12124/health` (when configured)

## Accessing from Dashboard (Remote Machine)

```powershell
# Using certificate thumbprint verification bypass (self-signed)
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

# For self-signed certificates:
$result = Invoke-WebRequest https://computer-name:12124/deviceinfo
$data = $result.Content | ConvertFrom-Json
```

## Documentation Files

| File | Purpose |
|------|---------|
| **README.md** | Features, API reference, overview |
| **DEPLOYMENT.md** | Detailed deployment, troubleshooting, service management |
| **HTTPS-SETUP.md** | Complete HTTPS configuration guide |
| **QUICKSTART.md** | This file - fast setup instructions |

## See Also

- [HTTPS-SETUP.md](HTTPS-SETUP.md) - Complete HTTPS certificate setup
- [README.md](README.md) - Feature details and API reference
- [DEPLOYMENT.md](DEPLOYMENT.md) - Full deployment guide
- [Controllers/DeviceInfoController.cs](Controllers/DeviceInfoController.cs) - API implementation
