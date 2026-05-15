---
description: CS2 DMA Project Build Guide
alwaysApply: false
---

# CS2 DMA Project Build Guide

## Prerequisites

### 1. Visual Studio 2022
- Install Visual Studio 2022 Community or Professional
- Workload: **Desktop development with C++**
- Individual components:
  - MSVC v143 - VS 2022 C++ x64/x86 build tools
  - Windows 10 SDK (10.0.19041.0 or later)
  - C++ ATL for latest v143 build tools (x86 & x64) - **Optional**, not required after removing atlconv.h

### 2. DirectX SDK (June 2010)
- Download from Microsoft: https://www.microsoft.com/en-us/download/details.aspx?id=6812
- Install to default path: `C:\Program Files (x86)\Microsoft DirectX SDK (June 2010)`
- Required for D3DX11.lib and DirectX headers

### 3. DMA Libraries
The following DLLs must be placed in the same directory as the built executable:
- `FTD3XX.dll` - FTDI driver library
- `leechcore.dll` - DMA core library
- `vmm.dll` - Virtual memory manager

### 4. Runtime Data Files
Place these files alongside the executable:
- `offsets.json` - From [cs2-dumper](https://github.com/a2x/cs2-dumper/blob/main/output/offsets.json)
- `client_dll.json` - From [cs2-dumper](https://github.com/a2x/cs2-dumper/blob/main/output/client_dll.json)

## Build Commands

### Command Line (MSBuild)

```powershell
# Find MSBuild path
$msbuild = & "C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe" -latest -products * -requires Microsoft.Component.MSBuild -find MSBuild\**\Bin\MSBuild.exe

# Build Stable Release x64 (no telemetry)
& $msbuild "c:\CS2-DMA\dma.slnx" /p:Configuration=Release /p:Platform=x64 /t:Rebuild /m

# Build Beta Release x64 (with telemetry, upload logs to GitHub)
& $msbuild "c:\CS2-DMA\cs2\Dll1.vcxproj" /p:Configuration=ReleaseBeta /p:Platform=x64 /t:Rebuild /m
```

> **Note**: ReleaseBeta must be built directly from the vcxproj (not slnx) because the slnx format does not support custom configuration mapping.

### Visual Studio IDE
1. Open `c:\CS2-DMA\dma.slnx`
2. Select configuration: **Release** (stable) or **ReleaseBeta** (beta with telemetry)
3. Select platform: **x64**
4. Build menu -> Rebuild Solution

## Output

| Configuration | Executable | Intermediate | Version |
|---------------|-----------|--------------|--------|
| Release | `c:\CS2-DMA\cs2.exe` | `build\Release\x64\` | `1.1.0` |
| ReleaseBeta | `c:\CS2-DMA\cs2beta.exe` | `build\ReleaseBeta\x64\` | 由 version.json 定义 |

## Project Configuration

| Setting | Release | ReleaseBeta |
|---------|---------|-------------|
| Configuration Type | Application (.exe) | Application (.exe) |
| Platform Toolset | v143 (VS 2022) | v143 (VS 2022) |
| C++ Standard | C++17 | C++17 |
| Character Set | Multi-Byte | Multi-Byte |
| Whole Program Optimization | Yes | Yes |
| SubSystem | Console | Console |
| BETA_TELEMETRY | ❌ | ✅ |
| PROJECT_VERSION | 由 version.json 定义 | 由 version.json 定义 |

## Key Include Paths

- `$(ProjectDir)SDK\Include` - DirectX SDK headers (bundled)
- `C:\Program Files (x86)\Microsoft DirectX SDK (June 2010)\Include` - External DirectX SDK

## Key Library Paths

- `$(ProjectDir)SDK\Lib\x64` - leechcore.lib, vmm.lib (bundled)
- `C:\Program Files (x86)\Microsoft DirectX SDK (June 2010)\Lib\x64` - External DirectX SDK

## Linked Libraries

- `leechcore.lib` - DMA core functions
- `vmm.lib` - Virtual memory manager
- `D3DX11.lib` - DirectX utilities
- `Normaliz.lib`, `wldap32.lib`, `crypt32.lib`, `Ws2_32.lib` - Windows networking

## Common Build Errors

### 1. `atlconv.h: No such file or directory`
- **Cause**: ATL library not installed
- **Fix**: Already fixed by removing the unused include in `ProcessManager.hpp`

### 2. `D3DX11.lib: No such file or directory`
- **Cause**: DirectX SDK not installed
- **Fix**: Install DirectX SDK (June 2010)

### 3. `C1041: cannot open program database vc143.pdb`
- **Cause**: PDB file locked by another process
- **Fix**: Kill any running `cl.exe` processes, then rebuild

### 4. Character encoding warnings (CP936)
- **Cause**: Source files contain characters that cannot be represented in Chinese code page
- **Impact**: Warning only, does not affect build
- **Fix**: Save files as UTF-8 with BOM (optional)

## Clean Build

```powershell
# Clean and rebuild stable
Remove-Item -Path "c:\CS2-DMA\build\Release\x64\*.pdb" -Force -ErrorAction SilentlyContinue
& $msbuild "c:\CS2-DMA\dma.slnx" /p:Configuration=Release /p:Platform=x64 /t:Rebuild /m

# Clean and rebuild beta
Remove-Item -Path "c:\CS2-DMA\build\ReleaseBeta\x64\*.pdb" -Force -ErrorAction SilentlyContinue
& $msbuild "c:\CS2-DMA\cs2\Dll1.vcxproj" /p:Configuration=ReleaseBeta /p:Platform=x64 /t:Rebuild /m
```

## Deployment Checklist

After successful build, ensure these files are in the deployment directory:

- [ ] `cs2.exe` - Main executable
- [ ] `FTD3XX.dll` - FTDI driver
- [ ] `leechcore.dll` - DMA core
- [ ] `vmm.dll` - Memory manager
- [ ] `offsets.json` - Game offsets
- [ ] `client_dll.json` - Client offsets
