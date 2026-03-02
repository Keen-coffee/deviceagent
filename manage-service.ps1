param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("install", "uninstall", "start", "stop", "restart", "status")]
    [string]$Action = "install"
)

# Requires admin privileges
#Requires -RunAsAdministrator

$serviceName = "Fourteen10DeviceAgent"
$displayName = "Fourteen10 Device Agent"
$serviceExePath = Join-Path $PSScriptRoot "bin\Release\net8.0-windows\publish\Fourteen10.DeviceAgent.exe"

function Test-Admin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Admin)) {
    Write-Host "Error: This script must be run as Administrator" -ForegroundColor Red
    exit 1
}

function Install-Service {
    if (Get-Service $serviceName -ErrorAction SilentlyContinue) {
        Write-Host "Service already exists. Uninstalling first..." -ForegroundColor Yellow
        Uninstall-Service
        Start-Sleep -Seconds 2
    }

    if (-not (Test-Path $serviceExePath)) {
        Write-Host "Error: Service executable not found at $serviceExePath" -ForegroundColor Red
        Write-Host "Please build the project first: dotnet publish -c Release -r win-x64" -ForegroundColor Yellow
        exit 1
    }

    Write-Host "Installing service: $displayName" -ForegroundColor Green
    New-Service -Name $serviceName -BinaryPathName $serviceExePath -StartupType Automatic -DisplayName $displayName -ErrorAction Stop
    Write-Host "Service installed successfully" -ForegroundColor Green
}

function Uninstall-Service {
    $service = Get-Service $serviceName -ErrorAction SilentlyContinue
    if ($service) {
        if ($service.Status -eq "Running") {
            Write-Host "Stopping service..." -ForegroundColor Yellow
            Stop-Service -Name $serviceName -Force
            Start-Sleep -Seconds 1
        }
        Write-Host "Removing service..." -ForegroundColor Green
        Remove-Service -Name $serviceName -Force
        Write-Host "Service uninstalled successfully" -ForegroundColor Green
    }
    else {
        Write-Host "Service not found" -ForegroundColor Yellow
    }
}

function Start-ServiceIfNotRunning {
    $service = Get-Service $serviceName -ErrorAction SilentlyContinue
    if ($service) {
        if ($service.Status -ne "Running") {
            Write-Host "Starting service..." -ForegroundColor Green
            Start-Service -Name $serviceName
            Start-Sleep -Seconds 2
            Write-Host "Service started" -ForegroundColor Green
        }
        else {
            Write-Host "Service is already running" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "Service not found. Install it first using: .\manage-service.ps1 -Action install" -ForegroundColor Red
    }
}

function Stop-ServiceIfRunning {
    $service = Get-Service $serviceName -ErrorAction SilentlyContinue
    if ($service -and $service.Status -eq "Running") {
        Write-Host "Stopping service..." -ForegroundColor Green
        Stop-Service -Name $serviceName -Force
        Start-Sleep -Seconds 1
        Write-Host "Service stopped" -ForegroundColor Green
    }
    else {
        Write-Host "Service is not running" -ForegroundColor Yellow
    }
}

function Restart-ServiceIfExists {
    $service = Get-Service $serviceName -ErrorAction SilentlyContinue
    if ($service) {
        Write-Host "Restarting service..." -ForegroundColor Green
        Restart-Service -Name $serviceName
        Start-Sleep -Seconds 2
        Write-Host "Service restarted" -ForegroundColor Green
    }
    else {
        Write-Host "Service not found" -ForegroundColor Red
    }
}

function Get-ServiceStatus {
    $service = Get-Service $serviceName -ErrorAction SilentlyContinue
    if ($service) {
        Write-Host "Service: $displayName" -ForegroundColor Cyan
        Write-Host "Name: $serviceName" -ForegroundColor Cyan
        Write-Host "Status: $($service.Status)" -ForegroundColor $(if ($service.Status -eq "Running") { "Green" } else { "Yellow" })
        Write-Host "Startup Type: $($service.StartType)" -ForegroundColor Cyan
        Write-Host "API: http://127.0.0.1:12123/deviceinfo" -ForegroundColor Cyan
    }
    else {
        Write-Host "Service not found" -ForegroundColor Red
    }
}

switch ($Action) {
    "install" { Install-Service }
    "uninstall" { Uninstall-Service }
    "start" { Start-ServiceIfNotRunning }
    "stop" { Stop-ServiceIfRunning }
    "restart" { Restart-ServiceIfExists }
    "status" { Get-ServiceStatus }
    default { Write-Host "Unknown action: $Action" -ForegroundColor Red }
}
