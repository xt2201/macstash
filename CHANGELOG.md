# Changelog

All notable changes to MacStash are documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [2.5.0] - 2026-11-06

### Added
- Tactile Stash Drop Shelf: the core namesake feature of MacStash. A frosted glass drop shelf sliding smoothly from the left screen edge to hold files, images, links, and text snippets when dragging across spaces, displays, or apps.
- Keep Awake (Caffeine) Radial Timer: hardware power assertion engine preventing screen and system sleep with preset dial notches (15m, 30m, 1h, 2h, and Indefinite), tactile mechanical detents, and Menu Bar quick status badge.
- Quick Scratchpad Drawer: ephemeral glassmorphic notepad on the left screen edge with live word and character counters, automatic local persistence, and quick copy/clear actions.
- Cursor Radial Palette: summons floating radial dials directly centered at the mouse cursor via global shortcut (`Option + Space`) for instant control without traversing across Ultrawide or multi-monitor screens.
- EdgeBar Action Selector in Settings: easily customize edge slider actions (Volume, Brightness, Keyboard Backlight, Pomodoro Timer, Keep Awake, Stash Shelf, Scratchpad, or Disabled).
- Universal Now Playing Media Controls: integrated vertical media module below Volume slider featuring live album artwork and vertical playback buttons (Previous on top, Play/Pause in middle, Next at bottom).
- Dancing Audio Waveform Visualizer: 5-bar animated audio equalizer in vibrant amber-orange gradient synchronized with playback and volume levels, smoothly resting on pause.
- Floating Track Details Tooltip: hover over album artwork to preview full track title, artist name, and album.
- Configurable global shortcuts for Cursor Palette (`Option+Space`), Stash Shelf (`Control+Option+S`), and Scratchpad (`Control+Option+N`).

---

## [2.4.0] - 2026-11-06

### Added
- Two-finger trackpad scroll adjustment (option in Settings > Hot Corners > Interaction Gestures) to seamlessly tune volume, brightness, backlight, and Pomodoro timer without clicking and dragging.
- Instant click-to-activate corner dials across all 4 screen corners without waiting for dwell delay.
- Option to toggle outer-only corner triggering under Settings > Hot Corners (`onlyOuterCorners`), defaulted to false so every corner on multi-monitor setups works out of the box.
- Independent per-display brightness control via the right-edge vertical slider on external screens.

### Fixed
- Fixed suppressed corner dials and edge sliders on secondary screens caused by inner screen seam perimeter filtering.
- Fixed Menu Bar control popover failing to expand downwards when clicking the app icon on external displays.
- Automatic anchor window creation and cleanup when toggling the menu bar popover across different displays.
- Smart trackpad momentum filtering preventing value runaway after lifting fingers.

---

## [2.3.5] - 2026-11-06

### Added
- Dynamic bundle version resolution for About tab and localization catalog, ensuring active version numbers are always accurately presented in the UI.
- Comprehensive `VersionConsistencyTests` test suite verifying synchronization across VERSION, Info.plist, CHANGELOG, Guides, and Sparkle appcast.

### Fixed
- Fixed stale version `2.1.1` in About tab by eliminating hardcoded version strings from `LocalizationService.swift` and `Localizable.xcstrings`.
- Fixed CI/CD release build failure on GitHub Actions by making `weasyprint` optional in `render_icons.sh`, preventing pipeline crashes when optional python PDF libraries are absent.

---

## [2.3.4] - 2026-11-06

### Added
- Native macOS alert chime sound (`Glass`) and system audio alert on Pomodoro interval completion.
- Critical user attention request (`NSApp.requestUserAttention`) causing the Dock icon to bounce upon interval finish.
- Foreground notification presentation support via `UNUserNotificationCenterDelegate` ensuring alert banners and sounds are delivered even when MacStash is active.

### Fixed
- Fixed missing Pomodoro completion notifications on macOS by setting the notification center delegate and handling `willPresent` with banner, sound, and badge options.
- Fixed inverted completion messages: properly passes `completedMode` from engine tick so focus session completions announce break time and break completions announce focus time.
- Fixed notification delivery authorization auto-check when status is unprompted.

---

## [2.3.3] - 2026-11-06

