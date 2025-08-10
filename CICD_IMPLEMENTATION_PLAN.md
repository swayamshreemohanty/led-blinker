# F Prime LED Blinker - Complete CI/CD Implementation Plan

## Project Overview

**Project**: F Prime LED Blinker for Raspberry Pi deployment  
**Repository**: led-blinker (GitLab)  
**Owner**: swayamshreemohanty  
**Target Platform**: Raspberry Pi 4/5 (ARM64)  
**Framework**: NASA F Prime

## Project Requirements & Decisions Made

### 1. Target Platform

- **Primary**: Raspberry Pi 4/5 (ARM64 Cortex-A72)
- **Architecture**: aarch64 (ARM64)
- **OS**: Raspberry Pi OS (64-bit)

### 2. GPIO Requirements

- **Current Usage**: LED blinking via GPIO
- **GPIO Library**: F Prime's built-in GPIO drivers with pigpio backend (recommended)
- **Hardware**: LED connected to GPIO pin (configurable, default GPIO 18)

### 3. CI/CD Strategy Decisions

- **Approach**: Native cross-compilation (NO Docker)
- **Reason**: Aerospace/satellite compliance requirements
- **Toolchain**: GCC ARM64 cross-compiler
- **Build Type**: Static linking for standalone deployment

### 4. Release Strategy

- **Versioning**: Semantic Versioning (MAJOR.MINOR.PATCH)
- **Automatic Releases**: Yes
  - Git tags → Stable releases (v1.2.3)
  - Master branch commits → Development builds (v1.2.3-dev.abc123)
- **Service Management**: Systemd service (aerospace standard)

### 5. Deployment Package Requirements

- **Format**: Complete deployment package (not just binary)
- **Contents**: Binary + config + scripts + documentation
- **Installation**: One-command deployment (`sudo ./install.sh`)
- **Service**: Auto-start systemd service with security hardening

## Current Project Structure

```
led-blinker/
├── CMakeLists.txt
├── CMakePresets.json
├── project.cmake
├── README.md
├── settings.ini
├── Components/
│   └── Led/
│       ├── CMakeLists.txt
│       ├── Led.cpp              # GPIO LED control implementation
│       ├── Led.fpp
│       ├── Led.hpp
│       └── docs/sdd.md
├── LedBlinker/
│   ├── CMakeLists.txt
│   ├── Main.cpp                 # Main F Prime application
│   ├── README.md
│   └── Top/
│       ├── CMakeLists.txt
│       ├── instances.fpp
│       ├── LedBlinkerPackets.xml
│       ├── LedBlinkerTopology.cpp
│       ├── LedBlinkerTopology.hpp
│       ├── LedBlinkerTopologyDefs.hpp
│       └── topology.fpp
└── lib/
    ├── README.md
    └── fprime/                  # F Prime framework submodule
```

## F Prime Implementation Details

### LED Component (`Components/Led/Led.cpp`)

- **GPIO Control**: Uses `gpioSet_out()` for LED control
- **State Management**: Tracks LED state (ON/OFF)
- **Blinking Logic**: Configurable blink interval via parameters
- **Commands**: `BLINKING_ON_OFF_cmdHandler()` for remote control
- **Telemetry**: Reports LED state and transitions

### Main Application (`LedBlinker/Main.cpp`)

- **Entry Point**: Standard F Prime main with CLI argument parsing
- **Network**: Supports hostname/IP and port configuration
- **Signal Handling**: Graceful shutdown on SIGINT/SIGTERM

## Complete CI/CD Pipeline Design

### Pipeline Architecture

```
┌─────────────┐    ┌──────────────┐    ┌─────────────┐    ┌──────────────┐
│   Source    │ -> │ Cross-Compile│ -> │  Package    │ -> │   Release    │
│   Code      │    │  (x86->ARM64)│    │  Creation   │    │  Deployment  │
└─────────────┘    └──────────────┘    └─────────────┘    └──────────────┘
      │                     │                   │                 │
   git push           ARM64 binary         .tar.gz          GitLab Release
```

### Pipeline Stages (Detailed)

#### Stage 1: Setup Environment

**Purpose**: Install F Prime tools and ARM64 cross-compilation toolchain
**Duration**: 3-5 minutes
**Tools Installed**:

- Ubuntu 22.04 base system
- GCC ARM64 cross-compiler (11.4.0)
- CMake (3.22.1)
- Python 3.9+ with F Prime tools (3.4.3)
- Build tools (ninja, pkg-config)

