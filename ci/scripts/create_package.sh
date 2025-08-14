#!/bin/bash
# create_package.sh - Creates deployment package for F Prime LED Blinker
# Usage: ./create_package.sh <tag> <sha>

set -e  # Exit on any error

TAG=${1:-"dev"}
SHA=${2:-"unknown"}
PROJECT_NAME="led-blinker"
TARGET_ARCH="rpi4"
BUILD_DIR="build-rpi4-native"

echo "=== Creating F Prime LED Blinker Deployment Package ==="
echo "Tag: $TAG"
echo "SHA: $SHA"

# Create version string
if [[ "$TAG" == "dev" ]]; then
    VERSION="dev-${SHA:0:8}"
    PACKAGE_NAME="${PROJECT_NAME}-${VERSION}-${TARGET_ARCH}"
else
    VERSION="$TAG"
    PACKAGE_NAME="${PROJECT_NAME}-${VERSION}-${TARGET_ARCH}"
fi

echo "Package: $PACKAGE_NAME"

# Create package directory structure
PACKAGE_DIR="dist/$PACKAGE_NAME"
mkdir -p "$PACKAGE_DIR"
mkdir -p "$PACKAGE_DIR/bin"
mkdir -p "$PACKAGE_DIR/config"
mkdir -p "$PACKAGE_DIR/scripts"
mkdir -p "$PACKAGE_DIR/docs"
mkdir -p "$PACKAGE_DIR/verification"

echo "✅ Created package directory structure"

# Copy binary
if [[ -f "$BUILD_DIR/LedBlinker/LedBlinker" ]]; then
    cp "$BUILD_DIR/LedBlinker/LedBlinker" "$PACKAGE_DIR/bin/"
    chmod +x "$PACKAGE_DIR/bin/LedBlinker"
    echo "✅ Copied ARM64 binary"
else
    echo "❌ Error: LedBlinker binary not found in $BUILD_DIR/LedBlinker/"
    exit 1
fi

# Copy F Prime dictionaries and config
if [[ -f "$BUILD_DIR/LedBlinker/LedBlinkerPackets.xml" ]]; then
    cp "$BUILD_DIR/LedBlinker/LedBlinkerPackets.xml" "$PACKAGE_DIR/config/"
    echo "✅ Copied F Prime dictionaries"
fi

# Copy any additional config files from build
if [[ -d "$BUILD_DIR/config" ]]; then
    cp -r "$BUILD_DIR/config/"* "$PACKAGE_DIR/config/" 2>/dev/null || true
    echo "✅ Copied additional config files"
fi

# Create installation script
cat > "$PACKAGE_DIR/scripts/install.sh" << 'EOF'
#!/bin/bash
# F Prime LED Blinker Installation Script
# Run with: sudo ./install.sh

set -e

INSTALL_USER="pi"
SERVICE_NAME="led-blinker"
INSTALL_DIR="/opt/fprime/led-blinker"
LOG_DIR="/var/log/fprime"

echo "=== F Prime LED Blinker Installation ==="

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "❌ This script must be run as root (use sudo)"
   exit 1
fi

# Create directories
echo "📁 Creating directories..."
mkdir -p "$INSTALL_DIR"
mkdir -p "$LOG_DIR"

