param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("generate", "bind", "info", "remove")]
    [string]$Action = "info"
)

# Requires admin privileges
#Requires -RunAsAdministrator

$serviceName = "Fourteen10DeviceAgent"
$certificateSubject = "CN=Fourteen10-LocalServer"
$storeLocation = "Cert:\LocalMachine\My"
$port = 12124

function Test-Admin {
    $currentUser = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Admin)) {
    Write-Host "Error: This script must be run as Administrator" -ForegroundColor Red
    exit 1
}

function Generate-Certificate {
    Write-Host "Generating self-signed certificate..." -ForegroundColor Green
    
    # Check if certificate already exists
    $existingCert = Get-ChildItem $storeLocation | Where-Object { $_.Subject -eq $certificateSubject } | Select-Object -First 1
    
    if ($existingCert) {
        Write-Host "Certificate already exists: $($existingCert.Thumbprint)" -ForegroundColor Yellow
        Write-Host "Subject: $($existingCert.Subject)" -ForegroundColor Cyan
        Write-Host "Expires: $($existingCert.NotAfter)" -ForegroundColor Cyan
        $response = Read-Host "Do you want to replace it? (y/n)"
        if ($response -ne 'y' -and $response -ne 'Y') {
            Write-Host "Certificate generation cancelled" -ForegroundColor Yellow
            return $existingCert.Thumbprint
        }
        # Remove old certificate
        Remove-Item $existingCert.PSPath
        Write-Host "Old certificate removed" -ForegroundColor Green
    }

    try {
        $newCert = New-SelfSignedCertificate `
            -CertStoreLocation $storeLocation `
            -Subject $certificateSubject `
            -DnsName "localhost", "127.0.0.1", $env:COMPUTERNAME `
            -KeyUsage DigitalSignature, KeyEncipherment `
            -EKU "Server Authentication" `
            -NotAfter (Get-Date).AddYears(10) `
            -ErrorAction Stop

        Write-Host "Certificate generated successfully!" -ForegroundColor Green
        Write-Host "Thumbprint: $($newCert.Thumbprint)" -ForegroundColor Cyan
        Write-Host "Subject: $($newCert.Subject)" -ForegroundColor Cyan
        Write-Host "Expires: $($newCert.NotAfter)" -ForegroundColor Cyan
        
        return $newCert.Thumbprint
    }
    catch {
        Write-Host "Error generating certificate: $_" -ForegroundColor Red
        return $null
    }
}

function Bind-Certificate {
    Write-Host "Binding certificate to port $port..." -ForegroundColor Green
    
    # Get certificate thumbprint
    $cert = Get-ChildItem $storeLocation | Where-Object { $_.Subject -eq $certificateSubject } | Select-Object -First 1
    
    if (-not $cert) {
        Write-Host "Error: Certificate not found. Run with -Action generate first." -ForegroundColor Red
        return
    }

    $thumbprint = $cert.Thumbprint
    Write-Host "Using certificate: $thumbprint" -ForegroundColor Cyan

    try {
        # Remove existing binding for the port
        $existing = netsh http show sslcert ipport=0.0.0.0:$port 2>$null
        if ($existing -and $existing -match "Certificate Hash") {
            Write-Host "Removing existing binding..." -ForegroundColor Yellow
            netsh http delete sslcert ipport=0.0.0.0:$port
        }

        # Create new binding
        $guid = [guid]::NewGuid().ToString("B")
        netsh http add sslcert ipport=0.0.0.0:$port certhash=$thumbprint appid=$guid
        
        Write-Host "Certificate bound successfully!" -ForegroundColor Green
        Write-Host "Port: $port" -ForegroundColor Cyan
        Write-Host "Certificate Hash: $thumbprint" -ForegroundColor Cyan
        Write-Host "Application GUID: $guid" -ForegroundColor Cyan
    }
    catch {
        Write-Host "Error binding certificate: $_" -ForegroundColor Red
    }
}

function Show-CertificateInfo {
    Write-Host "=== Certificate Information ===" -ForegroundColor Cyan
    
    $cert = Get-ChildItem $storeLocation | Where-Object { $_.Subject -eq $certificateSubject } | Select-Object -First 1
    
    if ($cert) {
        Write-Host "Status: FOUND" -ForegroundColor Green
        Write-Host "Thumbprint: $($cert.Thumbprint)" -ForegroundColor White
        Write-Host "Subject: $($cert.Subject)" -ForegroundColor White
        Write-Host "Issued: $($cert.NotBefore)" -ForegroundColor White
        Write-Host "Expires: $($cert.NotAfter)" -ForegroundColor White
        Write-Host "DNS Names: $($cert.DnsNameList -join ', ')" -ForegroundColor White
    }
    else {
        Write-Host "Status: NOT FOUND" -ForegroundColor Yellow
        Write-Host "Run: .\setup-certificate.ps1 -Action generate" -ForegroundColor Cyan
    }

    Write-Host "`n=== Port Binding Information ===" -ForegroundColor Cyan
    $binding = netsh http show sslcert ipport=0.0.0.0:$port 2>$null
    if ($binding -and $binding -match "Certificate Hash") {
        Write-Host "Status: BOUND to port $port" -ForegroundColor Green
        $binding | ForEach-Object { 
            if ($_ -match "Certificate Hash\s*:\s*(.+)") {
                Write-Host "Bound Certificate: $($Matches[1])" -ForegroundColor White
            }
        }
    }
    else {
        Write-Host "Status: NOT BOUND to port $port" -ForegroundColor Yellow
        Write-Host "Run: .\setup-certificate.ps1 -Action bind" -ForegroundColor Cyan
    }

    Write-Host "`n=== Configuration ===" -ForegroundColor Cyan
    Write-Host "To use this certificate, update appsettings.json:" -ForegroundColor Cyan
    Write-Host @"
{
  "Certificate": {
    "Mode": "store",
    "StoreName": "My",
    "StoreLocation": "LocalMachine",
    "Thumbprint": "$($cert.Thumbprint)"
  }
}
"@ -ForegroundColor White
}

function Remove-Certificate {
    Write-Host "Removing certificate binding and certificate..." -ForegroundColor Green
    
    try {
        # Remove binding
        $binding = netsh http show sslcert ipport=0.0.0.0:$port 2>$null
        if ($binding -and $binding -match "Certificate Hash") {
            Write-Host "Removing port binding..." -ForegroundColor Yellow
            netsh http delete sslcert ipport=0.0.0.0:$port
            Write-Host "Binding removed" -ForegroundColor Green
        }

        # Remove certificate
        $cert = Get-ChildItem $storeLocation | Where-Object { $_.Subject -eq $certificateSubject } | Select-Object -First 1
        if ($cert) {
            Write-Host "Removing certificate..." -ForegroundColor Yellow
            Remove-Item $cert.PSPath -Force
            Write-Host "Certificate removed" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "Error removing certificate: $_" -ForegroundColor Red
    }
}

switch ($Action) {
    "generate" { Generate-Certificate | Out-Null }
    "bind" { Bind-Certificate }
    "info" { Show-CertificateInfo }
    "remove" { Remove-Certificate }
    default { Write-Host "Unknown action: $Action" -ForegroundColor Red }
}
