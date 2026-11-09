# What's New in Version 2.9.0

MacStash 2.9.0 brings a comprehensive professional UX/UI upgrade, extreme-edge intentional dwell triggering for the Right Edge Slider, intuitive two-axis directional trackpad gestures for corner dials, double-click file launching on Stash Shelf, and complete elimination of edge click blockage.

## Key Enhancements in Version 2.9.0

- Extreme Edge Trigger & Dwell Delay: The Right Edge Slider now strictly requires moving the cursor to the physical edge boundary (x >= maxX - 3.0) with an intentional 180ms dwell delay, allowing you to use window scrollbars, editor minimaps, and rightmost click targets in Safari, Chrome, and Xcode without accidental activations.
- Natural Directional Scrolling for Corner Dials: Synchronized trackpad and mouse wheel vectors with macOS Natural Scrolling via event.isDirectionInvertedFromDevice. Swiping fingers UP or RIGHT naturally increases volume and settings across all corner dials.
- Lateral Two-Axis Vector Projection: Added horizontal trackpad delta support, enabling intuitive two-finger lateral scrubbing along the radial arc.
- Complete Elimination of Edge Click Blockage: Collapsed edge hosting views return nil for hit-testing and restrict resting peek handles to centered 64pt strips, keeping Finder sidebars, Slack workspaces, and browser tabs 100% accessible.
- Double-Click to Open on Stash Shelf: Double-clicking any file, image, or link on Stash Shelf immediately launches it with the default macOS application.
- Outside-Click Auto-Dismiss: Clicking anywhere outside Stash Shelf, Scratchpad, or expanded Right Edge Slider immediately dismisses the floating overlays.

# What's New in Version 2.8.1

MacStash 2.8.1 resolves a critical startup crash caused by Swift Package Manager resource bundle resolution in packaged application bundles, and improves first-mouse interaction responsiveness.

## Key Enhancements in Version 2.8.1

- Elimination of Launch Crash: Replaced SPM auto-generated Bundle.module lookups with standard macOS Bundle.main resource access, eliminating the startup crash (could not load resource bundle) on updated application bundles.
- Strict macOS Bundle Architecture Conformance: Cleaned up Swift Package definitions so that resources are bundled directly under Contents/Resources without triggering invalid root bundle lookups.
- Immediate First-Mouse Corner Dial Response: Corner dials now immediately process your click without requiring an initial focus click.

# What's New in Version 2.8.0

MacStash 2.8.0 delivers a premier macOS UX/UI overhaul, zero-footprint background mouse pass-through, shake-to-summon drag gestures, key window typing focus for Quick Scratchpad, immediate first-mouse responsive clicks, and total size metrics.

## Key Enhancements in Version 2.8.0

- Shake-to-Summon Drag Gesture: Simply wiggle or shake the mouse cursor back and forth while dragging any file, photo, or text snippet to instantly summon the Stash Shelf at your cursor with tactile mechanical detents.
- Zero-Footprint Mouse Pass-Through: Floating edge panels now strictly set ignoresMouseEvents = true when idle, ensuring background macOS applications (Finder sidebar, Safari tabs, Xcode editor, Terminal) receive 100% of mouse clicks without any edge blockage or interception.
- Non-Intrusive Edge Peek Affordance: Replaced intrusive permanent floating edge bars with an ultra-sleek, 3.5pt resting glass notch that expands into an interactive quick launcher only upon intentional cursor hover.
- Immediate First-Mouse Responsive Clicks: Integrated InteractiveHostingView and MacStashInteractivePanel across all floating overlay surfaces, ensuring action buttons (Clear All, Copy Path, Reveal in Finder, Delete, Close) trigger reliably on the very first click without discarded activation clicks.
- Key Window Focus for Quick Scratchpad: Scratchpad now dynamically gains key window status on summon, allowing immediate typing, text selection, and standard macOS keyboard shortcuts (Cmd+A, Cmd+C, Cmd+V, Cmd+Z, Esc).
- Copy All Files & Total Size Metrics: Added one-click "Copy All" and live formatted total file size (X items · Y MB) in Stash Shelf header.

# What's New in Version 2.7.0

MacStash 2.7.0 delivers a premier macOS UX/UI overhaul, zero-footprint background mouse pass-through, shake-to-summon drag gestures, key window typing focus for Quick Scratchpad, immediate first-mouse responsive clicks, and the native MediaRemote platform-binary bridge.

## Key Enhancements in Version 2.7.0

