#!/bin/bash
#
# Create DMG installer for AIMeter
# Usage: ./scripts/create-dmg.sh <app-path> <output-dir> [version]
#
# Requirements:
#   brew install create-dmg
#

set -e

APP_NAME="AIMeter"
APP_PATH="$1"
OUTPUT_DIR="$2"
VERSION="${3:-1.0}"

# Validate arguments
if [ -z "$APP_PATH" ] || [ -z "$OUTPUT_DIR" ]; then
    echo "Usage: $0 <app-path> <output-dir> [version]"
    echo ""
    echo "Example:"
    echo "  $0 build/Build/Products/Release/AIMeter.app release 1.0"
    exit 1
fi

# Check if app exists
if [ ! -d "$APP_PATH" ]; then
    echo "Error: App not found at $APP_PATH"
    exit 1
fi

# Check if create-dmg is installed
if ! command -v create-dmg &> /dev/null; then
    echo "Error: create-dmg not found. Install with: brew install create-dmg"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

DMG_NAME="${APP_NAME}-${VERSION}.dmg"
DMG_PATH="${OUTPUT_DIR}/${DMG_NAME}"

# Remove existing DMG if present
rm -f "$DMG_PATH"

echo "Creating DMG: ${DMG_NAME}"
echo "  Source: $APP_PATH"
echo "  Output: $DMG_PATH"
echo ""

# Create DMG with drag-to-Applications layout
create-dmg \
    --volname "${APP_NAME}" \
    --window-pos 200 120 \
    --window-size 600 400 \
    --icon-size 100 \
    --icon "${APP_NAME}.app" 150 190 \
    --hide-extension "${APP_NAME}.app" \
    --app-drop-link 450 185 \
    --no-internet-enable \
    "${DMG_PATH}" \
    "${APP_PATH}" || true

# Verify DMG was created
if [ ! -f "$DMG_PATH" ]; then
    echo "Error: Failed to create DMG"
    exit 1
fi

echo ""
echo "DMG created: ${DMG_PATH}"

# Generate SHA256 checksum
shasum -a 256 "${DMG_PATH}" > "${DMG_PATH}.sha256"
echo "Checksum: $(cat ${DMG_PATH}.sha256)"

echo ""
echo "Done!"
echo ""
echo "Next steps:"
echo "  1. Notarize: xcrun notarytool submit ${DMG_PATH} --apple-id EMAIL --password PWD --team-id TEAM --wait"
echo "  2. Staple:   xcrun stapler staple ${DMG_PATH}"
