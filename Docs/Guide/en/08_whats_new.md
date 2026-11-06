# What's New in Version 2.3.2

MacStash 2.3.2 delivers ultra-smooth keyboard backlight scrubbing in the top bar control popover, instantaneous hardware synchronization, and one-tap backlight toggling.

## Key Enhancements in Version 2.3.2

- Ultra-Smooth Keyboard Backlight Slider: Eliminated runloop delays and jitter during continuous slider dragging, keeping the thumb and percentage label in exact lockstep.
- Isolated Slider Components: Decomposed backlight and volume controls into dedicated views, preventing unnecessary display list queries during dragging.
- On-Appear Hardware Sync: Automatically queries and synchronizes current MacBook keyboard backlight and audio volume whenever opening the Menu Bar popover.
- One-Tap Backlight Toggle: Tapping the keyboard icon at the beginning of the slider toggles keyboard illumination on or off immediately.
- Synchronous Volume Scrubbing: Standardized MainActor volume updates to eliminate stutter during rapid volume adjustments.

# What's New in Version 2.3.1

MacStash 2.3.1 resolves Pomodoro duration jumping glitches, enhances corner dial UX with integrated satellite micro-controls, and completely hides edge sliders when idle.

## Key Enhancements in Version 2.3.1

- Pomodoro Dial Precision & Stability: Resolved gesture conflict where center badge taps were misidentified as radial drags, eliminating unexpected jumps to 24 or 23 minutes.
- Dial Arc Accuracy: The idle radial arc precisely mirrors the selected minute mark on the 60-minute dial without jumping to 100% on release.
- Integrated Satellite Micro-Buttons: Added translucent Reset and Skip mode buttons directly inside the corner dial quadrant for instant one-click actions.
- Round Progression Indicators: Center badge displays circular pips indicating completed vs total focus intervals.
- Completely Hidden Edge Slider: The right-edge vertical slider is now 100% hidden when idle with zero pixels on screen, smoothly gliding into view when hovering near the display edge.
- Paused Status Bar Countdown: The Menu Bar title retains countdown visibility during paused sessions.

# What's New in Version 2.3.0

MacStash 2.3.0 delivers major polish across audio controls, multi-monitor brightness, custom application profiles, and gesture edge sliders.

## Key Enhancements in Version 2.3.0

- One-Click In-Place Auto-Updates (Sparkle 2): Industry-standard macOS auto-updater integrated with Ed25519 (CryptoKit) cryptographic signature verification for seamless background updates and relaunching.
- Modern Audio Engine: Upgraded to modern AudioObject APIs with zero deprecation warnings, quick mute button on the menu bar speaker icon, and quick audio output device selector.
- Multi-Monitor Brightness: Individual brightness controls in the menu bar extra popover with screen names, icons, and persistent profile storage per display UUID.
- Application Profiles: Dedicated profile manager in Settings allowing custom corner and edge control mappings tailored to specific applications.
- Edge Sliders: Outer right edge slider gesture with intelligent pass-through hit testing and outer screen boundary validation.
- Dynamic Hotkeys: Configurable global shortcut parser for toggling dials with real-time macOS conflict detection.
- Complete Concurrency Safety: Swift 6 strict concurrency compliance across auto-update, appearance, and permission services.
- Comprehensive Backup: Backup and restore payloads now encompass both general settings and custom application profiles.

# What's New in Version 2.0.0

MacStash 2.0.0 represents a major stabilization and feature release.

## Key Enhancements

- Multi-monitor outer corner detection avoiding inner display seam conflicts.
- Formal state machine overlay lifecycle with generational delay cancellation.
- Universal binary distribution supporting both Apple Silicon (arm64) and Intel (x86_64).
- Multi-display brightness controller supporting Apple DisplayServices, DDC/CI, and Software Dimming.
- Monotonic Pomodoro focus timer surviving window drags and macOS system sleep.
- Standard 7-tab Settings preferences window with permissions deep-links and JSON backup.
- In-app offline user guide with search filter and first-launch onboarding walkthrough.