# Copy files
echo "📦 Installing files..."
cp bin/LedBlinker "$INSTALL_DIR/"
cp -r config/* "$INSTALL_DIR/" 2>/dev/null || true
cp scripts/start.sh "$INSTALL_DIR/"
cp scripts/stop.sh "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR"/*

# Set ownership
chown -R $INSTALL_USER:$INSTALL_USER "$INSTALL_DIR"
chown -R $INSTALL_USER:$INSTALL_USER "$LOG_DIR"

# Add user to gpio group (if not already)
usermod -a -G gpio $INSTALL_USER

# Install systemd service
echo "🔧 Installing systemd service..."
cp scripts/led-blinker.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable $SERVICE_NAME

# Start service
echo "🚀 Starting service..."
systemctl start $SERVICE_NAME

# Check status
sleep 2
if systemctl is-active --quiet $SERVICE_NAME; then
    echo "✅ F Prime LED Blinker installed and running successfully!"
    echo ""
    echo "📊 Service Status:"
    systemctl status $SERVICE_NAME --no-pager -l
    echo ""
    echo "📋 Useful Commands:"
    echo "  Check status:   sudo systemctl status $SERVICE_NAME"
    echo "  View logs:      sudo journalctl -u $SERVICE_NAME -f"
    echo "  Stop service:   sudo systemctl stop $SERVICE_NAME"
    echo "  Start service:  sudo systemctl start $SERVICE_NAME"
    echo ""
    echo "🌐 Connect with F Prime GDS:"
    echo "  fprime-gds -n --ip <this-pi-ip> --port 50050"
else
    echo "❌ Service failed to start. Check logs:"
    echo "  sudo journalctl -u $SERVICE_NAME"
    exit 1
fi
EOF

chmod +x "$PACKAGE_DIR/scripts/install.sh"

# Create systemd service file
cat > "$PACKAGE_DIR/scripts/led-blinker.service" << EOF
[Unit]
Description=F Prime LED Blinker
Documentation=https://fprime.jpl.nasa.gov
After=network.target
Wants=network.target

[Service]
Type=simple
User=pi
Group=pi
WorkingDirectory=/opt/fprime/led-blinker
ExecStart=/opt/fprime/led-blinker/LedBlinker -a 0.0.0.0 -p 50050
Restart=always
RestartSec=5

# Security hardening
NoNewPrivileges=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=/var/log/fprime /dev/gpiomem /sys/class/gpio
PrivateTmp=yes
ProtectKernelTunables=yes
ProtectKernelModules=yes
ProtectControlGroups=yes

# Logging
StandardOutput=journal
StandardError=journal
SyslogIdentifier=led-blinker

[Install]
WantedBy=multi-user.target
EOF

# Create start/stop scripts
cat > "$PACKAGE_DIR/scripts/start.sh" << 'EOF'
#!/bin/bash
# Manual start script for F Prime LED Blinker
echo "Starting F Prime LED Blinker..."
sudo systemctl start led-blinker
sudo systemctl status led-blinker --no-pager
EOF

cat > "$PACKAGE_DIR/scripts/stop.sh" << 'EOF'
#!/bin/bash
# Manual stop script for F Prime LED Blinker
echo "Stopping F Prime LED Blinker..."
sudo systemctl stop led-blinker
echo "Service stopped."
EOF

chmod +x "$PACKAGE_DIR/scripts/"*.sh

# Create uninstall script
cat > "$PACKAGE_DIR/scripts/uninstall.sh" << 'EOF'
#!/bin/bash
# F Prime LED Blinker Uninstall Script
# Run with: sudo ./uninstall.sh

if [[ $EUID -ne 0 ]]; then
   echo "❌ This script must be run as root (use sudo)"
   exit 1
fi

echo "=== Uninstalling F Prime LED Blinker ==="

# Stop and disable service
systemctl stop led-blinker || true
systemctl disable led-blinker || true

# Remove files
rm -f /etc/systemd/system/led-blinker.service
rm -rf /opt/fprime/led-blinker
systemctl daemon-reload

echo "✅ F Prime LED Blinker uninstalled successfully!"
EOF

chmod +x "$PACKAGE_DIR/scripts/uninstall.sh"

# Create deployment documentation
cat > "$PACKAGE_DIR/docs/DEPLOYMENT.md" << EOF
# F Prime LED Blinker Deployment Guide

## Package Information
- **Version**: $VERSION
- **Build SHA**: $SHA
- **Target**: Raspberry Pi 4/5 (ARM64)
- **F Prime Version**: 3.6.1

## Quick Installation

1. Transfer package to Raspberry Pi:
   \`\`\`bash
   scp $PACKAGE_NAME.tar.gz pi@<raspberry-pi-ip>:~
   \`\`\`

2. Extract and install:
   \`\`\`bash
   tar -xzf $PACKAGE_NAME.tar.gz
   cd $PACKAGE_NAME/
   sudo ./scripts/install.sh
   \`\`\`

3. Verify installation:
   \`\`\`bash
   sudo systemctl status led-blinker
   \`\`\`

## F Prime GDS Connection

Connect from your development machine:
\`\`\`bash
fprime-gds -n --ip <raspberry-pi-ip> --port 50050
\`\`\`

## Service Management

- **Start**: \`sudo systemctl start led-blinker\`
- **Stop**: \`sudo systemctl stop led-blinker\`
- **Status**: \`sudo systemctl status led-blinker\`
- **Logs**: \`sudo journalctl -u led-blinker -f\`

## Hardware Requirements

- Raspberry Pi 4 or 5
- LED connected to GPIO pin 13
- Raspberry Pi OS (64-bit)

## Troubleshooting

1. **Service won't start**: Check logs with \`sudo journalctl -u led-blinker\`
2. **GPIO permissions**: Ensure pi user is in gpio group
3. **Port conflicts**: Check if port 50050 is available
4. **Network issues**: Verify firewall settings

## Uninstall

Run: \`sudo ./scripts/uninstall.sh\`
EOF

# Generate checksums
echo "🔒 Generating checksums..."
cd "$PACKAGE_DIR"
find . -type f -exec sha256sum {} \; | sort > verification/checksums.sha256
cd - > /dev/null

# Create main binary checksum for release notes
sha256sum "$PACKAGE_DIR/bin/LedBlinker" > "$PACKAGE_DIR/verification/LedBlinker.sha256"

# Create tarball
echo "📦 Creating tarball..."
cd dist
tar -czf "$PACKAGE_NAME.tar.gz" "$PACKAGE_NAME/"
cd - > /dev/null

# Create tarball checksum
sha256sum "dist/$PACKAGE_NAME.tar.gz" > "dist/$PACKAGE_NAME.sha256"

# Summary
echo ""
echo "✅ Package created successfully!"
echo "📦 Package: dist/$PACKAGE_NAME.tar.gz"
echo "🔒 Checksum: dist/$PACKAGE_NAME.sha256"
echo ""
echo "📋 Package Contents:"
tar -tzf "dist/$PACKAGE_NAME.tar.gz" | head -20
echo ""
echo "📊 Package Size:"
ls -lh "dist/$PACKAGE_NAME.tar.gz"
