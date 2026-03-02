# HTTPS Setup Guide

## Overview

The Fourteen10 Device Agent supports HTTPS for secure communication from your dashboard on other servers. This guide covers certificate setup and configuration.

## Quick Start

### On Windows (Deployment Target)

```powershell
# 1. Run PowerShell as Administrator
# 2. Navigate to service directory
cd "C:\Services\Fourteen10DeviceAgent"

# 3. Generate a self-signed certificate
.\setup-certificate.ps1 -Action generate

# 4. View certificate information and thumbprint
.\setup-certificate.ps1 -Action info

# 5. Update appsettings.json with the thumbprint (see Configuration section below)

# 6. Bind to port 12124
.\setup-certificate.ps1 -Action bind

# 7. Restart the service
.\manage-service.ps1 -Action restart

# 8. Test HTTPS endpoint (ignore certificate warning for self-signed)
Invoke-WebRequest -Uri https://127.0.0.1:12124/deviceinfo -SkipCertificateCheck | ConvertFrom-Json
```

## Certificate Options

### Option 1: Self-Signed Certificate (Recommended for Lab/Internal Use)

**Pros:**
- Free and easy to set up
- No external dependencies
- Good for internal dashboards
- Can be generated and replaced as needed

**Cons:**
- Browser/client warnings about untrusted certificate
- Must use `-SkipCertificateCheck` or disable cert validation in client

**Setup:**
```powershell
# As Administrator
.\setup-certificate.ps1 -Action generate
.\setup-certificate.ps1 -Action bind
```

### Option 2: Enterprise Certificate (Production)

**Pros:**
- Trusted by operating system
- No client-side certificate warnings
- Professional setup

**Cons:**
- Requires enterprise CA
- Certificate management overhead
- Renewal process required

**Setup:**
1. Request certificate from your enterprise CA with Subject: `CN=Fourteen10-LocalServer`
2. Ensure certificate includes DNS names: `localhost`, `127.0.0.1`, computer name
3. Import certificate to LocalMachine\My store
4. Get thumbprint and update configuration (see Configuration section)

### Option 3: Let's Encrypt (Only if externally accessible)

**Note:** Only suitable if your internal server is somehow exposed to the internet

1. Use Certbot or similar ACME client
2. Place certificate in PFX format
3. Configure as "file" mode in appsettings.json

## Configuration

### Step 1: Generate/Obtain Certificate

Using the setup script (self-signed):
```powershell
.\setup-certificate.ps1 -Action generate
.\setup-certificate.ps1 -Action info
```

Note the **Thumbprint** value (e.g., `1A2B3C4D5E6F7G8H9I0J...`)

### Step 2: Update appsettings.json

Navigate to your service directory and update `appsettings.json`:

**For Windows Certificate Store:**
```json
{
  "Certificate": {
    "Mode": "store",
    "StoreName": "My",
    "StoreLocation": "LocalMachine",
    "Thumbprint": "1A2B3C4D5E6F7G8H9I0J1K2L3M4N5O6P7Q8R9S0T"
  }
}
```

**For PFX File:**
```json
{
  "Certificate": {
    "Mode": "file",
    "FilePath": "C:\\Services\\Fourteen10DeviceAgent\\certificate.pfx",
    "Password": "your-certificate-password"
  }
}
```

### Step 3: Bind Certificate to Port

```powershell
# As Administrator
.\setup-certificate.ps1 -Action bind
```

Or manually using netsh:
```powershell
$thumbprint = "1A2B3C4D5E6F7G8H9I0J1K2L3M4N5O6P7Q8R9S0T"
$guid = [guid]::NewGuid().ToString("B")
netsh http add sslcert ipport=0.0.0.0:12124 certhash=$thumbprint appid=$guid
```

### Step 4: Restart Service

```powershell
.\manage-service.ps1 -Action restart
```

## Accessing from Dashboard

### PowerShell (Local Machine)

```powershell
# HTTP (local access only)
Invoke-WebRequest http://127.0.0.1:12123/deviceinfo | ConvertFrom-Json

# HTTPS (from network, ignoring cert warning)
Invoke-WebRequest -Uri https://devicename:12124/deviceinfo -SkipCertificateCheck | ConvertFrom-Json
```

### PowerShell (Remote Machine - With Self-Signed Certificate)

```powershell
# Ignore certificate validation (for self-signed certs)
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
$result = Invoke-WebRequest https://your-device:12124/deviceinfo
$result.Content | ConvertFrom-Json
```

### C# / .NET Client

```csharp
// For self-signed certificates
var handler = new HttpClientHandler();
handler.ServerCertificateCustomValidationCallback = (msg, cert, chain, errors) => true;

using var client = new HttpClient(handler);
var response = await client.GetAsync("https://your-device:12124/deviceinfo");
var json = await response.Content.ReadAsStringAsync();
```

