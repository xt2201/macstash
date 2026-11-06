#!/bin/bash
# Stash for macOS: Automated Asset and Icon Rendering Pipeline
# Reproducible generation of ICNS, Asset Catalogs, Menu Bar Templates, and Brand Exports.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

SOURCE_DIR="$PROJECT_ROOT/Design/Logo/source"
EXPORTS_DIR="$PROJECT_ROOT/Design/Logo/exports/brand"
RESOURCES_DIR="$PROJECT_ROOT/Sources/MacStash/Resources"
TMP_DIR="$PROJECT_ROOT/.build/icon_render_tmp"

mkdir -p "$EXPORTS_DIR"
mkdir -p "$RESOURCES_DIR"
mkdir -p "$TMP_DIR"

echo "=== Stash Icon & Asset Rendering Pipeline ==="

# Helper function to render SVG to exact size PNG using qlmanage and sips
render_svg_to_png() {
    local svg_file="$1"
    local out_png="$2"
    local target_w="$3"
    local target_h="$4"
    local base_name
    base_name="$(basename "$svg_file" .svg)"

    # Render at high resolution using macOS QuickLook engine
    qlmanage -t -s 1024 -o "$TMP_DIR" "$svg_file" > /dev/null 2>&1
    local tmp_render="$TMP_DIR/${base_name}.svg.png"

    if [ ! -f "$tmp_render" ]; then
        echo "Error: Failed to render $svg_file"
        exit 1
    fi

    # Scale to requested dimensions
    sips -z "$target_h" "$target_w" "$tmp_render" --out "$out_png" > /dev/null 2>&1
    rm -f "$tmp_render"
}

# 1. Render App Master Icon & Multi-Resolution ICNS
echo "[1/4] Generating MacStash.icns iconset..."
ICONSET_DIR="$TMP_DIR/MacStash.iconset"
rm -rf "$ICONSET_DIR"
mkdir -p "$ICONSET_DIR"

MASTER_SVG="$SOURCE_DIR/stash_icon_master.svg"
MASTER_1024="$EXPORTS_DIR/stash_icon_1024.png"
render_svg_to_png "$MASTER_SVG" "$MASTER_1024" 1024 1024

# Generate full Apple standard iconset tier
sips -z 16 16     "$MASTER_1024" --out "$ICONSET_DIR/icon_16x16.png" > /dev/null
sips -z 32 32     "$MASTER_1024" --out "$ICONSET_DIR/icon_16x16@2x.png" > /dev/null
sips -z 32 32     "$MASTER_1024" --out "$ICONSET_DIR/icon_32x32.png" > /dev/null
sips -z 64 64     "$MASTER_1024" --out "$ICONSET_DIR/icon_32x32@2x.png" > /dev/null
sips -z 128 128   "$MASTER_1024" --out "$ICONSET_DIR/icon_128x128.png" > /dev/null
sips -z 256 256   "$MASTER_1024" --out "$ICONSET_DIR/icon_128x128@2x.png" > /dev/null
sips -z 256 256   "$MASTER_1024" --out "$ICONSET_DIR/icon_256x256.png" > /dev/null
sips -z 512 512   "$MASTER_1024" --out "$ICONSET_DIR/icon_256x256@2x.png" > /dev/null
sips -z 512 512   "$MASTER_1024" --out "$ICONSET_DIR/icon_512x512.png" > /dev/null
cp "$MASTER_1024" "$ICONSET_DIR/icon_512x512@2x.png"

# Convert to MacStash.icns
iconutil -c icns "$ICONSET_DIR" -o "$EXPORTS_DIR/MacStash.icns"
cp "$EXPORTS_DIR/MacStash.icns" "$RESOURCES_DIR/AppIcon.icns"
rm -rf "$ICONSET_DIR"
echo "  -> Created: $EXPORTS_DIR/MacStash.icns"
echo "  -> Copied to: $RESOURCES_DIR/AppIcon.icns"

# 2. Render Menu Bar Template Images (Monochrome Alpha Mask)
echo "[2/4] Generating Menu Bar status bar template icons..."
swift "$PROJECT_ROOT/Scripts/render_menubar_icons.swift" "$RESOURCES_DIR"
cp "$RESOURCES_DIR"/stash_menubar*.png "$EXPORTS_DIR/"
echo "  -> Menu Bar template icons generated in @1x, @2x, @3x"

# 3. Render Brand Variants (Lockups, Marks, Favicon, Social Preview)
echo "[3/4] Rendering Brand Variants & Marketing Assets..."
render_svg_to_png "$SOURCE_DIR/stash_lockup_dark.svg" "$EXPORTS_DIR/stash_lockup_dark.png" 1024 320
render_svg_to_png "$SOURCE_DIR/stash_lockup_light.svg" "$EXPORTS_DIR/stash_lockup_light.png" 1024 320
render_svg_to_png "$SOURCE_DIR/stash_mark_color.svg" "$EXPORTS_DIR/stash_mark_color.png" 512 512
render_svg_to_png "$SOURCE_DIR/stash_mark_mono_black.svg" "$EXPORTS_DIR/stash_mark_mono_black.png" 512 512
render_svg_to_png "$SOURCE_DIR/stash_mark_mono_white.svg" "$EXPORTS_DIR/stash_mark_mono_white.png" 512 512
render_svg_to_png "$SOURCE_DIR/stash_social_preview.svg" "$EXPORTS_DIR/stash_social_preview.png" 1280 640
render_svg_to_png "$SOURCE_DIR/stash_favicon.svg" "$EXPORTS_DIR/stash_favicon_64.png" 64 64
render_svg_to_png "$SOURCE_DIR/stash_favicon.svg" "$EXPORTS_DIR/stash_favicon_32.png" 32 32

# 4. Render DMG Background Asset
echo "[4/4] Rendering DMG Installer Background..."
render_svg_to_png "$SOURCE_DIR/stash_dmg_background.svg" "$EXPORTS_DIR/stash_dmg_background.png" 660 420
cp "$EXPORTS_DIR/stash_dmg_background.png" "$RESOURCES_DIR/dmg_background.png"

# Cleanup temporary files
rm -rf "$TMP_DIR"
echo "=== All assets rendered successfully! ==="

# 5. Render Vector PDF Exports
echo "[5/5] Generating Vector PDF Exports..."
python3 -c "
import os
from weasyprint import HTML

svg_files = [
    'stash_icon_master',
    'stash_mark_color',
    'stash_mark_mono_black',
    'stash_mark_mono_white',
    'stash_lockup_dark',
    'stash_lockup_light',
    'stash_menubar'
]

for name in svg_files:
    svg_path = f'$SOURCE_DIR/{name}.svg'
    pdf_path = f'$EXPORTS_DIR/{name}.pdf'
    HTML(string=f'<style>@page {{ size: auto; margin: 0; }} body {{ margin: 0; }}</style><img src=\"{os.path.abspath(svg_path)}\" style=\"display:block; width:100%;\" />').write_pdf(pdf_path)
"
echo "  -> Vector PDFs generated in $EXPORTS_DIR"
