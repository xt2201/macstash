#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

echo "Building MacStash v2.0 (Release mode)..."
swift build -c release

BIN_PATH="$PROJECT_DIR/.build/release/MacStash"
APP_BUNDLE="$PROJECT_DIR/MacStash.app"
DMG_PATH="$PROJECT_DIR/MacStash.dmg"
DMG_STAGING="$PROJECT_DIR/.build/dmg_staging"

echo "Assembling MacStash.app bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$BIN_PATH" "$APP_BUNDLE/Contents/MacOS/MacStash"
cp "$PROJECT_DIR/Scripts/Info.plist" "$APP_BUNDLE/Contents/Info.plist"
chmod +x "$APP_BUNDLE/Contents/MacOS/MacStash"

echo "Ad-hoc code signing MacStash.app..."
codesign --force --deep --sign - "$APP_BUNDLE"

echo "Verifying signature..."
codesign --verify --deep --strict "$APP_BUNDLE"

# Build DMG installer for distribution into /Applications
echo "Creating MacStash.dmg installer with /Applications symlink..."
rm -rf "$DMG_STAGING" "$DMG_PATH"
mkdir -p "$DMG_STAGING"
cp -R "$APP_BUNDLE" "$DMG_STAGING/"
ln -s /Applications "$DMG_STAGING/Applications"

hdiutil create -volname "MacStash v2.0" -srcfolder "$DMG_STAGING" -ov -format UDZO "$DMG_PATH" > /dev/null
rm -rf "$DMG_STAGING"

echo "Build Complete!"
echo "   App Bundle: $APP_BUNDLE"
echo "   DMG Disk Image: $DMG_PATH"
