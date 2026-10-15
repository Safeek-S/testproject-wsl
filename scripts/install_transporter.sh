#!/usr/bin/env bash
set -e

echo "=== Installing Apple iTMSTransporter for Linux ==="

INSTALLER_URL="https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/ra/resources/download/public/Transporter__Linux/bin"
TEMP_INSTALLER="/tmp/itms_installer.sh"
TEMP_DIR="/tmp/itms_extracted"

echo "1. Downloading iTMSTransporter from Apple..."
curl -sSL "$INSTALLER_URL" -o "$TEMP_INSTALLER"
chmod +x "$TEMP_INSTALLER"

echo "2. Extracting package..."
"$TEMP_INSTALLER" --noexec --target "$TEMP_DIR"

echo "3. Installing to /usr/local/itms..."
sudo mkdir -p /usr/local/itms
sudo cp -r "$TEMP_DIR/itms/." /usr/local/itms/
sudo chmod -R 755 /usr/local/itms

echo "4. Cleaning up temporary files..."
rm -f "$TEMP_INSTALLER"
rm -rf "$TEMP_DIR"

echo "5. Verifying installation..."
/usr/local/itms/bin/iTMSTransporter -version

echo "=== iTMSTransporter installation complete! ==="

