# Build Troubleshooting

## Error: "Specify which project or solution file to use"

**Cause:** You're running the build script from the wrong directory.

**Solution:**
```powershell
# Navigate to the project folder first
cd C:\path\to\deviceagent

# Then run the script
.\build.ps1
```

### What the Script Expects

The `build.ps1` script must be run from the folder that contains:
- `Fourteen10.DeviceAgent.csproj` ✓
- `Program.cs` ✓
- `build.ps1` ✓
- `manage-service.ps1` ✓
- `appsettings.json` ✓

### Verify You're in the Right Place

```powershell
# Check if these files exist
dir Fourteen10.DeviceAgent.csproj
dir Program.cs
dir build.ps1

# Or view the current directory
Get-Location
```

---

## Error: "PowerShell script not found"

**Cause:** You extracted the files but didn't navigate to the folder.

**Solution:**
```powershell
# Wrong - file is not in current folder
C:\> .\build.ps1

# Right - navigate to the project folder first
C:\> cd deviceagent
C:\deviceagent\> .\build.ps1
```

---

## Error: "the file cannot be loaded because running scripts is disabled"

**Cause:** PowerShell execution policy blocks scripts.

**Solution:**
```powershell
# Option 1: Bypass for this session only (temporary)
powershell -ExecutionPolicy Bypass -File .\build.ps1

# Option 2: Run PowerShell as Administrator and set execution policy
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\build.ps1

# Option 2 Alternative: Use cmd.exe instead
cd C:\path\to\deviceagent
dotnet build Fourteen10.DeviceAgent.csproj -c Release
dotnet publish Fourteen10.DeviceAgent.csproj -c Release -r win-x64 --self-contained false
```

---

## Alternative: Build Without the Script

If the script doesn't work, you can build manually:

### Framework-Dependent (Small - ~5 MB)
```powershell
cd C:\path\to\deviceagent
dotnet build Fourteen10.DeviceAgent.csproj -c Release
dotnet publish Fourteen10.DeviceAgent.csproj -c Release -r win-x64 --self-contained false
```

### Self-Contained (Large - ~180 MB)
```powershell
cd C:\path\to\deviceagent
dotnet build Fourteen10.DeviceAgent.csproj -c Release
dotnet publish Fourteen10.DeviceAgent.csproj -c Release -r win-x64 --self-contained true
```

Output will be in: `bin\Release\net8.0\win-x64\publish\`

---

## Verification Checklist

- [ ] You're in the `deviceagent` folder
- [ ] `Fourteen10.DeviceAgent.csproj` exists in current folder
- [ ] .NET 8.0 SDK is installed (`dotnet --version` shows `8.0.x`)
- [ ] PowerShell is running as Administrator (for some commands)
- [ ] No antivirus is blocking `dotnet` commands

---

## Quick Validation

Run this to verify everything is set up correctly:

```powershell
# Check location
Get-Location

# Check project file exists
Test-Path Fourteen10.DeviceAgent.csproj

# Check .NET version
dotnet --version

# Try a simple build
dotnet build Fourteen10.DeviceAgent.csproj
```

---

## Still Having Issues?

1. **Run from Command Prompt instead:**
   ```cmd
   cd C:\path\to\deviceagent
   dotnet build Fourteen10.DeviceAgent.csproj -c Release
   dotnet publish Fourteen10.DeviceAgent.csproj -c Release -r win-x64
   ```

2. **Check for multiple project files:**
   ```powershell
   dir *.csproj  # Should show only one file
   dir *.sln     # Should show nothing or one file
   ```

3. **Clean build cache and try again:**
   ```powershell
   dotnet clean Fourteen10.DeviceAgent.csproj
   dotnet build Fourteen10.DeviceAgent.csproj -c Release
   ```

4. **Check .NET is installed for Windows x64:**
   ```powershell
   dotnet --info
   # Should show x64 as an installed RID
   ```
