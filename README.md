<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="Design/Logo/exports/brand/stash_lockup_dark.png">
    <source media="(prefers-color-scheme: light)" srcset="Design/Logo/exports/brand/stash_lockup_light.png">
    <img src="Design/Logo/exports/brand/stash_lockup_dark.png" alt="MacStash for macOS" width="460">
  </picture>
</p>

<p align="center">
  <strong>Tactile Hidden Controls &amp; Smart Corner Dials for macOS</strong><br/>
  <em>Zero-pixel hot corner gestures, multi-monitor hardware brightness, tactile audio routing, and Pomodoro focus timer.</em>
</p>

<p align="center">
  <a href="https://github.com/xt2201/macstash/releases/latest"><img src="https://img.shields.io/badge/release-v2.11.0-0A84FF?style=flat-square&logo=apple&logoColor=white" alt="Latest Release"></a>
  <img src="https://img.shields.io/badge/platform-macOS%2013.0%2B-5856D6?style=flat-square" alt="macOS 13.0+">
  <img src="https://img.shields.io/badge/arch-Universal%202%20(Apple%20Silicon%20%26%20Intel)-34C759?style=flat-square" alt="Universal 2 Architecture">
  <img src="https://img.shields.io/badge/Swift-6.0-F05138?style=flat-square&logo=swift&logoColor=white" alt="Swift 6.0">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue?style=flat-square" alt="MIT License"></a>
  <img src="https://img.shields.io/badge/updates-Sparkle%202-00D2FF?style=flat-square" alt="Sparkle 2 Auto-Update">
  <img src="https://img.shields.io/badge/telemetry-100%25%20offline-success?style=flat-square" alt="Zero Telemetry">
</p>

<p align="center">
  <a href="https://github.com/xt2201/macstash/releases/latest">
    <img src="https://img.shields.io/badge/Download-MacStash--v2.11.0.dmg-0A84FF?style=for-the-badge&logo=apple&logoColor=white" alt="Download MacStash DMG">
  </a>
</p>

<p align="center">
  <a href="#overview">Overview</a> &bull;
  <a href="#quadrant-architecture">Quadrant Architecture</a> &bull;
  <a href="#key-features">Key Features</a> &bull;
  <a href="#how-it-works">How It Works</a> &bull;
  <a href="#installation">Installation</a> &bull;
  <a href="#permissions--privacy">Privacy &amp; Permissions</a> &bull;
  <a href="#shortcuts">Shortcuts</a> &bull;
  <a href="#developer-guide">Developer Guide</a> &bull;
  <a href="#documentation">Documentation</a>
</p>

---

## Overview

**MacStash** is a lightweight, background utility for macOS that reinvents screen corners and borders as zero-pixel tactile interaction zones. Based on Fitts's Law, the physical corners of your display represent infinite target zones—meaning you can flick your mouse to any corner without needing to aim.

Tucked invisibly at the screen boundary, MacStash blooms interactive radial dials into view when your pointer dwells at a corner. Drag along the arc or flick your trackpad scroll wheel to adjust display brightness, tune keyboard backlighting, scrub master audio volume, or kick off a Pomodoro focus sprint.

<p align="center">
  <img src="Design/Logo/exports/brand/stash_quadrant_overview.png" alt="MacStash Quadrant Architecture Overview" width="920"/>
</p>

---

## Quadrant Architecture

MacStash assigns high-frequency system controls to the four physical display vertices:

| Corner | Default Assignment | Technology &amp; Action |
|---|---|---|
| **Top-Left (TL)** | **Keyboard Backlight** | Direct macOS Ambient Light Sensor (ALS) control; smooth 0–100% illumination with one-click toggle. |
| **Top-Right (TR)** | **Display Brightness** | Multi-monitor hardware DDC/CI (I2C) for third-party external monitors + Apple Silicon native display brightness. |
| **Bottom-Left (BL)** | **Pomodoro Focus Timer** | Radial arc countdown (0–60 min) with round progression pips and satellite reset/skip micro-controls. |
| **Bottom-Right (BR)** | **Master Volume &amp; Route** | Real-time audio gain adjustment and immediate audio output device switching. |
| **Screen Edge** | **Hidden Dock Shelf** | Smooth slide-out shelf with macOS dock magnification effect and instant Quick App Launcher. |

