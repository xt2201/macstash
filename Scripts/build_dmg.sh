#!/usr/bin/env bash
# Stash for macOS: Universal DMG & Sparkle Update Packaging Pipeline
# Builds universal binary (arm64 + x86_64), embeds brand assets and Sparkle.framework,
# signs inside-out, and produces both DMG installer and signed ZIP update archive.
set -euo pipefail

show_help() {
    cat << EOF
Usage: $(basename "$0") [options]

Builds universal macOS release binary (arm64 + x86_64), creates Stash.app bundle,
and packages a distribution DMG and Sparkle update ZIP with Ed25519 signatures.

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
if [[ -x "$REPO_ROOT/Scripts/render_icons.sh" ]]; then
    echo "[0/7] Verifying and rendering latest brand icon assets..."
    "$REPO_ROOT/Scripts/render_icons.sh"
elif [[ -x "$REPO_ROOT/scripts/render_icons.sh" ]]; then
    echo "[0/7] Verifying and rendering latest brand icon assets..."
    "$REPO_ROOT/scripts/render_icons.sh"
fi

VERSION="2.4.0"
if [[ -f "$REPO_ROOT/VERSION" ]]; then
    VERSION="$(tr -d '[:space:]' < "$REPO_ROOT/VERSION")"
elif [[ -f "$REPO_ROOT/Scripts/Info.plist" ]]; then
    VERSION=$(defaults read "$REPO_ROOT/Scripts/Info.plist" CFBundleShortVersionString 2>/dev/null || echo "2.4.0")
fi

echo "[1/7] Building release binaries for arm64 and x86_64 architectures..."
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
mkdir -p "$APP_BUNDLE/Contents/Frameworks"

echo "[2/7] Merging universal binary via lipo..."
lipo -create -output "$APP_BUNDLE/Contents/MacOS/Stash" "$ARM64_BIN" "$X86_BIN"
chmod +x "$APP_BUNDLE/Contents/MacOS/Stash"

ARM64_NP_DYLIB="$REPO_ROOT/.build/arm64-apple-macosx/release/libMacStashNowPlaying.dylib"
X86_NP_DYLIB="$REPO_ROOT/.build/x86_64-apple-macosx/release/libMacStashNowPlaying.dylib"
if [[ -f "$ARM64_NP_DYLIB" && -f "$X86_NP_DYLIB" ]]; then
    echo "Merging universal libMacStashNowPlaying.dylib..."
    lipo -create -output "$APP_BUNDLE/Contents/Frameworks/libMacStashNowPlaying.dylib" "$ARM64_NP_DYLIB" "$X86_NP_DYLIB"
    chmod +x "$APP_BUNDLE/Contents/Frameworks/libMacStashNowPlaying.dylib"
fi

# Add rpath for embedded frameworks
install_name_tool -add_rpath "@executable_path/../Frameworks" "$APP_BUNDLE/Contents/MacOS/Stash" 2>/dev/null || true

echo "[3/7] Copying app bundle resources and metadata..."
if [[ -f "$REPO_ROOT/Scripts/Info.plist" ]]; then
    cp "$REPO_ROOT/Scripts/Info.plist" "$APP_BUNDLE/Contents/Info.plist"
elif [[ -f "$REPO_ROOT/Sources/MacStash/Resources/Info.plist" ]]; then
    cp "$REPO_ROOT/Sources/MacStash/Resources/Info.plist" "$APP_BUNDLE/Contents/Info.plist"
fi

# Update version and executable metadata in Info.plist
if [[ -f "$APP_BUNDLE/Contents/Info.plist" ]]; then
    BUILD_VERSION=$(echo "$VERSION" | tr -d '.')
    if [[ -f "$REPO_ROOT/Scripts/Info.plist" ]]; then
        EXISTING_BUILD=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$REPO_ROOT/Scripts/Info.plist" 2>/dev/null || true)
        if [[ -n "$EXISTING_BUILD" && "$EXISTING_BUILD" =~ ^[0-9]+$ ]]; then
            BUILD_VERSION="$EXISTING_BUILD"
        fi
    fi
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$APP_BUNDLE/Contents/Info.plist" 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_VERSION" "$APP_BUNDLE/Contents/Info.plist" 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Set :CFBundleExecutable Stash" "$APP_BUNDLE/Contents/Info.plist" 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string AppIcon" "$APP_BUNDLE/Contents/Info.plist" 2>/dev/null || \
    /usr/libexec/PlistBuddy -c "Set :CFBundleIconFile AppIcon" "$APP_BUNDLE/Contents/Info.plist" 2>/dev/null || true
fi

# Copy icon and resources into app bundle
if [[ -d "$REPO_ROOT/Sources/MacStash/Resources" ]]; then
    cp -R "$REPO_ROOT/Sources/MacStash/Resources/"* "$APP_BUNDLE/Contents/Resources/" 2>/dev/null || true
    if [[ -f "$APP_BUNDLE/Contents/Resources/now-playing.pl" ]]; then
        chmod +x "$APP_BUNDLE/Contents/Resources/now-playing.pl"
    fi
fi

# Embed target resource bundles if present
for rb in "$REPO_ROOT"/.build/*/release/MacStash_MacStash.bundle; do
    if [[ -d "$rb" ]]; then
        cp -R "$rb" "$APP_BUNDLE/Contents/Resources/" 2>/dev/null || true
        break
    fi
done

# Embed Sparkle.framework
echo "Embedding Sparkle.framework..."
SPARKLE_FW_SRC="$REPO_ROOT/.build/artifacts/sparkle/Sparkle/Sparkle.xcframework/macos-arm64_x86_64/Sparkle.framework"
if [[ ! -d "$SPARKLE_FW_SRC" ]]; then
    SPARKLE_FW_SRC=$(find "$REPO_ROOT/.build" -name "Sparkle.framework" -type d | grep "Sparkle.xcframework" | head -n 1)
fi

if [[ -d "$SPARKLE_FW_SRC" ]]; then
    cp -R "$SPARKLE_FW_SRC" "$APP_BUNDLE/Contents/Frameworks/Sparkle.framework"
else
    echo "Error: Sparkle.framework source not found in .build artifacts!" >&2
    exit 1
fi

echo "[4/7] Code signing application bundle..."
SIGNING_IDENTITY="${SIGNING_IDENTITY:-}"
SIGN_ID_ARG="${SIGNING_IDENTITY:--}"

NP_DYLIB="$APP_BUNDLE/Contents/Frameworks/libMacStashNowPlaying.dylib"
if [[ -f "$NP_DYLIB" ]]; then
    codesign --force --sign "$SIGN_ID_ARG" "$NP_DYLIB"
fi

FW="$APP_BUNDLE/Contents/Frameworks/Sparkle.framework"
if [[ -d "$FW" ]]; then
    for xpc in "$FW/Versions/B/XPCServices/"*.xpc; do
        if [[ -d "$xpc" ]]; then
            codesign --force --sign "$SIGN_ID_ARG" "$xpc"
        fi
    done
    if [[ -f "$FW/Versions/B/Autoupdate" ]]; then
        codesign --force --sign "$SIGN_ID_ARG" "$FW/Versions/B/Autoupdate"
    fi
    if [[ -d "$FW/Versions/B/Updater.app" ]]; then
        codesign --force --sign "$SIGN_ID_ARG" "$FW/Versions/B/Updater.app"
    fi
    codesign --force --sign "$SIGN_ID_ARG" "$FW"
fi

if [[ "$ALLOW_UNSIGNED" == "true" || -z "$SIGNING_IDENTITY" ]]; then
    echo "Using ad-hoc code signature with stable designated requirement..."
    codesign --force --sign - --requirements '=designated => identifier "com.macstash.app"' "$APP_BUNDLE"
else
    echo "Signing with identity: $SIGNING_IDENTITY..."
    codesign --force --options runtime --sign "$SIGNING_IDENTITY" "$APP_BUNDLE"
fi

codesign --verify --deep --strict "$APP_BUNDLE"

mkdir -p "$OUTPUT_DIR"

echo "[5/7] Creating Sparkle update ZIP archive..."
ZIP_FILENAME="Stash-${VERSION}.zip"
ZIP_PATH="$REPO_ROOT/$OUTPUT_DIR/$ZIP_FILENAME"
rm -f "$ZIP_PATH"
(cd "$STAGING_DIR" && ditto -c -k --keepParent "$APP_NAME" "$ZIP_PATH")

if [[ -f "$REPO_ROOT/Scripts/sign_sparkle_update.swift" ]]; then
    echo "Signing update zip with Ed25519 signature..."
    SIGN_OUTPUT=$(swift "$REPO_ROOT/Scripts/sign_sparkle_update.swift" "$ZIP_PATH" 2>&1 || true)
    echo "$SIGN_OUTPUT"
    echo "$SIGN_OUTPUT" > "${ZIP_PATH}.signature.txt"

    ED_SIG=$(echo "$SIGN_OUTPUT" | grep '^ED_SIGNATURE=' | cut -d= -f2- || true)
    if [[ -n "$ED_SIG" && -f "$REPO_ROOT/Scripts/update_appcast.swift" ]]; then
        BUILD_NUM=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$APP_BUNDLE/Contents/Info.plist" 2>/dev/null || echo "$VERSION")
        swift "$REPO_ROOT/Scripts/update_appcast.swift" "$VERSION" "$BUILD_NUM" "$ZIP_PATH" "$ED_SIG"
    fi
fi

echo "[6/7] Creating DMG disk image with brand identity and Applications link..."
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

echo "[7/7] Generating SHA-256 checksums..."
SHA_FILE="${DMG_PATH}.sha256"
shasum -a 256 "$DMG_PATH" | awk '{print $1}' > "$SHA_FILE"
DMG_SHA="$(cat "$SHA_FILE")"

ZIP_SHA_FILE="${ZIP_PATH}.sha256"
shasum -a 256 "$ZIP_PATH" | awk '{print $1}' > "$ZIP_SHA_FILE"
ZIP_SHA="$(cat "$ZIP_SHA_FILE")"

echo "Build Pipeline Complete!"
echo "   DMG Artifact: $DMG_PATH (SHA256: $DMG_SHA)"
echo "   ZIP Artifact: $ZIP_PATH (SHA256: $ZIP_SHA)"