- Shake-to-Summon Drag Gesture: Simply wiggle or shake the mouse cursor back and forth while dragging any file, photo, or text snippet to instantly summon the Stash Shelf at your cursor with tactile mechanical detents.
- Zero-Footprint Mouse Pass-Through: Floating edge panels now strictly set `ignoresMouseEvents = true` when idle, ensuring background macOS applications (Finder sidebar, Safari tabs, Xcode editor, Terminal) receive 100% of mouse clicks without any edge blockage or interception.
- Non-Intrusive Edge Peek Affordance: Replaced intrusive permanent floating edge bars with an ultra-sleek, 3.5pt resting glass notch that expands into an interactive quick launcher only upon intentional cursor hover.
- Immediate First-Mouse Responsive Clicks: Integrated `InteractiveHostingView` and `MacStashInteractivePanel` across all floating overlay surfaces, ensuring action buttons (Clear All, Copy Path, Reveal in Finder, Delete, Close) trigger reliably on the very first click without discarded activation clicks.
- Key Window Focus for Quick Scratchpad: Scratchpad now dynamically gains key window status on summon, allowing immediate typing, text selection, and standard macOS keyboard shortcuts (Cmd+A, Cmd+C, Cmd+V, Cmd+Z, Esc).
- Copy All Files & Total Size Metrics: Added one-click "Copy All" and live formatted total file size (X items · Y MB) in Stash Shelf header.
- Universal Browser & App Now Playing Capture on macOS 15.4+: Powered by a native platform-binary bridge (`now-playing.pl` and `libMacStashNowPlaying.dylib`) using `MRPlayerPath`, MacStash reliably captures live track title, artist, playback state, and full album artwork from any browser (including Crest playing SoundCloud, Safari, Chrome, Arc) as well as Spotify, Apple Music, and VLC.
- Artwork Dominant Color Tinting: Extracts the most vibrant dominant color palette directly from the current track's album cover to dynamically tint the 5-bar dancing equalizer, artwork border glow, and Play/Pause button.
- Real-Time Rhythm Visualizer Envelope: 30fps multi-band rhythm generator with fast attack and smooth decay that dances to the beat of the active audio session and rests smoothly when paused.
- 120Hz ProMotion EdgeBar Smoothness: Asynchronous CoreAudio hardware dispatch, readback jitter suppression, display profile caching, and debounced settings persistence deliver instant, butter-smooth vertical dragging and two-finger trackpad scrolling along the screen edge.

# What's New in Version 2.6.0

MacStash 2.6.0 introduces the signature Tactile Stash Drop Shelf, a Keep-Awake (Caffeine) radial timer, an instant Quick Scratchpad drawer, and a Cursor Radial Palette for Ultrawide monitors.

## Key Enhancements in Version 2.6.0

- Tactile Stash Drop Shelf: The core namesake feature of MacStash. A frosted glass drop shelf sliding smoothly from the left screen edge to hold files, images, links, and text snippets when dragging across spaces, displays, or apps.
- Keep Awake (Caffeine) Radial Timer: Hardware power assertion engine preventing screen and system sleep during video renders, terminal builds, and presentations, with preset dial notches (15m, 30m, 1h, 2h, and Indefinite), tactile mechanical detents, and Menu Bar quick status badge.
- Quick Scratchpad Drawer: Ephemeral glassmorphic notepad on the left screen edge with live word and character counters, automatic local persistence, and quick copy/clear actions.
- Cursor Radial Palette: Summons floating radial dials directly centered at the mouse cursor via global shortcut (Option + Space) for instant volume, brightness, keep-awake, and timer control without traversing across Ultrawide or multi-monitor screens.
- Global Keyboard Shortcuts: Configurable shortcuts for Cursor Palette (Option+Space), Stash Shelf (Control+Option+S), and Scratchpad (Control+Option+N).

# What's New in Version 2.5.0

MacStash 2.5.0 introduces customizable EdgeBar actions in Settings and a sleek vertical Universal Now Playing media controller under the Volume slider, featuring live album artwork, a dancing audio waveform visualizer, and vertical transport controls.

## Key Enhancements in Version 2.5.0

- EdgeBar Action Selector: Easily choose what action the screen edge slider performs in Settings (Volume, Display Brightness, Keyboard Backlight, Pomodoro Timer, or Disabled).
- Universal Now Playing Media Controls: When the EdgeBar is configured for Volume, an integrated vertical media controller appears directly beneath the slider, detecting currently playing media from any macOS application (Apple Music, Spotify, YouTube in Safari or Chrome, Podcasts, VLC).
- Live Album Artwork: Displays authentic album cover art with smooth rounded corners, glass borders, and soft shadows.
- Dancing Audio Waveform Visualizer: 5-bar animated audio equalizer in vibrant amber-orange gradient synchronized with playback and volume levels, smoothly resting on pause.
- Vertical Transport Controls: Convenient vertical button arrangement tailored for screen edges: Previous Track on top, Play/Pause in the middle, and Next Track at the bottom.
- Floating Track Details Tooltip: Hovering over the album artwork or media section smoothly reveals a floating card to the left with full track title, artist name, and album.
- Customizable Settings: Dedicated toggles in Settings > Hot Corners to enable or disable Now Playing media controls and the dancing audio visualizer.

# What's New in Version 2.4.0

MacStash 2.4.0 introduces two-finger trackpad scroll adjustment, full multi-monitor hot corner and edge slider reliability, instant click-to-activate corner dials, and multi-display top bar control popover expansion.

## Key Enhancements in Version 2.4.0

- Two-Finger Trackpad Scroll to Adjust: Seamlessly tune system volume, display brightness, keyboard backlight, and Pomodoro timer duration simply by scrolling with two fingers while hovering over active corner dials or edge sliders without requiring click-and-drag.
- Full Multi-Monitor Hot Corner Support: Resolves issues where display seam boundaries suppressed corner dials and edge sliders on secondary screens. All four corners on each connected display now trigger reliably.
- Instant Click-to-Activate: In addition to standard dwell delay activation, clicking directly into any screen corner immediately launches the corresponding control dial without waiting.
- Outer Corner Seam Suppression Toggle: Added a dedicated toggle under Settings > Hot Corners allowing users to choose whether to activate all screen corners or strictly outer desktop perimeter corners.
- Multi-Display Top Bar Popover: Clicking the MacStash icon in the top menu bar on any display (including external monitors) cleanly positions and expands the control popover on that exact display.
- Per-Display Brightness Scrubbing: Right edge slider correctly forwards display identifiers to independently adjust brightness on individual external monitors.
- Smart Momentum Protection: Automatic filtering of trackpad inertia phases prevents values from unintentionally running away after lifting fingers.

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
