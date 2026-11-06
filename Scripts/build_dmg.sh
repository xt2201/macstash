#!/usr/bin/env bash
# Stash for macOS: Universal DMG Packaging Pipeline
# Builds universal binary (arm64 + x86_64), embeds brand assets, and creates branded DMG installer.
set -euo pipefail

show_help() {
    cat << EOF
Usage: $(basename "$0") [options]

Builds universal macOS release binary (arm64 + x86_64), creates Stash.app bundle,
and packages a distribution DMG with SHA-256 checksum.

Options:
  -h, --help        Show this help message and exit
  --unsigned        Skip developer signing; enforce ad-hoc signature
  --output-dir DIR  Specify custom output directory (default: dist)
EOF
}

ALLOW_UNSIGNED=false
OUTPUT_DIR="dist"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        --unsigned)
            ALLOW_UNSIGNED=true
            shift
            ;;
        --output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1" >&2
            show_help
            exit 1
            ;;
    esac
done

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# Ensure brand assets are generated and fresh
if [[ -x "$REPO_ROOT/scripts/render_icons.sh" ]]; then
    echo "[0/6] Verifying and rendering latest brand icon assets..."
    "$REPO_ROOT/scripts/render_icons.sh"
fi

VERSION="2.3.0"
if [[ -f "$REPO_ROOT/VERSION" ]]; then
    VERSION="$(tr -d '[:space:]' < "$REPO_ROOT/VERSION")"
elif [[ -f "$REPO_ROOT/scripts/Info.plist" ]]; then
    VERSION=$(defaults read "$REPO_ROOT/scripts/Info.plist" CFBundleShortVersionString 2>/dev/null || echo "2.3.0")
fi

echo "[1/6] Building release binaries for arm64 and x86_64 architectures..."
swift build --triple arm64-apple-macosx -c release
swift build --triple x86_64-apple-macosx -c release

ARM64_BIN="$REPO_ROOT/.build/arm64-apple-macosx/release/MacStash"
X86_BIN="$REPO_ROOT/.build/x86_64-apple-macosx/release/MacStash"

if [[ ! -f "$ARM64_BIN" || ! -f "$X86_BIN" ]]; then
    echo "Error: Missing compiled architecture binaries." >&2
    exit 1
fi

STAGING_DIR="$REPO_ROOT/.build/package_staging"
APP_NAME="Stash.app"
APP_BUNDLE="$STAGING_DIR/$APP_NAME"

rm -rf "$STAGING_DIR"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

echo "[2/6] Merging universal binary via lipo..."
lipo -create -output "$APP_BUNDLE/Contents/MacOS/Stash" "$ARM64_BIN" "$X86_BIN"
chmod +x "$APP_BUNDLE/Contents/MacOS/Stash"

echo "[3/6] Copying app bundle resources and metadata..."
if [[ -f "$REPO_ROOT/Scripts/Info.plist" ]]; then
    cp "$REPO_ROOT/Scripts/Info.plist" "$APP_BUNDLE/Contents/Info.plist"
elif [[ -f "$REPO_ROOT/Sources/MacStash/Resources/Info.plist" ]]; then
    cp "$REPO_ROOT/Sources/MacStash/Resources/Info.plist" "$APP_BUNDLE/Contents/Info.plist"
fi

# Update version and icon metadata in Info.plist
if [[ -f "$APP_BUNDLE/Contents/Info.plist" ]]; then
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$APP_BUNDLE/Contents/Info.plist" 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $VERSION" "$APP_BUNDLE/Contents/Info.plist" 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Set :CFBundleExecutable Stash" "$APP_BUNDLE/Contents/Info.plist" 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string AppIcon" "$APP_BUNDLE/Contents/Info.plist" 2>/dev/null || \
    /usr/libexec/PlistBuddy -c "Set :CFBundleIconFile AppIcon" "$APP_BUNDLE/Contents/Info.plist" 2>/dev/null || true
fi

# Copy icon and resources into app bundle
if [[ -d "$REPO_ROOT/Sources/MacStash/Resources" ]]; then
    cp -R "$REPO_ROOT/Sources/MacStash/Resources/"* "$APP_BUNDLE/Contents/Resources/" 2>/dev/null || true
fi

# Also embed target resource bundles if present
for rb in "$REPO_ROOT"/.build/*/release/MacStash_MacStash.bundle; do
    if [[ -d "$rb" ]]; then
        cp -R "$rb" "$APP_BUNDLE/Contents/Resources/" 2>/dev/null || true
        break
    fi
done

echo "[4/6] Code signing application bundle..."
SIGNING_IDENTITY="${SIGNING_IDENTITY:-}"
if [[ "$ALLOW_UNSIGNED" == "true" || -z "$SIGNING_IDENTITY" ]]; then
    echo "Using ad-hoc code signature with stable designated requirement..."
    codesign --force --deep --sign - --requirements '=designated => identifier "com.macstash.app"' "$APP_BUNDLE"
else
    echo "Signing with identity: $SIGNING_IDENTITY..."
    codesign --force --deep --options runtime --sign "$SIGNING_IDENTITY" "$APP_BUNDLE"
fi

codesign --verify --deep --strict "$APP_BUNDLE"

echo "[5/6] Creating DMG disk image with brand identity and Applications link..."
mkdir -p "$OUTPUT_DIR"
DMG_VOLNAME="Stash $VERSION"
DMG_FILENAME="Stash-${VERSION}.dmg"
if [[ "$ALLOW_UNSIGNED" == "true" || -z "$SIGNING_IDENTITY" ]]; then
    DMG_FILENAME="Stash-${VERSION}-unsigned.dmg"
fi
DMG_PATH="$REPO_ROOT/$OUTPUT_DIR/$DMG_FILENAME"

DMG_SRC="$REPO_ROOT/.build/dmg_source"
rm -rf "$DMG_SRC" "$DMG_PATH"
mkdir -p "$DMG_SRC/.background"

# 1. Place Stash.app
cp -R "$APP_BUNDLE" "$DMG_SRC/"

# 2. Add /Applications symlink
ln -s /Applications "$DMG_SRC/Applications"

# 3. Add custom brand background
if [[ -f "$REPO_ROOT/Sources/MacStash/Resources/dmg_background.png" ]]; then
    cp "$REPO_ROOT/Sources/MacStash/Resources/dmg_background.png" "$DMG_SRC/.background/dmg_background.png"
fi

# 4. Add Volume Icon
if [[ -f "$REPO_ROOT/Sources/MacStash/Resources/AppIcon.icns" ]]; then
    cp "$REPO_ROOT/Sources/MacStash/Resources/AppIcon.icns" "$DMG_SRC/.VolumeIcon.icns"
    SetFile -a C "$DMG_SRC" 2>/dev/null || true
fi

# 5. Build UDZO disk image
hdiutil create -volname "$DMG_VOLNAME" -srcfolder "$DMG_SRC" -ov -format UDZO "$DMG_PATH" > /dev/null
rm -rf "$DMG_SRC"

echo "[6/6] Generating SHA-256 checksum..."
SHA_FILE="${DMG_PATH}.sha256"
shasum -a 256 "$DMG_PATH" | awk '{print $1}' > "$SHA_FILE"
SHA256_HASH="$(cat "$SHA_FILE")"

echo "Package Build Complete!"
echo "   Artifact: $DMG_PATH"
echo "   Checksum: $SHA256_HASH"