### Added
- Native Apple AppKit SVG rasterizer (`Scripts/render_svg.swift`) producing lossless 32-bit RGBA PNG assets without letterbox padding or aspect ratio distortion.
- Dual-theme GitHub lockup assets supporting automatic Light and Dark appearance switching via `<picture>`.
- Screen quadrant architecture visual showcase diagram (`stash_quadrant_overview.svg`) detailing all 4 corners and the hidden dock shelf.

### Changed
- Complete overhaul of `README.md` following modern macOS open-source standards, adding flat badges, direct DMG download call-to-action, permissions transparency matrix, and visual feature breakdowns.
- Re-rendered all marketing, lockup, social preview, and DMG background assets with true alpha channels and exact aspect ratios.

### Fixed
- Fixed critical asset rendering distortion where `qlmanage` thumbnail squaring and `sips` force-scaling squashed non-square graphics and generated white letterbox bands.
- Removed opaque background cards from dark and light lockup SVGs to eliminate visual clipping in GitHub markdown.

---

## [2.3.2] - 2026-11-06

### Added
- One-click keyboard backlight toggle button on the menu bar keyboard icon to switch illumination on or off immediately.
- Hardware state synchronization on menu bar popover appear, automatically pulling active keyboard backlight and master volume levels.

### Changed
- Isolated menu bar slider rows into dedicated subviews to prevent parent view re-renders and redundant display queries during dragging.
- Forwarded keyboard and audio `objectWillChange` notifications to `AppState` for unified reactive observation.

### Fixed
- Fixed un-smooth and jittery keyboard brightness slider by removing asynchronous runloop dispatch and performing synchronous state updates on MainActor.
- Fixed volume slider jitter during rapid scrubbing by standardizing MainActor synchronous volume mutations.

---

## [2.3.1] - 2026-11-06

### Added
- Integrated satellite micro-buttons (Reset and Skip mode) directly inside the Pomodoro Corner Dial quadrant for immediate one-click actions.
- Round progression indicators with clean circular pips inside the center badge showing completed vs total intervals.
- Status bar title now retains countdown visibility while a session is paused.

### Changed
- Edge Slider is now completely hidden when idle (100% transparent and pushed off-screen with 0 pixels visible), smoothly gliding into view upon hovering near the screen edge.
- Idle Pomodoro dial arc precisely tracks the configured duration on the 60-minute dial without jumping to 100% on mouse release.

### Fixed
- Fixed gesture touch conflict on Corner Dial CenterActionBadge where clicking Play/Pause was misidentified as a radial drag, jumping session duration to 24 or 23 minutes.
- Fixed duration scrubbing in CornerDialView: drag events within radius 58 are ignored to protect the Play button, and minimum drag distance is enforced.
- Fixed Pomodoro settings synchronization where saving preferences would reset custom scrubbed minutes back to 25.

---

## [2.3.0] - 2026-11-06

### Added
- Industry-standard 1-click in-place background auto-update engine powered by Sparkle 2 (`SPUStandardUpdaterController`).
- Cryptographic update signature verification using Apple `CryptoKit` with Ed25519 (EdDSA) and automated `appcast.xml` feed synchronization.
- Release packaging pipeline producing universal distribution DMG installers and signed update ZIP archives.
- Automated GitHub Actions release workflow building universal binaries, signing archives, and publishing releases on tag pushes.
- Audio output device selector dropdown in Menu Bar extra popover for switching between connected headphones, speakers, and external displays.
- Quick mute toggle button integrated directly into the Menu Bar speaker icon and Corner Dial center badge.
- Multi-monitor brightness controls in Menu Bar extra popover displaying independent sliders, monitor names, and device icons.
- Persistent display brightness profiles saving user brightness levels and hardware control methods per display UUID.
- Application Profiles management in Settings > Hot Corners allowing custom corner and edge control mappings per app.
- Edge Sliders right-edge gesture slider with outer screen boundary geometry and pass-through hit testing.
- Dynamic global hotkey parser and real-time conflict detection against macOS system reserved combinations.
- Comprehensive JSON backup and restore capturing both application preferences and custom application profiles.

### Changed
- Migrated deprecated AudioHardwareService APIs to modern CoreAudio AudioObject APIs with zero compiler warnings.
- Cleaned obsolete toggle dock shortcut references and synchronized string catalogs across English and Vietnamese.

