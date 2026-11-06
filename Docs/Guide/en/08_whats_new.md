# What's New in Version 2.4.0

MacStash 2.4.0 introduces two-finger trackpad scroll adjustment for corner dials and screen edge sliders, enabling fluid, effortless value tuning without requiring mouse click-and-drag actions.

## Key Enhancements in Version 2.4.0

- Two-Finger Trackpad Scroll to Adjust: Seamlessly tune system volume, display brightness, keyboard backlight, and Pomodoro timer duration simply by scrolling with two fingers while hovering over active corner dials or edge sliders.
- Comprehensive Surface Coverage: Scroll adjustments are supported symmetrically across all 4 corner dials and the screen edge slider bar.
- Smart Momentum Protection: Automatic filtering of trackpad inertia phases prevents values from unintentionally running away after lifting fingers.
- Configurable in Settings: Easily toggle the gesture on or off under Settings > Hot Corners > Interaction Gestures.

# What's New in Version 2.3.6

MacStash 2.3.6 delivers comprehensive multi-monitor enhancements, instant click-to-activate corner dials, multi-display edge slider support, and seamless top bar popover expansion across external displays.

## Key Enhancements in Version 2.3.6

- Full Multi-Monitor Hot Corner Support: Resolves issues where display seam boundaries suppressed corner dials and edge sliders on secondary screens. All four corners on each connected display now trigger reliably.
- Instant Click-to-Activate: In addition to standard dwell delay activation, clicking directly into any screen corner immediately launches the corresponding control dial without waiting.
- Outer Corner Seam Suppression Toggle: Added a dedicated toggle under Settings > Hot Corners allowing users to choose whether to activate all screen corners or strictly outer desktop perimeter corners.
- Multi-Display Top Bar Popover: Clicking the MacStash icon in the top menu bar on any display (including external monitors) cleanly positions and expands the control popover on that exact display.
- Per-Display Brightness Scrubbing: Right edge slider correctly forwards display identifiers to independently adjust brightness on individual external monitors.

# What's New in Version 2.3.5

MacStash 2.3.5 introduces dynamic version synchronization in the user interface, automated version integrity auditing, and robust CI/CD release pipeline error handling.

## Key Enhancements in Version 2.3.5

- Dynamic Version Display: Replaced hardcoded version strings in settings and localization catalogs with dynamic bundle inspection, guaranteeing that the About tab always reflects the exact active version.
- Automated Version Consistency Audit: Added test suite coverage verifying that release tags, Info.plist metadata, documentation, and update feeds stay perfectly synchronized.
- Resilient Release Pipeline: Hardened icon and asset rendering scripts against missing optional python PDF libraries, preventing pipeline failures on remote runners.

# What's New in Version 2.3.4

MacStash 2.3.4 guarantees Pomodoro completion notifications on macOS via native foreground presentation delegates, audible alert chimes, and Dock icon attention requests.

## Key Enhancements in Version 2.3.4

- Guaranteed Foreground Notification Delivery: Integrated `UNUserNotificationCenterDelegate` with `.banner, .sound, .badge, .list` presentation options, resolving issues where macOS silently discarded completion banners while the application was active.
- Audible Alert Chime: Plays a crisp macOS completion sound (`Glass` or user preferred alert) and haptic detents when an interval ends, ensuring you hear the alert even if banners are silenced.
- Critical User Attention: Automatically requests user attention (`NSApp.requestUserAttention`) causing the Dock icon to bounce upon interval finish.
- Synchronized Mode Text: Accurately announces focus completion ("Pomodoro Completed") and break completion ("Break Finished") without inverted message strings.

# What's New in Version 2.3.3

MacStash 2.3.3 introduces a lossless AppKit vector rendering pipeline, dual-theme GitHub lockup integration, and a comprehensive documentation and visual asset overhaul.

## Key Enhancements in Version 2.3.3

- Native AppKit Vector Rasterizer: Replaced legacy QuickLook thumbnailing with dedicated Swift AppKit rasterization, ensuring non-square marketing assets retain exact aspect ratios and true alpha transparency without white letterbox borders.
- Dual-Theme Lockup Assets: Refactored dark and light lockup graphics to transparent backgrounds for seamless GitHub Light and Dark mode rendering.
- Quadrant Architecture Showcase: Added high-DPI visual diagram illustrating the four screen corner dials and the hidden edge dock shelf.
- Modernized README: Revamped project overview with flat badge matrix, direct release download buttons, permissions transparency matrix, and Fitts's law mechanics explanation.

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