---

## Key Features

### 1. Sculpted Liquid Glass Radial Corner Dials
- Invisibly docked at the screen corners with zero desktop clutter.
- **Apple Liquid Glass Optical Realism**: Multi-layer frosted refraction, dual-path specular bevel highlights (135° virtual light source), and dynamic caustic ambient color halos.
- **Tactical HUD Precision Instrument Hub**: Center action hubs engineered with studio-grade optical glass bezels, multi-color hierarchical SF Symbols, and precision micro-typography with tabular figures (`.monospacedDigit()`).
- **Mathematical Symmetry & 4-Quadrant Balance**: Perfectly aligned along the 45° diagonal axis of symmetry with uniform 19pt clearance to both adjacent screen borders, inner concentric guide arcs, and 21 symmetrical ticks with major indicators placed at 0%, 25%, 50%, 75%, and 100%.
- **Luminous Fluid Meniscus**: Active levels (Volume, Brightness, Keyboard, Timer) are rendered as glowing fluid inside a sculpted crystal arc with a curved droplet meniscus head and illuminated laser-etched tick marks.
- **Natural Two-Axis Trackpad Scrubbing**: Synchronized with macOS Natural Scrolling via `event.isDirectionInvertedFromDevice`. Glide two fingers UP or RIGHT on your trackpad to smoothly increase volume, brightness, backlight, or timer duration, or DOWN and LEFT to decrease.
- Drag along the radial arc or use vertical/horizontal trackpad scrolling for fluid adjustments.
- Instant collapse when the cursor departs the quadrant area.

### 2. Multi-Monitor Hardware Brightness (DDC/CI &amp; Native)
- Controls third-party HDMI and DisplayPort monitors directly via DDC/CI hardware I2C packets.
- Smooth fallback to Apple Native CoreDisplay services for built-in Retina panels and Pro Display XDR / Studio Display.
- Synchronized multi-display dimming or independent per-display adjustment.

### 3. Tactile Pomodoro Focus Engine
- Visual countdown dial showing remaining session time as a sweeping luminous sector.
- Integrated round progression indicators showing completed vs. target focus intervals.
- Corner satellite micro-buttons for immediate one-click Session Reset and Interval Skip.
- Live ticking title in the macOS menu bar status item while running.

### 4. Master Audio &amp; Endpoint Routing
- Instant volume scrubbing with linear perceived loudness scaling.
- Rapid audio output device switcher directly from the corner popover.
- Low-latency synchronization with macOS CoreAudio subsystem.