#### Stage 2: Code Validation

**Purpose**: Validate F Prime project structure
**Duration**: 1-2 minutes
**Checks**:

- F Prime project integrity (`fprime-util info`)
- FPP file validation
- CMake configuration verification

#### Stage 3: Cross-Compilation Build

**Purpose**: Build ARM64 binary for Raspberry Pi
**Duration**: 5-10 minutes
**Process**:

- Configure with ARM64 toolchain
- Build with Cortex-A72 optimizations
- Generate `LedBlinker` executable
- Verify ARM64 architecture

#### Stage 4: Binary Testing

**Purpose**: Verify binary integrity
**Duration**: 1 minute
**Tests**:

- Binary exists and executable
- ARM64 architecture verification
- SHA256 checksum generation

#### Stage 5: Package Creation

**Purpose**: Create deployment package
**Duration**: 2-3 minutes
**Package Contents**:

```
led-blinker-v1.2.3-rpi4/
├── bin/LedBlinker              # ARM64 executable
├── config/LedBlinkerPackets.xml
├── scripts/
│   ├── install.sh
│   ├── uninstall.sh
│   ├── start.sh
│   ├── stop.sh
│   └── led-blinker.service
├── docs/DEPLOYMENT.md
└── verification/LedBlinker.sha256
```

#### Stage 6: Release Creation

**Purpose**: Create GitLab releases
**Triggers**:

- Git tags: Stable releases
- Master commits: Development builds

## Implementation Files Needed

### 1. Core CI/CD Files

- `.gitlab-ci.yml` - Main CI/CD pipeline
- `cmake/rpi4-native-toolchain.cmake` - ARM64 cross-compilation toolchain
- Updated `CMakePresets.json` - Add RPI4 preset

### 2. Deployment Scripts

- `scripts/install.sh` - One-command installation with security
- `scripts/uninstall.sh` - Complete removal script
- `scripts/start.sh` - Manual start script
- `scripts/stop.sh` - Stop script
- `scripts/led-blinker.service` - Systemd service with security hardening

### 3. Documentation

- `docs/DEPLOYMENT.md` - Complete deployment guide
- `docs/CICD.md` - CI/CD pipeline documentation

## Key Technical Specifications

### Cross-Compilation Configuration

```cmake
# Toolchain: cmake/rpi4-native-toolchain.cmake
CMAKE_SYSTEM_NAME=Linux
CMAKE_SYSTEM_PROCESSOR=aarch64
CMAKE_C_COMPILER=aarch64-linux-gnu-gcc
CMAKE_CXX_COMPILER=aarch64-linux-gnu-g++

# Optimization flags for Raspberry Pi 4/5
CPU_FLAGS="-mcpu=cortex-a72 -mtune=cortex-a72"
OPTIMIZATION_FLAGS="-O3 -DNDEBUG -ffast-math"
SECURITY_FLAGS="-fstack-protector-strong -D_FORTIFY_SOURCE=2"
LINKING_FLAGS="-static-libgcc -static-libstdc++"
```

### CMake Preset Addition

```json
{
  "name": "fprime-rpi4-native",
  "displayName": "F´ Raspberry Pi 4/5 Native Cross-Compile",
  "binaryDir": "${sourceDir}/build-rpi4-native",
  "toolchainFile": "${sourceDir}/cmake/rpi4-native-toolchain.cmake",
  "cacheVariables": {
    "CMAKE_BUILD_TYPE": "Release",
    "FPRIME_ENABLE_AUTOCODER_UTS": "OFF",
    "FPRIME_ENABLE_FRAMEWORK_UTS": "OFF",
    "BUILD_TESTING": "OFF"
  }
}
```

### GitLab CI Variables

```yaml
variables:
  FPRIME_VERSION: "3.4.3"
  CMAKE_VERSION: "3.22.1"
  GCC_VERSION: "11.4.0"
  BUILD_TYPE: "Release"
  TARGET_ARCH: "aarch64"
  PROJECT_NAME: "led-blinker"
```

## Deployment Workflow for Team Members

### 1. Download Release

```bash
# From GitLab releases
wget https://gitlab.com/yourcompany/led-blinker/-/releases/v1.2.3/downloads/led-blinker-v1.2.3-rpi4.tar.gz
```

### 2. Deploy to Raspberry Pi

```bash
# Transfer to Pi
scp led-blinker-v1.2.3-rpi4.tar.gz pi@192.168.1.100:~

# Extract and install
tar -xzf led-blinker-v1.2.3-rpi4.tar.gz
cd led-blinker-v1.2.3-rpi4/
sudo ./scripts/install.sh

# Service is now running automatically
sudo systemctl status led-blinker
```

