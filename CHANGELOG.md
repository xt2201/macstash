# Changelog

All notable changes to MacStash are documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [2.11.0] - 2026-11-09

### Added
- Second Dock (Auxiliary Live Widget & Application Dock): Introduced a customizable auxiliary dock running alongside macOS native Dock without interception or overlap, supporting both Fixed Bottom (docked above native Dock with >= 0px clearance) and Floating window layouts.
- Live Widget Framework & Registry: Standardized `DockWidget` architecture powering 10 local live widgets: Clock (digital, analog, flip), Date (untruncated month and weekday), Weather (Open-Meteo offline-first weather without mandatory GPS), Now Playing (Apple Music & Spotify controller with freshness TTL), Calendar (next upcoming event with countdown and meeting join buttons), Reminders (upcoming checklist with fast toggle and task addition), System Stats (CPU, RAM, battery metrics via kernel mach APIs and IOKit), Pomodoro timer, Search bar (instant Spotlight launcher), and File Shelf (drag-and-drop holding tray).
- Multi-Profile Dock Management: Switch between up to 8 independent dock workspaces (Default, Focus, Coding, Media) via built-in switcher or hotkeys, with real-time profile duplicate, rename, and isolation.
- Glass Backdrop Themes: System-adaptive Light Glass, Dark Glass, Liquid Glass, and Clear frameless visual appearances with customizable scale, tile spacing, and edge offsets.
- Click Pass-Through & Edge Auto-Hide: Native non-activating `NSPanel` (`.canJoinAllSpaces`) that does not steal focus, passes clicks on empty/transparent regions directly to underlying windows, and supports proximity auto-hide with 0.0-3.0s configurable reveal delay.

---

## [2.10.0] - 2026-11-09

### Added
- Flush Corner Dial Alignment: Anchored all 4 corner dials flush against the physical monitor corners with zero offset, directing window shadow padding exclusively towards the display interior.
- Stash Shelf Local Disk Persistence: Added persistent JSON storage (`StashShelfStorage`) preserving stashed files, links, and snippets across reboots and app updates.
- Drawer Pinning & Clear Undo: Added Pin toggle buttons to both Stash Shelf and Scratchpad headers to keep drawers open during multi-window workflows, plus instant Undo recovery for cleared items.
- High-DPI Retina Icon Cache: Upgraded `StashIconCache` with high-resolution 2x backing bitmap representations for crystal-clear icon rendering on Retina displays.
- Scratchpad Debounce & Zero-Allocation Counter: Optimized text saving with a 400ms debounce to eliminate main-thread disk I/O freezes, and replaced array-allocating string splits with an O(N) zero-allocation scalar word counter.
- Left Edge Extreme Dwell Trigger: Calibrated left edge activation to match the precision behavior of Right Edge Bar — requires pushing the cursor flush against the physical left screen edge with dwell detection before sliding open.

### Changed
- Zero-Obtrusion Left Edge: Removed the persistent thin peek handle along the left screen border, allowing 100% unobstructed clicks and interactions with underlying background applications and left-docked panels.

### Fixed
- Eliminated Ghost Corner Dwell Pop: Re-verified cursor position strictly against hot corner sensitivity radius upon dwell timer completion, preventing dials from popping open after the cursor has left the corner.
- Background Application Click Pass-Through: Throttled mouse tracking events to eliminate task churn, and scoped corner panel hit testing to within dial radius + 5pt so transparent window margins pass all mouse clicks through to underlying apps.
- Left Drawer Hit-Testing & Window Clipping: Expanded left edge NSPanel to 410pt and aligned hit-testing bounds to 352pt (Shelf) and 382pt (Scratchpad), fixing unclickable buttons on the right edge of drawers.
- Direct Image Drops: Added support for dropping raw image representations (TIFF/PNG from browsers and screenshots) directly onto Stash Shelf.

---

## [2.9.9] - 2026-11-09

### Added
- Tactical HUD Precision Instrument Hub: Re-engineered Corner Dial center action hubs with studio-grade optical glass bezels, multi-color hierarchical SF Symbols, and precision micro-typography with tabular digits.
- Inner Concentric Guide Ring: Introduced a laser-etched concentric guide arc framing the center hub into the radial dial, unifying radial perspective across all 4 quadrants.

