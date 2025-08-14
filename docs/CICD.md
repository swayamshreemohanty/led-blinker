# F Prime LED Blinker CI/CD Pipeline Documentation

## Overview

This document describes the automated CI/CD pipeline for the F Prime LED Blinker project, which builds ARM64 binaries for Raspberry Pi deployment.

## Pipeline Architecture

```
┌─────────────┐    ┌──────────────┐    ┌─────────────┐    ┌──────────────┐
│   Source    │ -> │ Cross-Compile│ -> │  Package    │ -> │   Release    │
│   Code      │    │  (x86->ARM64)│    │  Creation   │    │  Creation    │
└─────────────┘    └──────────────┘    └─────────────┘    └──────────────┘
```

## Pipeline Stages

### 1. Prepare (1-2 minutes)
- **Purpose**: Validate F Prime project structure
- **Actions**: 
  - Install cross-compilation toolchain
  - Setup F Prime environment (version 3.6.1)
  - Run `fprime-util info` validation
- **Triggers**: All branches and tags

### 2. Build (5-8 minutes)
- **Purpose**: Cross-compile ARM64 binary for Raspberry Pi
- **Actions**:
  - Configure with ARM64 toolchain (`cmake --preset fprime-rpi4-native`)
  - Build with Cortex-A72 optimizations
  - Verify binary architecture with `file` command
- **Output**: ARM64 `LedBlinker` executable + F Prime dictionaries
- **Triggers**: All branches and tags

### 3. Package (2-3 minutes)
- **Purpose**: Create deployment-ready bundle
- **Actions**:
  - Bundle binary, configs, scripts, documentation
  - Generate installation scripts with security hardening
  - Create checksums for verification
- **Output**: `led-blinker-vX.Y.Z-rpi4.tar.gz`
- **Triggers**: Master branch and tags only

### 4. Release (30 seconds)
- **Purpose**: Create GitLab Release with assets
- **Actions**:
  - Create release notes with installation instructions
  - Attach deployment tarball and checksums
- **Triggers**: Tags only (e.g., v1.0.0)

## Deployment Package Contents

The release tarball contains everything needed for deployment:

```
led-blinker-v1.0.0-rpi4/
├── bin/
│   └── LedBlinker                    # ARM64 executable
├── config/
│   └── LedBlinkerPackets.xml         # F Prime dictionaries
├── scripts/
│   ├── install.sh                    # Main installer
│   ├── uninstall.sh                  # Removal script
│   ├── start.sh                      # Manual start
│   ├── stop.sh                       # Manual stop
│   └── led-blinker.service           # Systemd service
├── docs/
│   └── DEPLOYMENT.md                 # Team instructions
└── verification/
    ├── checksums.sha256              # All file checksums
    └── LedBlinker.sha256             # Binary checksum
```

## Triggering Pipelines

### Branch Pushes
```bash
git push origin feature/new-feature
```
- **Runs**: prepare + build stages only
- **Purpose**: Fast feedback during development
- **Duration**: ~6-10 minutes
- **Artifacts**: Binary (expires in 1 week)

### Master Branch
```bash
git push origin master
```
- **Runs**: prepare + build + package stages
- **Purpose**: Create development artifacts
- **Duration**: ~8-13 minutes
- **Artifacts**: Development package with `-dev.sha` suffix

### Release Tags
```bash
git tag v1.0.0
git push origin v1.0.0
```
- **Runs**: All stages (prepare + build + package + release)
- **Purpose**: Create stable release
- **Duration**: ~8-14 minutes
- **Artifacts**: Release package + GitLab Release

## Team Deployment Workflow

### 1. Download Release
Navigate to GitLab project → Releases → Download tarball:
```bash
wget https://gitlab.com/yourproject/led-blinker/-/releases/v1.0.0/downloads/led-blinker-v1.0.0-rpi4.tar.gz
```

### 2. Transfer to Raspberry Pi
```bash
scp led-blinker-v1.0.0-rpi4.tar.gz pi@192.168.1.100:~
```

