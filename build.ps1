param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("framework-dependent", "self-contained")]
    [string]$DeploymentType = "framework-dependent",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("Release", "Debug")]
    [string]$Configuration = "Release"
)

$projectFile = "Fourteen10.DeviceAgent.csproj"

# Validate we're in the correct directory
if (-not (Test-Path $projectFile)) {
    Write-Host "Error: Project file not found!" -ForegroundColor Red
    Write-Host "Make sure you're in the project directory (deviceagent folder)" -ForegroundColor Yellow
    Write-Host "Current location: $(Get-Location)" -ForegroundColor Cyan
    exit 1
}

Write-Host "=== Fourteen10 Device Agent - Build Script ===" -ForegroundColor Cyan
Write-Host "Location: $(Get-Location)" -ForegroundColor Cyan
Write-Host "Deployment Type: $DeploymentType" -ForegroundColor Yellow
Write-Host "Configuration: $Configuration" -ForegroundColor Yellow
Write-Host ""

$selfContained = if ($DeploymentType -eq "self-contained") { "true" } else { "false" }

Write-Host "Building project..." -ForegroundColor Green
dotnet build $projectFile -c $Configuration

if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Publishing project..." -ForegroundColor Green

$publishArgs = @(
    "publish"
    $projectFile
    "-c", $Configuration
    "-r", "win-x64"
    "--self-contained", $selfContained
)

dotnet @publishArgs

if ($LASTEXITCODE -ne 0) {
    Write-Host "Publish failed!" -ForegroundColor Red
    exit 1
}

$publishPath = ".\bin\$Configuration\net8.0\win-x64\publish"
$sizeInfo = [math]::Round((Get-ChildItem $publishPath -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB, 2)

Write-Host ""
Write-Host "✓ Build successful!" -ForegroundColor Green
Write-Host "Output location: $publishPath" -ForegroundColor Cyan
Write-Host "Output size: ~$sizeInfo MB" -ForegroundColor Cyan
Write-Host ""

if ($DeploymentType -eq "self-contained") {
    Write-Host "This is a SELF-CONTAINED deployment." -ForegroundColor Green
    Write-Host "✓ Includes .NET 8.0 runtime" -ForegroundColor Green
    Write-Host "✓ No .NET installation required on target machine" -ForegroundColor Green
    Write-Host "Ready to copy and run on any Windows x64 machine!" -ForegroundColor Green
}
else {
    Write-Host "This is a FRAMEWORK-DEPENDENT deployment." -ForegroundColor Yellow
    Write-Host "⚠ Requires .NET 8.0 runtime installed on target machine" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To install .NET 8.0 runtime on target:" -ForegroundColor Cyan
    Write-Host "1. Visit: https://dotnet.microsoft.com/download/dotnet/8.0" -ForegroundColor White
    Write-Host "2. Download: .NET 8.0 Runtime" -ForegroundColor White
    Write-Host "3. Run installer and reboot if prompted" -ForegroundColor White
}

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Copy files from: $publishPath" -ForegroundColor White
Write-Host "2. Run on Windows: .\manage-service.ps1 -Action install" -ForegroundColor White
Write-Host "3. Start service: .\manage-service.ps1 -Action start" -ForegroundColor White
