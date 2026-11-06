# MacStash

**Tactile Hidden Controls & Smart Edge Dock for macOS**  
*Inspired by [Stash for Mac](https://www.stashformac.com/)*

Built with modern **Swift 5.9+ / Swift 6**, **SwiftUI**, and native **AppKit**.

---

## Features

- **Quarter-Circle Corner Dials**:
  - Quarter-circle radial dials tucked invisibly into the four screen corners.
  - Gently blooms into view when the mouse approaches or hovers the corner.
  - Drag along the arc or use two-finger trackpad scroll to adjust values.
  - **Bottom-Right (BR)**: System Master Volume (Click center to mute/unmute).
  - **Top-Right (TR)**: Display Brightness.
  - **Top-Left (TL)**: Dark / Light Mode Switcher.
  - **Bottom-Left (BL)**: Secondary Quick Control (Mute / Output).
- **Hidden Dock Shelf ("Sometimes Apps")**:
  - Lives discreetly on the **Left Edge** of the screen.
  - Slides out smoothly when hovering the edge.
  - Pinned apps with macOS dock magnification effect on hover.
  - Small indicator dot showing which apps are currently running.
  - Includes an instant **Quick App Launcher** with search.
- **Vertical Edge Sliders**:
  - Glassmorphic capsule sliders along the screen border for continuous level adjustment.
- **Tactile Feedback**:
  - **Trackpad Haptics**: Uses `NSHapticFeedbackManager` to emit subtle, satisfying detent ticks as dials rotate through each notch.
  - **Mechanical Sound FX**: Low-latency mechanical click sounds mimicking physical rotary knobs.
- **Context-Aware App Profiles**:
  - Automatically detects frontmost active apps (e.g. Photoshop, Xcode, Safari, Finder) and can switch corner dial assignments dynamically.
- **Menu Bar Utility**:
  - Runs in the background as a lightweight agent (`LSUIElement = true`) without cluttering your main macOS Dock.
  - Quick hardware volume & brightness control right from the menu bar status icon.
  - Full-featured Preferences window (`⌘,`).

---

## Getting Started

### Requirements
- macOS 13.0+ (Ventura, Sonoma, Sequoia)
- Apple Silicon (M1/M2/M3/M4) or Intel Mac

### Quick Launch
To build and launch `MacStash.app`:
```bash
cd ~/Documents/MacStash
./Scripts/run.sh
```

### Build Release App Bundle
```bash
./Scripts/build_app.sh
```
This produces `MacStash.app` signed with an ad-hoc certificate, ready to be moved to `/Applications` if desired:
```bash
cp -R MacStash.app /Applications/
```

---

## Project Structure

```text
MacStash/
├── Package.swift                    # Swift Package definition
├── MacStash.app                     # Compiled native macOS Application Bundle
├── Sources/
│   └── MacStash/
│       ├── Main.swift               # Entry point
│       ├── App/
│       │   ├── AppDelegate.swift    # Status item & window management
│       │   └── AppState.swift       # Central state, settings & persistence
│       ├── Core/
│       │   ├── AudioManager.swift   # CoreAudio master volume & mute
│       │   ├── BrightnessManager.swift # DisplayServices screen brightness
│       │   ├── AppearanceManager.swift # Dark/Light mode toggle
│       │   ├── HapticManager.swift  # Trackpad haptic feedback
│       │   ├── SoundEffectManager.swift # Mechanical sound generator
│       │   ├── AppProfileManager.swift  # Active frontmost application watcher
│       │   └── InstalledAppsManager.swift # Applications scanner
│       ├── Window/
│       │   └── OverlayWindowController.swift # Floating borderless NSPanels
│       ├── Views/
│       │   ├── CornerDials/
│       │   │   ├── CornerDialView.swift
│       │   │   ├── RadialGaugeShape.swift
│       │   │   └── DialTicksView.swift
│       │   ├── EdgeSliders/
│       │   │   └── EdgeSliderView.swift
│       │   ├── HiddenDock/
│       │   │   ├── HiddenDockView.swift
│       │   │   └── QuickLauncherSheet.swift
│       │   ├── MenuBar/
│       │   │   └── MenuBarExtraView.swift
│       │   ├── Settings/
│       │   │   └── SettingsView.swift
│       │   └── Components/
│       │       └── GlassmorphicPanel.swift
│       └── Models/
│           ├── CornerPosition.swift
│           ├── ControlAction.swift
│           ├── EdgePosition.swift
│           ├── DockItem.swift
│           └── AppProfile.swift
├── Scripts/
│   ├── Info.plist                   # App metadata & LSUIElement flag
│   ├── build_app.sh                 # Release compiler & packager
│   └── run.sh                       # Quick runner
└── Tests/
    └── VerificationTests.swift      # Automated math & serialization tests
```
