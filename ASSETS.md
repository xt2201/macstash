# Asset Registry & Licensing (ASSETS.md)

All visual assets used in SideDock are either system-native SF Symbols, generated programmatically, or created specifically for this project.

## Iconography
- **System Icons:** Apple SF Symbols (via `Image(systemName:)`), compliant with Apple Human Interface Guidelines.
- **Brand & Menu Bar Icons:** Rendered programmatically via `Scripts/render_icons.sh` and AppKit vector drawing in `Scripts/render_svg.swift`.
- **Application Icons:** Fetched dynamically at runtime from `NSWorkspace.shared.icon(forFile:)` for installed applications.

## Wallpapers & Gradients
- Built-in backgrounds are purely mathematical CoreGraphics/SwiftUI gradients (mesh and linear), requiring zero external image files:
  1. *Aurora Borealis* (Cyan / Indigo / Teal linear gradient)
  2. *Sunset Glow* (Orange / Coral / Violet linear gradient)
  3. *Deep Space* (Dark Navy / Slate / Jet Black linear gradient)
  4. *Liquid Glass* (Ultra-thin material blur + specular highlight)
  5. *Frost Clear* (Transparent borderless presentation)