### Fixed
- Fixed Swift 6 strict concurrency compiler warnings across AppearanceManager, SystemPermissionService, and AutoUpdateManager.
- Fixed Volume dial center badge to display MUTE indicator and toggle mute state upon tap.
- Fixed unlocalized Active Method label in DisplaysTab.

---

## [2.2.0] - 2026-11-06

### Added
- Full Pomodoro cycle state machine supporting Focus Sessions, Short Breaks, Long Breaks, and configurable round progression.
- Live Menu Bar countdown text indicator (e.g. `24:50`) and dynamic active icon synchronization via Combine subscribers.
- Redesigned Menu Bar popover Focus Timer card with Play/Pause, Skip mode, Reset action, and mini progress bar.
- Persistent snapshot serialization restoring active or paused sessions across application restarts.
- Mode-aware corner dial indicators with purple (Focus) and emerald green (Break) progress rings.
- Instant screen wake synchronization eliminating refresh delay upon waking from macOS sleep.

### Changed
- Protected active Pomodoro sessions in `CornerDialView` from accidental cursor drag resets; duration scrubbing is now enabled when idle.
- Modernized `PomodoroTab` in Settings with live state monitoring card, round indicators, and full Apple String Catalog integration.

### Fixed
- Fixed Start button failure from `.idle` and `.completed` states in `PomodoroEngine`.
- Fixed `reset(toDurationSeconds:)` ignoring custom focus duration and forcefully defaulting to 25 minutes.
- Fixed dead settings in `PomodoroTab` where break durations, rounds before long break, and auto-start breaks were disconnected from runtime logic.
- Fixed hardcoded English notification strings and inline ternary units in Pomodoro UI.

---

## [2.1.1] - 2026-11-06

### Fixed
- Fixed interface language switching in Settings > General: UI labels, toolbar tabs, status bar popup, and in-app User Guide now update dynamically upon selecting Vietnamese (`vi`), English (`en`), or System Default.
- Integrated Apple String Catalog (`Localizable.xcstrings`) and thread-safe `LocalizationService` in `MacStashCore` with 150 translated keys and zero emojis.
- Added comprehensive unit test coverage (`LocalizationTests`) validating language resolution, key symmetry, Vietnamese diacritics, and dynamic fallback.

---

## [2.1.0] - 2026-11-06

### Added
- Official brand identity and app icon: "The Radial Corner Bloom", embodying the physical hot corner dial mechanics.
- Multi-layered vector asset catalog (`background.svg`, `foreground.svg`, `mono.svg`) compliant with Apple Human Interface Guidelines and Liquid Glass requirements.
- Native monochrome Menu Bar template images (`stash_menubar` at 18pt @1x/@2x/@3x) with dynamic active Pomodoro state indication (`stash_menubar_active`).
- Reusable `StashBrandLogoView` component integrated across About tab, Onboarding flow, Menu Bar popover, and User Guide.
- Reproducible asset rendering pipeline (`scripts/render_icons.sh`) producing `.icns`, PNG scale pyramids, vector PDFs, social preview banners, and favicons.
- Professional DMG distribution pipeline (`scripts/build_dmg.sh`) featuring custom drag-and-drop installer background artwork and `.VolumeIcon.icns`.
- Comprehensive design specification suite in `Design/Logo/`: Brief & Research (`01-brief.md`), Concepts (`02-concepts.md`), Refinement & Testing (`03-refinement.md`), Rationale (`04-rationale.md`), Icon Composer Guide (`05-icon-composer-guide.md`), and Asset Licenses (`LICENSES.md`).

### Changed
- Replaced generic placeholder symbols in status bar, onboarding, and about panels with official brand mark.
- Added Design Governance section to `AGENTS.md` designating SVGs in `Design/Logo/source/` as the single source of truth.
- Updated User Guide (both English and Vietnamese editions) with brand identity and status bar appearance documentation.
- Standardized all Vietnamese documentation across Docs/Guide/vi/ and Design/Logo/ with complete diacritics and typography.

---

## [2.0.0] - 2026-11-06

### Added
- Core domain model, overlay state machine, and hardware display services in `MacStashCore`.
- Multi-monitor support across MacBook built-in Retina displays and external monitors via DDC/CI and Software Dimming.
- Pass-through hit-testing architecture with configurable dwell delay and sensitivity thresholds.
- Monotonic Pomodoro focus timer engine with radial progress visualization.
- Automated domain unit test runner with 67 assertions.