### 3. Connect with F Prime GDS

```bash
fprime-gds -n --ip <raspberry-pi-ip> --port 50050
```

## Security & Aerospace Compliance Features

### Build Security

- **Deterministic builds**: Fixed tool versions
- **Static linking**: Minimal runtime dependencies
- **Checksum verification**: Binary integrity validation
- **No Docker**: Direct toolchain for compliance

### Deployment Security

- **Dedicated user**: Service runs as `fprime` user
- **Systemd hardening**: Security restrictions applied
- **GPIO-only access**: Limited system permissions
- **Sandboxed execution**: Restricted filesystem access

### Service Security Configuration

```ini
[Service]
User=fprime
Group=fprime
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/var/log/fprime /dev/gpiomem /sys/class/gpio
PrivateTmp=true
```

## Benefits of This Approach

### For Development Team

✅ **One-command deployment**: `sudo ./install.sh`  
✅ **Automatic releases**: No manual intervention  
✅ **Consistent builds**: Same binary for everyone  
✅ **Production-ready**: Proper service management

### For Aerospace/Satellite Use

✅ **Native performance**: No virtualization overhead  
✅ **Deterministic**: Fixed tool versions  
✅ **Compliant**: Meets aerospace standards  
✅ **Secure**: Hardened deployment

### For Operations

✅ **Auto-start**: Service starts on boot  
✅ **Health monitoring**: Systemd status tracking  
✅ **Log management**: Centralized logging  
✅ **Easy rollback**: Version management

## Next Steps for Implementation

### Phase 1: Core Infrastructure (Priority 1)

1. Create `.gitlab-ci.yml` with complete pipeline
2. Create ARM64 cross-compilation toolchain
3. Update CMakePresets.json with RPI4 preset
4. Test basic cross-compilation locally

### Phase 2: Deployment Scripts (Priority 2)

1. Create installation script with security features
2. Create systemd service configuration
3. Create start/stop management scripts
4. Create uninstallation script

### Phase 3: Documentation (Priority 3)

1. Create deployment guide for team members
2. Create CI/CD pipeline documentation
3. Create troubleshooting guide
4. Create release notes template

### Phase 4: Testing & Validation (Priority 4)

1. Test complete pipeline end-to-end
2. Validate deployment on actual Raspberry Pi
3. Test GPIO functionality
4. Verify service management

## Troubleshooting Guide for Implementation

### Common Issues Expected

#### Cross-Compilation Issues

- **Missing ARM64 tools**: Ensure `gcc-aarch64-linux-gnu` installed
- **Library conflicts**: Use static linking
- **Architecture mismatch**: Verify `aarch64` target

#### F Prime Issues

- **Virtual environment**: Ensure fprime-venv activated
- **FPP errors**: Validate .fpp model files
- **Dictionary generation**: Check autocoder output

#### Deployment Issues

- **GPIO permissions**: User must be in `gpio` group
- **Service failures**: Check systemd logs
- **Network binding**: Verify port availability

## Questions for Next AI Implementation

1. **GitLab Configuration**: Private GitLab instance or GitLab.com?
2. **Runner Type**: Docker runners available or shell runners?
3. **GPIO Pin**: Which GPIO pin is LED connected to? (default: GPIO 18)
4. **Network Settings**: Default IP/port for F Prime GDS connection?
5. **Custom Requirements**: Any additional F Prime components needed?

## Files Status

### ✅ Analyzed

- `CMakeLists.txt` - Root build configuration
- `CMakePresets.json` - Build presets (needs RPI4 addition)
- `Components/Led/Led.cpp` - GPIO LED control implementation
- `LedBlinker/Main.cpp` - Main application entry point

### ❌ Need Creation

- `.gitlab-ci.yml` - Complete CI/CD pipeline
- `cmake/rpi4-native-toolchain.cmake` - Cross-compilation toolchain
- `scripts/install.sh` - Installation automation
- `scripts/uninstall.sh` - Removal automation
- `scripts/led-blinker.service` - Systemd service
- `scripts/start.sh` - Manual start script
- `scripts/stop.sh` - Stop script
- `docs/DEPLOYMENT.md` - Deployment guide
- `docs/CICD.md` - Pipeline documentation

This document provides complete context for the next AI model to implement the remaining CI/CD infrastructure without losing any of the decisions and technical specifications we've discussed.