### 3. Install on Pi
```bash
ssh pi@192.168.1.100
tar -xzf led-blinker-v1.0.0-rpi4.tar.gz
cd led-blinker-v1.0.0-rpi4/
sudo ./scripts/install.sh
```

### 4. Verify Installation
```bash
sudo systemctl status led-blinker
sudo journalctl -u led-blinker -f
```

### 5. Connect F Prime GDS
From development machine:
```bash
fprime-gds -n --ip 192.168.1.100 --port 50050
```

## Configuration

### GitLab CI Variables
Set in GitLab project settings if customization needed:

| Variable | Default | Description |
|----------|---------|-------------|
| `FPRIME_VERSION` | `3.6.1` | F Prime tools version |
| `GPIO_PIN` | `13` | LED GPIO pin number |
| `BUILD_TYPE` | `Release` | CMake build type |

### Cross-compilation Toolchain
- **Target**: `aarch64-linux-gnu` (ARM64)
- **CPU**: Cortex-A72 (Raspberry Pi 4/5)
- **Optimizations**: `-O3 -ffast-math -mcpu=cortex-a72`
- **Security**: Stack protection, fortify source
- **Linking**: Static libgcc/libstdc++ for portability

## Security Features

### Build Security
- **Deterministic builds**: Fixed tool versions
- **Checksum verification**: SHA256 for all files
- **Static linking**: Minimal runtime dependencies

### Deployment Security
- **Systemd hardening**: NoNewPrivileges, ProtectSystem
- **User isolation**: Runs as `pi` user with limited permissions
- **GPIO-only access**: Restricted to `/dev/gpiomem` and `/sys/class/gpio`
- **Private temp**: Isolated temporary directories

## Monitoring and Logs

### Service Status
```bash
sudo systemctl status led-blinker
```

### Real-time Logs
```bash
sudo journalctl -u led-blinker -f
```

### Log Location
- **Systemd Journal**: `journalctl -u led-blinker`
- **Application Logs**: `/var/log/fprime/` (if configured)

## Troubleshooting

### Common Build Issues

**Pipeline fails at prepare stage:**
- Check F Prime project structure with `fprime-util info`
- Verify CMakeLists.txt and .fpp files are valid

**Cross-compilation fails:**
- Check if all source files compile on native platform first
- Verify ARM64 toolchain installation in CI image

**Package creation fails:**
- Ensure binary exists in expected build directory
- Check file permissions and paths in packaging script

### Common Deployment Issues

**Service won't start:**
```bash
sudo journalctl -u led-blinker
# Check for permission or GPIO access issues
```

**GPIO permissions:**
```bash
# Ensure user is in gpio group
sudo usermod -a -G gpio pi
# Check GPIO device permissions
ls -l /dev/gpiomem
```

**Network connectivity:**
```bash
# Test F Prime GDS connection
telnet <pi-ip> 50050
# Check firewall settings
sudo ufw status
```

## Pipeline Optimization

### Reducing Build Time
- Use CMake build caching (future enhancement)
- Parallel compilation with `-j$(nproc)`
- Ninja generator for faster builds

### Reducing CI Minutes Usage
- Skip package stage for feature branches
- Use pipeline rules to avoid unnecessary runs
- Cache F Prime virtual environment (future)

## Version Management

### Semantic Versioning
- **Major** (1.0.0): Breaking changes to F Prime interface
- **Minor** (1.1.0): New features, backward compatible
- **Patch** (1.0.1): Bug fixes only

### Development Builds
- **Format**: `dev-<short-sha>` (e.g., `dev-a1b2c3d4`)
- **Trigger**: Master branch pushes
- **Purpose**: Testing unreleased features

## Future Enhancements

### Planned Features
- **Multi-architecture**: Support ARM32 and x86_64
- **Hardware-in-loop testing**: Automated Pi testing
- **SBOM generation**: Software bill of materials
- **Security scanning**: Static analysis integration
- **Performance benchmarking**: Automated performance tests

### Infrastructure Improvements
- **Build caching**: Speed up repeat builds
- **Artifact registry**: Centralized package storage
- **Deployment environments**: Staging and production
- **Rollback capability**: Easy version rollbacks