### 5. The Liquid Docking Bay (Stash Drop Shelf) & Quick Scratchpad
- **The Stash Shelf**: The core namesake feature of MacStash. A sculpted liquid glass docking bay sliding smoothly from the left screen edge to hold files, images, links, and text snippets when dragging across spaces, displays, or apps.
- **Silky-Smooth 120 FPS Performance**: Isolated row rendering (`StashItemCardView`) and in-memory icon caching (`StashIconCache`) eliminate LaunchServices disk I/O during mouse hover and scroll, guaranteeing locked 120 FPS fluid interaction.
- **Instant Zero-Copy Drag Out**: Items dragged from the shelf provide direct file URL references without main-thread temporary file duplications, starting drag gestures instantaneously with zero freeze or stutter.
- **Liquid Ripple Drop Aura**: Hovering a dragged file over the drop zone summons an animated pulsating liquid ripple wave that magnetically expands to receive items. A top drop banner guides drag-and-drop even over populated lists.
- **Elevated Glass File Tiles**: Stashed items rest on translucent frosted glass tiles with continuous squircle corners, 3D hover elevation, and crystal micro-action buttons.
- **Bidirectional Shake-to-Summon Gesture**: Wiggle or shake the mouse cursor horizontally or vertically while dragging any file, photo, or snippet to immediately summon the Stash Shelf at your cursor with tactile mechanical detents.
- **1-Click Launch from Edge Peek Handle**: Hover or click the subtle 44pt left-edge indicator to slide out the shelf without delay, with full protection against edge jitter or accidental collapse.
- **Double-Click to Launch**: Double-clicking any file, image, or link on Stash Shelf immediately launches it with the default macOS system app.
- **Zero-Footprint Background Pass-Through**: Floating edge panels strictly ignore mouse events when idle and center resting peek handles on a slim strip, guaranteeing 100% unimpeded clicks in underlying macOS apps (Finder sidebar, Safari tabs, Xcode editor, Terminal).
- **Outside-Click & Mouse-Exit Auto-Dismiss**: Moving the mouse out of the drawer area into the workspace automatically schedules a smooth auto-dismiss timer, while clicking outside collapses the shelf immediately and returns window focus cleanly to your active application. Drop operations stay safely active during drag sessions.
- **Immediate First-Mouse Interaction**: Every button (Clear All, Copy Path, Reveal in Finder, Remove, Close) triggers on the very first mouse-up with zero swallowed clicks.
- **Quick Drag Export & Copy All**: Drag stashed items back out to any application, email, or Finder folder anytime, or click "Copy All" to copy all file references to the clipboard at once.
- **Quick Scratchpad Drawer**: Ephemeral liquid glass writing slate with dynamic key window keyboard focus for immediate typing, glowing emerald rim, live word and character counters, automatic local persistence, and standard macOS keyboard shortcuts (`Cmd+A`, `Cmd+C`, `Cmd+V`, `Cmd+Z`, `Esc`).

### 6. Keep Awake (Caffeine) Radial Dial
- Hardware-level macOS I/O Kit power assertions (`IOPMAssertionCreateWithName`) prevent display and system sleep during video exports, large downloads, or presentations.
- Radial presets: 15m, 30m, 1h, 2h, and Indefinite (∞) with tactile mechanical detent feedback.
- Quick status badge and one-click toggle in the macOS menu bar companion.

### 7. Cursor Radial Palette (for Ultrawide Displays)
- Press `Option + Space` to summon the 4-quadrant radial dials directly centered at your mouse cursor.
- Adjust Volume, Display Brightness, Keep Awake, and Focus Timer anywhere on screen without flinging the pointer across 34"–49" Ultrawide setups.

### 8. Hidden Edge Slider &amp; Now Playing Media Controls
- Rides flush against your screen border with configurable actions in Settings (Volume, Brightness, Keyboard, Timer, Keep Awake, Stash Shelf, Scratchpad) and 120Hz ProMotion vertical drag/scroll smoothness.
- **Extreme Edge &amp; Dwell Triggering**: Requires moving cursor to the physical edge boundary (`x >= maxX - 3.0`) with an intentional 180ms dwell delay, completely eliminating accidental expansions when using window scrollbars or controls in background apps.
- **Universal Now Playing Media Controller**: When configured for Volume, reveals an integrated vertical media controller right below the slider with live album artwork, a 5-bar rhythm audio visualizer dynamically tinted to match the track's artwork color, and vertical transport controls (Previous on top, Play/Pause in middle, Next at bottom) across all browsers (Crest, Safari, Chrome, Arc) and native players (Spotify, Apple Music, VLC).
- **Hover Track Tooltip**: Floating glassmorphic card previews full track title, artist, album, and source app on hover.
- **Two-Finger Edge Scrubbing**: Seamlessly tune volume, brightness, or your chosen action on the edge slider using natural two-finger vertical scrolling.

### 9. Tactile Detents &amp; Mechanical Acoustics
- **Trackpad Detents**: Emits crisp physical ticks via `NSHapticFeedbackManager` as the rotary dial steps through values.
- **Acoustic Feedback**: Low-latency mechanical click sound effects mimicking high-end rotary hardware dials.

