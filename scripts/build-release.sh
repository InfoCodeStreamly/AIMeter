#!/bin/bash
#
# Build AIMeter release locally
# Usage: ./scripts/build-release.sh [version]
#
# Requirements:
#   - Xcode with command line tools
#   - Developer ID Application certificate in Keychain
#   - brew install create-dmg (for DMG creation)
#

set -e

VERSION="${1:-1.0}"
BUILD_DIR="build"
RELEASE_DIR="release"
PROJECT="AIMeter.xcodeproj"
SCHEME="AIMeter"

echo "========================================"
echo "  Building AIMeter v${VERSION}"
echo "========================================"
echo ""

# Clean previous build
echo "Cleaning previous build..."
rm -rf "$BUILD_DIR" "$RELEASE_DIR"
mkdir -p "$BUILD_DIR" "$RELEASE_DIR"

# Build
echo "Building release configuration..."
xcodebuild build \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR" \
    | grep -E "^(Build|Compile|Link|Sign|warning:|error:)" || true

APP_PATH="$BUILD_DIR/Build/Products/Release/AIMeter.app"

# Check build output
if [ ! -d "$APP_PATH" ]; then
    echo "Error: Build failed - app not found at $APP_PATH"
    exit 1
fi

echo ""
echo "Build successful: $APP_PATH"

# Sign with Developer ID
echo ""
echo "Signing with Developer ID Application..."

# Check if Developer ID certificate exists
if ! security find-identity -v -p codesigning | grep -q "Developer ID Application"; then
    echo ""
    echo "Warning: Developer ID Application certificate not found in Keychain"
    echo "The app will be signed with development certificate only."
    echo ""
    echo "To sign for distribution, you need:"
    echo "  1. Apple Developer Program membership (\$99/year)"
    echo "  2. Developer ID Application certificate"
    echo ""
else
    codesign --force --sign "Developer ID Application" \
        --timestamp \
        --options runtime \
        --entitlements "AIMeter/AIMeterRelease.entitlements" \
        "$APP_PATH"

    # Verify signature
    echo "Verifying signature..."
    codesign --verify --deep --strict "$APP_PATH"
    echo "Signature verified."
fi

echo ""
echo "========================================"
echo "  Build Complete"
echo "========================================"
echo ""
echo "App location: $APP_PATH"
echo ""
echo "Next steps for distribution:"
echo ""
echo "1. Notarize the app:"
echo "   ditto -c -k --keepParent \"$APP_PATH\" app.zip"
echo "   xcrun notarytool submit app.zip --apple-id EMAIL --password APP_PWD --team-id TEAM --wait"
echo "   xcrun stapler staple \"$APP_PATH\""
echo ""
echo "2. Create DMG:"
echo "   ./scripts/create-dmg.sh \"$APP_PATH\" \"$RELEASE_DIR\" \"$VERSION\""
echo ""
echo "3. Notarize DMG:"
echo "   xcrun notarytool submit release/AIMeter-${VERSION}.dmg --apple-id EMAIL --password APP_PWD --team-id TEAM --wait"
echo "   xcrun stapler staple release/AIMeter-${VERSION}.dmg"
echo ""