### Fixed
- Stash Shelf Auto-Dismiss on Mouse Exit: Implemented continuous boundary monitoring in `ScreenManager` that automatically schedules a smooth auto-close timer when the cursor exits the left shelf drawer into the workspace, while safely preserving openness during active drag-and-drop operations.
- Multi-Monitor Menu Bar Popover Screen Targeting: Fixed AppKit bug where clicking the menu bar app icon on a secondary/Mac screen mistakenly dropped down the popover on the external monitor. Ensured anchor windows are strictly created on the clicked monitor coordinate space with post-presentation bounding verification.
- Radial Dial Mathematical Symmetry & OCD Balance: Re-aligned the central hub along the exact 45° diagonal axis of symmetry, maintaining uniform clearance to both adjacent screen borders (19pt) and balanced distance to the arc track.
- Symmetrical 4-Quadrant Tick Marks: Upgraded dial tick count to 21 with major indicator lines placed symmetrically at 0%, 25%, 50%, 75%, and 100%, and removed rogue white meniscus tick artifacts.

---

## [2.9.8] - 2026-11-09

### Fixed
- Fixed Right Edge Bar not opening on multi-monitor / external displays: Eliminated per-instance dwell timer cancellation in `ScreenManager` cursor tracking, allowing the extreme edge dwell detector to inspect all screens and schedule dwell without non-candidate displays immediately cancelling it.
- Fixed boundary clipping on physical screen edges: Replaced open-interval `CGRect.contains` check with an inclusive boundary test (`x >= maxX - 2.5 && x <= maxX + 1.0`), guaranteeing that cursors pushed directly to `maxX` on external displays are reliably detected.
- Per-display Right Edge Bar activation: Scoped edge slider expansion and hit-testing interactivity strictly to the active target display (`appState.activeDisplayID`), ensuring edge panels on other connected displays stay idle without intercepting underlying application clicks.
- Improved multi-display outer boundary geometry: Enhanced `isOuterRightEdge` and `isOuterLeftEdge` in `CornerGeometry` to use robust interval overlap checks that reliably handle vertically offset or differently sized external displays.

---

## [2.9.7] - 2026-11-09

### Added
- The Liquid Docking Bay (Stash Shelf): Elevated the left-edge drop shelf with interactive liquid ripple aura on file hover, frosted glass item tiles with 3D hover lift, and circular glass micro-action pills.
- Drag-and-Drop Drop Target Feedback: Added animated drop indicator banner when dragging files over populated shelf items and expanded dropped type recognition to support legacy file lists and string URLs.
- Bidirectional Shake-to-Summon Gesture: Upgraded shake detection to monitor both horizontal and vertical mouse direction reversals with a responsive 12pt threshold and 0.75s window.

### Fixed
- Stash Shelf Performance & Lag Elimination: Replaced synchronous LaunchServices icon extraction and disk queries during SwiftUI view passes with high-performance in-memory caching (`StashIconCache`). Isolated item hover state inside dedicated `StashItemCardView` subviews to eliminate full-list view invalidations, maintaining silky-smooth 120 FPS scrolling and interaction.
- Stash Shelf Drag Latency Fix: Replaced `NSItemProvider(contentsOf:)` with `NSItemProvider(object: url as NSURL)` in `createItemProvider`, eliminating synchronous temporary file copy operations on the main thread and making dragging files out of the shelf instantaneous. Removed conflicting double-tap recognizer delays on draggable cards.
- Left-Edge Peek Handle & Hover Hit-Testing: Fixed narrow 4pt hit zone clipping that caused rapid hovering/collapsing jitter. Unified hit-test and hover bounds across `ScreenManager`, `StashShelfHostingView`, and `LeftEdgeContainerView` (44pt width, 84pt height), allowing single-click opening and rock-solid button interactions.

---

## [2.9.6] - 2026-11-09

