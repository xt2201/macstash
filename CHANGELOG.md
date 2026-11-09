# Changelog

All notable changes to MacStash are documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [2.9.1] - 2026-11-09

### Fixed
- Fixed vertical centering of Right Edge Bar: Edge slider is now precisely centered on the physical screen height across all display configurations.
- Fixed buttery-smooth slide-in and slide-out animation: Kept slider content in view hierarchy so spring exit animations glide off-screen smoothly without popping out abruptly.
- Fixed reliable auto-hide when cursor departs edge: Integrated native AppKit `NSTrackingArea` with `mouseExited` callbacks and reduced expanded hit zone from 260pt to the exact 80pt slider body, ensuring instant auto-hide when moving into background applications.

---

## [2.9.0] - 2026-11-09

### Changed
- Extreme Edge Trigger & Dwell Delay for Right Edge Bar: Right Edge Slider now strictly requires the cursor to reach the physical screen edge (`x >= maxX - 3.0`) with a 180ms intentional dwell delay, completely eliminating accidental triggers when interacting with window scrollbars or controls in background applications.
- Natural Directional Scrolling for Corner Dials: Synchronized trackpad and scroll wheel vectors with macOS Natural Scrolling via `event.isDirectionInvertedFromDevice`. Swiping fingers UP or RIGHT now naturally turns up volume on Bottom-Right corner dial and adjusts values across all quadrants.
- Two-Axis Vector Projection: Added horizontal scroll delta (`scrollingDeltaX`) support across corner dials, enabling fluid two-finger lateral scrubbing along the radial arc.

### Fixed
- Fixed background application click blockage on left and right edges: Collapsed edge hosting views now strictly return nil for hit-testing and restrict peek handle hit zones to 64pt centered strips, keeping Finder sidebars, Slack workspaces, and browser scrollbars 100% responsive.
- Fixed unclickable controls on Stash Shelf: Granted Key Window capability to Stash Shelf when active, ensuring immediate first-click responses for all action buttons and enabling keyboard shortcuts (Esc to close, Space to open).
- Added Outside-Click Auto-Dismiss: Clicking anywhere outside Stash Shelf, Scratchpad, or expanded Right Edge Slider immediately collapses the overlays and returns window focus to the underlying application.
- Added Double-Click to Open: Double-clicking any file, image, or link on Stash Shelf immediately launches it in the default macOS application.

---

## [2.8.1] - 2026-11-09

### Fixed
- Fixed fatal crash on startup (`could not load resource bundle: from /Applications/Stash.app/MacStash_MacStash.bundle`): Eliminated usage of SPM's auto-generated `Bundle.module` in favor of standard macOS `Bundle.main` resource loading, preventing launch assertion failures in standalone application bundles.
- Excluded unhandled resource folder from SPM executable target to prevent unwanted bundle accessor synthesis and ensure robust code signing conformance.
- Enhanced Corner Dials first-mouse responsiveness: Ensured immediate interaction on first click across all corner dials without requiring an initial window focus click.

---

## [2.8.0] - 2026-11-07

### Added
- Shake-to-Summon Drag Gesture: Wiggling or shaking the mouse cursor back and forth while dragging any file, image, or text snippet instantly summons the Stash Shelf right where you need it with tactile haptic feedback.
- Drag Proximity Auto-Bloom: Approaching the left screen edge while holding a dragged item smoothly expands the frosted glass drop zone with zero delay.
- Non-Intrusive Edge Peek Affordance: Replaced permanent floating edge bars with an ultra-sleek, 3.5pt resting glass notch that expands into an interactive launcher only on intentional hover.
- Immediate First-Mouse Interaction: Integrated `InteractiveHostingView` and `MacStashInteractivePanel` across all floating overlays, ensuring buttons (Clear All, Copy Path, Reveal in Finder, Delete, Close) trigger reliably on the very first click without discarded activation clicks.
- Key Window Focus for Quick Scratchpad: Scratchpad now dynamically gains key window focus on summon, allowing seamless typing, text selection, and keyboard shortcuts (`Cmd+A`, `Cmd+C`, `Cmd+V`, `Cmd+Z`, `Esc`).
- Copy All Files & Total Size Metrics: Added one-click "Copy All" and live formatted total file size (`X items · Y MB`) in Stash Shelf header.

### Fixed
- Fixed background app click blockage: Floating edge overlay panels now strictly set `ignoresMouseEvents = true` when idle, eliminating all mouse interception and ensuring full interactivity in underlying macOS applications (Finder sidebar, Safari tabs, Xcode editor, Terminal).
- Fixed Stash Shelf card gesture conflicts: Separated the draggable file body (`.onDrag`) from trailing action buttons so clicking Reveal in Finder, Copy Path, or Remove works instantaneously without being swallowed by drag recognizers.

---

## [2.7.0] - 2026-11-06

---

## [2.6.0] - 2026-11-06

### Added
- Tactile Stash Drop Shelf: the core namesake feature of MacStash. A frosted glass drop shelf sliding smoothly from the left screen edge to hold files, images, links, and text snippets when dragging across spaces, displays, or apps.
- Keep Awake (Caffeine) Radial Timer: hardware power assertion engine preventing screen and system sleep with preset dial notches (15m, 30m, 1h, 2h, and Indefinite), tactile mechanical detents, and Menu Bar quick status badge.
- Quick Scratchpad Drawer: ephemeral glassmorphic notepad on the left screen edge with live word and character counters, automatic local persistence, and quick copy/clear actions.
- Cursor Radial Palette: summons floating radial dials directly centered at the mouse cursor via global shortcut (`Option + Space`) for instant control without traversing across Ultrawide or multi-monitor screens.
- Global shortcuts for Cursor Palette (`Option+Space`), Stash Shelf (`Control+Option+S`), and Scratchpad (`Control+Option+N`).

---

## [2.5.0] - 2026-11-06

### Added
- EdgeBar Action Selector in Settings: easily customize edge slider actions (Volume, Brightness, Keyboard Backlight, Pomodoro Timer, or Disabled).
- Universal Now Playing Media Controls: integrated vertical media module below Volume slider featuring live album artwork and vertical playback buttons (Previous on top, Play/Pause in middle, Next at bottom).
- Dancing Audio Waveform Visualizer: 5-bar animated audio equalizer in vibrant amber-orange gradient synchronized with playback and volume levels, smoothly resting on pause.
- Floating Track Details Tooltip: hover over album artwork to preview full track title, artist name, and album.
- Settings toggles for Now Playing Media Controls and Dancing Visualizer under Volume.

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

---

## [2.3.5] - 2026-11-06

### Added
- Dynamic version inspection across Settings, About tab, and localization layers.
- Automated version consistency test suite enforcing semver compliance across 6 source-of-truth locations.
- Resilient release packaging script with safe fallbacks for optional PDF generation tools.

---

## [2.3.4] - 2026-11-06

### Added
- Guaranteed Pomodoro completion notifications on macOS via UNUserNotificationCenter foreground presentation delegates.
- Audible alert chime and trackpad haptic detents upon interval completion.
- Dock icon attention bounce request when focus or break sessions finish.

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