### Python Client

```python
import requests
import urllib3
from urllib3.exceptions import InsecureRequestWarning

# Suppress SSL warnings
urllib3.disable_warnings(InsecureRequestWarning)

# For self-signed certificates
response = requests.get(
    "https://your-device:12124/deviceinfo",
    verify=False  # Ignore SSL certificate verification
)
data = response.json()
print(data)
```

### JavaScript/Node.js Client

```javascript
// With node-fetch
const fetch = require('node-fetch');
const https = require('https');

// For self-signed certificates
const agent = new https.Agent({
  rejectUnauthorized: false
});

fetch('https://your-device:12124/deviceinfo', { agent })
  .then(res => res.json())
  .then(data => console.log(data));
```

## Troubleshooting

### Certificate Shows as Untrusted

**Cause:** Self-signed certificate not in trusted store  
**Solution:** This is expected for self-signed certificates. Use `-SkipCertificateCheck` or disable validation in your client

### Port 12124 Already in Use

```powershell
# Find what's using the port
Get-NetTCPConnection -LocalPort 12124 | Select-Object -Property State, OwningProcess, OffsetCreationTime
Get-Process -Id <PID>

# Free the port (kill the process or change certificate port)
Stop-Process -Id <PID> -Force
```

### Certificate Not Found in Store

```powershell
# List all certificates in LocalMachine\My store
Get-ChildItem Cert:\LocalMachine\My | Format-Table -AutoSize

# Verify thumbprint matches exactly (no spaces or extra characters)
```

### HTTPS Endpoint Not Responding

1. Check certificate is installed:
   ```powershell
   .\setup-certificate.ps1 -Action info
   ```

2. Check port binding:
   ```powershell
   netsh http show sslcert
   ```

3. Check service is running:
   ```powershell
   .\manage-service.ps1 -Action status
   ```

4. Check Event Viewer for errors

### Service Won't Start After HTTPS Config

1. Verify `appsettings.json` syntax is valid JSON
2. Check certificate thumbprint is correct
3. Verify certificate exists in Windows store
4. Check service logs in Event Viewer

## Certificate Renewal

### For Self-Signed Certificates

```powershell
# Remove old certificate
.\setup-certificate.ps1 -Action remove

# Generate new certificate
.\setup-certificate.ps1 -Action generate

# Bind to port
.\setup-certificate.ps1 -Action bind

# Restart service
.\manage-service.ps1 -Action restart
```

### For Enterprise Certificates

1. Obtain new certificate from CA
2. Import to LocalMachine\My store
3. Get new thumbprint
4. Update `appsettings.json` with new thumbprint
5. Restart service

## Security Considerations

✅ **HTTPS Encryption:** All data encrypted in transit  
✅ **Authentication:** Configure firewalls to restrict access to your network  
✅ **Certificate Pinning:** Consider implementing certificate pinning in your dashboard  
⚠️ **Self-Signed Certs:** Vulnerable to MITM if not distributed securely  
⚠️ **Private Key:** Never share the private key or PFX password  
⚠️ **Firewall:** Ensure Windows Firewall rules are properly configured

## Firewall Configuration

### Allow HTTPS Traffic (Windows Firewall)

```powershell
# Add inbound rule for HTTPS on port 12124
New-NetFirewallRule -DisplayName "Fourteen10 Device Agent HTTPS" `
    -Direction Inbound -Action Allow -Protocol tcp -LocalPort 12124
```

## DNS Configuration

If accessing from other machines on the network, consider:

1. **Using IP Address:** `https://192.168.x.x:12124/deviceinfo`
2. **Using Computer Name:** `https://computer-name:12124/deviceinfo` (requires DNS resolution)
3. **Using Certificate CN:** Ensure certificate's CN matches the hostname used

## Common Access Patterns

### Pattern 1: Local Service (Same Machine)

```
HTTP:  http://127.0.0.1:12123/deviceinfo
HTTPS: https://127.0.0.1:12124/deviceinfo
```

### Pattern 2: Network Dashboard (Different Machine)

```
HTTPS: https://computer-name:12124/deviceinfo
   or
HTTPS: https://192.168.x.x:12124/deviceinfo
```

### Pattern 3: Hybrid (Both)

```
Local (low-overhead):   http://127.0.0.1:12123/deviceinfo
Network (secure):       https://computer-name:12124/deviceinfo
```

## See Also

- [README.md](README.md) - Main documentation
- [DEPLOYMENT.md](DEPLOYMENT.md) - Deployment guide
- [QUICKSTART.md](QUICKSTART.md) - Quick start instructions