### 10. Context-Aware Application Profiles
- Detects the frontmost active application and dynamically reconfigures corner dials (e.g., volume in Final Cut Pro, brightness in Xcode, timer in Safari).

### 11. Native Menu Bar Companion
- Operates as a lightweight agent (`LSUIElement = true`) with a ~15MB RAM footprint.
- Monochrome template status bar icon that illuminates during active Pomodoro intervals.
- Full-featured Preferences window (`Command + ,`).

### 12. Second Dock with Live Interactive Widgets
- **Auxiliary Second Dock**: An elegant live widget dock running alongside your native macOS Dock with zero conflict or overlap.
- **10 Native Local Widgets**:
  1. *Clock*: Digital, analog face, or flip clock with full multi-timezone world clock support.
  2. *Date*: Clear calendar date with weekday and untruncated full month name.
  3. *Weather*: Current conditions and multi-day forecast powered by Open-Meteo with zero API keys required and manual city search (no location permission needed).
  4. *Now Playing*: Interactive playback controls, track title, artist, progress bar, and freshness validation for Apple Music and Spotify.
  5. *Calendar*: Upcoming events, countdown timer, and 1-click video meeting Join buttons for Zoom, Google Meet, Teams, and Webex.
  6. *Reminders*: Due tasks checklist, quick-add input, and 1-tap task completion synced with Apple Reminders.
  7. *System Stats*: Real-time CPU usage, RAM utilization, battery percentage, charging state, and disk space without external tools.
  8. *Pomodoro*: Focus sprints, short/long breaks, and desktop notifications.
  9. *Search*: Spotlight application and file search bar with instant keyboard execution.
  10. *File Shelf*: Drop temporary files, links, and snippets onto the dock to hold and reuse across apps.
- **7 Layout Placements & Auto-Fit**: Fixed Bottom (perfectly positioned above the native macOS Dock with distance >= 0 px), Floating Window with drag handle, Fixed Top, Fixed Left, Fixed Right, and auto-fit screen width.
- **Smart Edge Triggers & Auto-Hide**: Customizable slide reveal delay (0.0s to 3.0s) and edge trigger activation thickness (2px to 20px).
- **Zero-Interference Pass-Through**: Mouse clicks on empty/transparent regions pass straight through to background windows.
- **Profile Switcher & Widget Gallery**: Supports multiple independent dock profiles (Work, Focus, Default) with instant switching and a searchable widget catalog.
- **Glass Styling**: Light Glass, Dark Glass, Liquid Glass, and Clear frameless themes.

---

## How It Works: Fitts's Law &amp; Zero-Pixel Hit-Zones

In human-computer interaction, **Fitts's Law** states that the time required to rapidly move to a target area is a function of the ratio between the distance to the target and the width of the target:

$$\text{MT} = a + b \log_2 \left( \frac{2D}{W} \right)$$

Because the macOS mouse cursor cannot travel beyond the physical boundary of the screen, the display edges and corners effectively have an **infinite target width** ($W = \infty$). This makes screen corners the fastest, most effortless targets on the entire screen:

1. **Zero Acquisition Cost**: You can flick your mouse toward a corner with maximum physical velocity without overshooting.
2. **Dwell Threshold Protection**: MacStash prevents accidental activations with an adjustable dwell delay (default `0.20s`), ensuring normal window management gestures are never intercepted.
3. **Continuous Scrubbing**: Once bloomed, circular arc trigonometry tracks cursor rotation around the corner vertex, granting 360-degree precision control.

---

## Installation