### Added
- Apple Liquid Glass Design System: Re-architected all floating overlay panels with high-fidelity optical realism (`LiquidGlassMaterial`), featuring multi-layer frosted refraction, dual-path specular rim bevels reflecting 135° virtual light, caustic ambient color halos, and soft depth shadows.
- Sculpted Liquid Glass Radial Corner Dials: Transformed the 4 corner hot vertex dials with 3D sculpted quarter-circle glass backdrops, luminous fluid arc gauges with droplet meniscus heads, laser-etched tick marks that illuminate as liquid sweeps across them, and floating glass jewel action badges.
- Crystal Tube & Dynamic Now Playing Aura: Re-architected the vertical edge slider into a precision crystal tube with glowing fluid volume (`LiquidVerticalTrack`), and infused the Now Playing controller with dancing fluid visualizers and real-time album artwork aurora reflections.
- Floating Glass Writing Slate (Scratchpad): Refined ephemeral scratchpad drawer with translucent glass surface, glowing emerald accent rim, and floating capsule word/char counter.
- Liquid Glass Compass (Cursor Radial Palette): 4 magnetic fluid petals expanding toward cursor with surface tension on Ultrawide monitors.
- Interactive Liquid Glass Studio Stage (Preferences): Added real-time interactive preview canvas in Settings > Appearance, allowing live testing of dial radius, glass opacity, fluid scrubbing, and tactile haptic/sound detents.

---

## [2.9.5] - 2026-11-09

### Fixed
- Fixed menu bar popover overlapping the macOS menu bar: Replaced obsolete hardcoded `350pt` content size with dynamic intrinsic sizing (`updatePopoverContentSize`) computed prior to popover presentation. This anchors the popover window strictly below the status item button and ensures all content expansion flows downwards without covering the top menu bar or protruding off-screen.
- Enhanced status item click detection: Added button window frame boundary verification with margin inset to guarantee clicks on the menu bar status icon are reliably routed to the physical status button without spawning misaligned anchor panels on external displays.

---

## [2.9.4] - 2026-11-09

### Fixed
- Fixed Right Edge Slider premature expansion: Removed hover state expansion from the 80pt slider container and tightened edge detection strictly to the physical display boundary (`<= 2.0pt`) with a 150ms intentional dwell delay, completely eliminating unintended slider popouts when moving mouse near the right margin.
- Fixed bidirectional macOS Silent / Mute synchronization: Added CoreAudio property listeners for `kAudioDevicePropertyMute` and scalar volume, alongside a 0.5s background polling synchronization to instantly reflect system-level mute changes.
- Added 1-Click Silent / Unmute toggle: Clicking the volume icon on the Right Edge Slider or the center action badge on the Bottom-Right corner dial now immediately toggles system mute/unmute with tactile haptic and audio feedback.
- Restored visual silent feedback: When muted, both the corner dial and right edge slider drop to 0 level, display a red `speaker.slash.fill` icon, and show a clear `MUTE` label.

---

## [2.9.3] - 2026-11-09

### Fixed
- Fixed corner dial swipe directions: Unified physical gesture dynamics across all 4 screen corner dials (Bottom-Right volume, Top-Right brightness, Bottom-Left timer, Top-Left keyboard brightness). Swiping fingers UP or RIGHT now consistently and intuitively increases values, while swiping DOWN or LEFT decreases values.
- Fixed radial gauge filling orientation: Corrected Bottom-Left and Top-Right radial gauges so that 0% starts at the lowest perimeter and rises upward to 100%, perfectly synchronizing visual arc filling with natural finger swiping.
- Resolved local application running state: Replaced running application in `/Applications/Stash.app` with fresh universal binary release, preventing obsolete 2.9.1 instances from exhibiting old detached hover boxes.

---

## [2.9.2] - 2026-11-09

### Fixed
- Fixed Right Edge Bar clipping on screen edge: Eliminated layout overflow from detached flyout card in media controls, restoring crisp 8pt margins and unclipped rounded borders on both left and right sides.
- Fixed glitchy floating artwork card: Replaced overflowing detached hover box with native macOS tooltips and click-to-activate gesture on album artwork.
- Streamlined Edge Media Controller to strict 50pt column width, guaranteeing zero layout shifts or rightward drift.

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
