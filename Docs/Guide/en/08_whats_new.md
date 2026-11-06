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
