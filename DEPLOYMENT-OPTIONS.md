# Deployment Options Summary

## Quick Answer

**Yes, .NET dependencies can be included in the build** by using `--self-contained true`.

You have two options:

## Option 1: Framework-Dependent (Recommended Default)

✅ **Requires .NET 8.0 runtime installed on target machine**

```powershell
# On your build machine:
.\build.ps1 -DeploymentType framework-dependent

# Or manually:
dotnet publish -c Release -r win-x64 --self-contained false
```

**Output Size:** ~5 MB  
**Target Machine Setup:**
1. Install .NET 8.0 Runtime (70-100 MB download)
2. Copy published files
3. Run `.\manage-service.ps1 -Action install`

**Best For:**
- Enterprise environments
- Corporate networks
- When storage/bandwidth is limited
- When you want automatic security updates from Windows

---

## Option 2: Self-Contained 

✅ **Includes .NET runtime, NO dependencies to install**

```powershell
# On your build machine:
.\build.ps1 -DeploymentType self-contained

# Or manually:
dotnet publish -c Release -r win-x64 --self-contained true
```

**Output Size:** ~150-200 MB  
**Target Machine Setup:**
1. Copy published files (includes .NET runtime)
2. Run `.\manage-service.ps1 -Action install`

**Best For:**
- Standalone/remote servers
- Air-gapped environments
- Quick deployments
- Offline installations
- When you want predictable versions

---

## Comparison Table

| Factor | Framework-Dependent | Self-Contained |
|--------|-------------------|-----------------|
| Output Size | ~5 MB | ~150-200 MB |
| .NET Included | ❌ No | ✅ Yes |
| Target Setup | 2 steps | 1 step |
| Installation Time | Longer (DL runtime) | Shorter |
| Security Updates | Automatic | Manual |
| Works Offline | ❌ No | ✅ Yes |
| Portable | ❌ Less | ✅ More |
| Production Grade | ✅ Yes | ✅ Yes |

---

## How to Use the Build Script

**Make sure you're in the project directory first:**

```powershell
cd C:\path\to\deviceagent  # Navigate to the project folder
```

### Default (Framework-Dependent)
```powershell
.\build.ps1
```

### Self-Contained
```powershell
.\build.ps1 -DeploymentType self-contained
```

### Debug Build
```powershell
.\build.ps1 -Configuration Debug
```

### Combine Options
```powershell
.\build.ps1 -DeploymentType self-contained -Configuration Release
```

The script will:
- ✅ Build the project
- ✅ Publish for Windows x64
- ✅ Show output location
- ✅ Display final size
- ✅ Provide next steps

---

## .NET Runtime Installation (For Framework-Dependent)

If you choose framework-dependent, the target machine needs .NET 8.0 Runtime:

1. **Download:** https://dotnet.microsoft.com/download/dotnet/8.0
2. **Select:** Windows x64 (Installer)
3. **Install** and reboot if prompted
4. **Verify:** Open PowerShell and run `dotnet --version`

---

## File Locations After Build

```
deviceagent/
├── bin/Release/net8.0/win-x64/publish/    ← Framework-dependent (~5 MB)
└── bin/Release/net8.0/win-x64/publish/    ← Self-contained (~150-200 MB)
```

Both use the same output path. The script automatically selects what to include based on your choice.

---

## Recommendation

**For most scenarios: Use Framework-Dependent**
- Smaller downloads
- Easier distribution
- Automatic security updates
- Standard enterprise approach

**Use Self-Contained if:**
- Target server has no internet
- You need a completely standalone package
- You want to lock specific .NET version
- You're deploying to many isolated systems

---

## Next Steps

1. **Build with your preferred option:**
   ```powershell
   .\build.ps1 -DeploymentType self-contained  # or framework-dependent
   ```

2. **Copy files to Windows machine**

3. **Install service:**
   ```powershell
   cd C:\Services\Fourteen10DeviceAgent
   .\manage-service.ps1 -Action install
   .\manage-service.ps1 -Action start
   ```

4. **Test:**
   ```powershell
   Invoke-WebRequest http://127.0.0.1:12123/deviceinfo | ConvertFrom-Json
   ```

---

## Questions?

- **Build fails?** Run `dotnet clean` then try again
- **Port already in use?** Change port in `appsettings.json` and rebuild
- **Service won't start?** Check Event Viewer → Windows Logs → Application
- **Can't connect?** Make sure service is running: `.\manage-service.ps1 -Action status`