### Method 1: Direct DMG Download (Recommended)
1. Download the latest universal disk image: **[MacStash-v2.7.0.dmg](https://github.com/xt2201/macstash/releases/latest)**.
2. Open the disk image and drag **MacStash** into your `Applications` folder.
3. Launch MacStash from Launchpad, Spotlight, or `Applications`.

> [!NOTE]
> If macOS displays an unsigned developer notice on first launch, open **System Settings &gt; Privacy &amp; Security** and click **Open Anyway**, or run:
> ```bash
> xattr -d com.apple.quarantine /Applications/MacStash.app
> ```

### Method 2: Automatic In-App Updates (Sparkle 2)
MacStash includes built-in background updates powered by **Sparkle 2**. Updates are cryptographically verified using Apple CryptoKit Ed25519 public signatures before installation.
- Check for updates anytime via the Menu Bar &gt; **Preferences &gt; About &gt; Check for Updates**.

---

## Permissions &amp; Privacy

MacStash is committed to absolute user privacy. It operates **100% locally and offline**. It collects zero analytics, performs zero network tracking, and requires no account or cloud registration.

| Permission | System Privilege | Purpose in MacStash | Network Activity |
|---|---|---|:---:|
| **Accessibility** | `AXUIElement` | Used to anchor floating dial overlays at physical display corners and track cursor proximity. | **None (Offline)** |
| **Input Monitoring** | `CGEvent` tap | Detects corner hover gestures and global hotkey shortcuts. Does not record keystrokes or text. | **None (Offline)** |
| **Apple Events** | `NSAppleScript` | Coordinates hardware brightness, audio levels, and active application detection. | **None (Offline)** |
| **Calendars & Reminders** | `EventKit` | Reads upcoming events and todos for Calendar and Reminders widgets (100% on-device). | **None (Offline)** |

---

## Shortcuts &amp; Settings

| Shortcut | Action | Scope |
|---|---|---|
| `Option + Space` | Bloom Cursor Radial Palette | Global |
| `Control + Option + S` | Toggle Stash Drop Shelf | Global |
| `Control + Option + D` | Toggle Second Dock | Global |
| `Control + Option + N` | Toggle Quick Scratchpad | Global |
| `Option + S` | Toggle Screen Hot Corner Dials | Global |
| `Command + ,` | Open MacStash Preferences | Global / In-App |
| `Command + W` | Close Preferences or Guide Window | In-App |
| `Command + ?` | Open In-App Interactive Guide | Global / In-App |
| `Command + Q` | Quit MacStash completely | In-App |

Customize dwell delays, hit-zone radii, haptic intensity, audio feedback, and corner dial assignments anytime in **Preferences &gt; Hot Corners**.

---

## Developer Guide

### Prerequisites
- macOS 13.0 (Ventura) or newer (Sonoma and Sequoia fully supported).
- Swift 6 compiler toolchain (`xcrun swift --version`).
- Xcode Command Line Tools (`xcode-select --install`).

### Build &amp; Test Workflow

```bash
# 1. Clone repository
git clone https://github.com/xt2201/macstash.git
cd macstash

# 2. Run unit and domain test suite
make test

# 3. Regenerate all brand assets, ICNS, and vector PDFs
./Scripts/render_icons.sh

# 4. Compile release binary and package distribution DMG
./Scripts/build_dmg.sh
```

The output DMG and signed Sparkle ZIP archive will be placed in `dist/`.

---

## Documentation

Full bilingual guides and troubleshooting documentation are available in the repository:
- **[English Guide](Docs/Guide/en/01_getting_started.md)**: Getting Started, Display Brightness, Pomodoro Timer, Troubleshooting, Settings, Shortcuts, FAQ.
- **[Vietnamese Guide](Docs/Guide/vi/01_getting_started.md)**: Hướng dẫn bắt đầu, Độ sáng màn hình, Đồng hồ Pomodoro, Xử lý sự cố, Cài đặt, Phím tắt, FAQ.
- **[Brand &amp; Logo Rationale](Design/Logo/04-rationale.md)**: Visual identity principles, geometry specifications, and color palette.

---

## License

MacStash is open-source software licensed under the **[MIT License](LICENSE)**. All vector designs and brand assets are original works subject to the guidelines in `Design/Logo/LICENSES.md`.
