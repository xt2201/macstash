# What's New in Version 2.10.0

MacStash 2.10.0 delivers seamless corner dial alignment that sits flush against physical monitor corners with zero offset, eliminates background polling and cursor tracking task churn, brings robust local disk persistence and pinning to the Stash Shelf, and introduces debounced saves and zero-allocation word counting to the Quick Scratchpad.

## Key Enhancements in Version 2.10.0

- Flush Corner Dial Alignment: Anchored all four corner dials flush against the physical monitor corners with zero offset gap, routing window shadow padding strictly towards the screen interior.
- High-Performance Cursor Tracking: Eliminated redundant 40ms polling timers and unstructured task churn on mouse move events, throttling tracking calculations and integrating OverlayStateMachine for flawless state transitions.
- Ghost Dwell Pop Elimination: Re-verified cursor coordinates strictly against the corner sensitivity radius when dwell timers expire, preventing dials from popping open after the mouse has moved away.
- Stash Shelf Local Disk Persistence: Added JSON disk storage via StashShelfStorage, retaining stashed files, links, and snippets across system restarts and application updates.
- Drawer Pinning and Clear Undo: Added quick pin toggle buttons to both Stash Shelf and Scratchpad headers to keep drawers open during multi-window tasks, alongside instant Undo recovery for accidentally cleared items.
- High-DPI Retina Icon Cache: Upgraded StashIconCache with high-resolution 2x backing bitmap representations, delivering pixel-perfect file icons on Retina screens.
- Scratchpad Debounce and Zero-Allocation Counter: Optimized text persistence with a 400ms debounce to eliminate main-thread freezes, and replaced array-allocating string splits with an O(N) zero-allocation scalar word counter.
- Left Drawer Hit-Testing Alignment: Expanded left edge NSPanel to 410pt and aligned hit-testing bounds to 352pt (Shelf) and 382pt (Scratchpad), fixing unclickable buttons on the right edge of drawers.
- Direct Image Drops: Added support for dropping raw image representations (TIFF/PNG from browsers and screenshots) directly onto Stash Shelf.

# What's New in Version 2.9.9

MacStash 2.9.9 delivers automatic drawer dismissal on mouse leave for the Stash Shelf, resolves multi-display menu bar popover placement issues, establishes absolute mathematical symmetry across Corner Dials, and introduces the Tactical HUD Instrument Hub with hierarchical iconography and precision micro-typography.

## Key Enhancements in Version 2.9.9

- Stash Shelf Auto-Dismiss on Mouse Exit: Added continuous edge drawer boundary monitoring in ScreenManager that automatically schedules a smooth auto-close timer when the cursor moves away from the left shelf drawer into the workspace, while keeping the shelf securely open during active drag-and-drop operations.
- Accurate Multi-Monitor Menu Bar Popover Placement: Resolved the AppKit window placement bug where clicking the menu bar app icon on a Mac built-in screen incorrectly displayed the popover on the external monitor. Anchor windows are strictly bound to the clicked monitor coordinate space with post-presentation bounding checks.
- Corner Dial Mathematical Symmetry & OCD Balance: Re-aligned the central action hub along the exact 45-degree diagonal axis of symmetry, maintaining uniform 19pt clearance to both adjacent screen borders and balanced spacing to the arc track.
- Symmetrical 4-Quadrant Tick Marks: Upgraded dial tick count to 21 with major indicator lines placed symmetrically at 0%, 25%, 50%, 75%, and 100%, and eliminated rogue white meniscus tick artifacts.
- Tactical HUD Precision Instrument Hub: Re-engineered Center Action Badges with studio-grade optical glass bezels, multi-color hierarchical SF Symbols, and precision micro-typography with tabular digits.
- Concentric Guide Ring: Added a laser-etched concentric guide arc framing the center hub into the radial dial, unifying radial perspective across all 4 quadrants.

# What's New in Version 2.9.8

MacStash 2.9.8 resolves the issue where the Right Edge Bar would not open when an external display was connected, delivering seamless multi-monitor edge dwell detection, inclusive physical boundary checks, and isolated per-display edge activation.

## Key Enhancements in Version 2.9.8

- Multi-Monitor Right Edge Bar Responsiveness: Fixed a race condition where non-candidate screens cancelled the edge dwell timer across displays, ensuring the slider opens reliably on any connected external monitor.
- Inclusive Physical Edge Boundary Detection: Replaced open-interval rectangle containment checks with inclusive boundary clamping (`x >= maxX - 2.5 && x <= maxX + 1.0`), recognizing cursor slams pinned directly to the rightmost bezel.
- Target Display Isolation: Right edge slider expansion and hit-testing are strictly scoped to the active display (`activeDisplayID`), keeping edge panels on other connected monitors completely passive.
- Robust Multi-Screen Geometry: Updated outer edge boundary calculations in `CornerGeometry` with continuous vertical interval overlap analysis, properly handling vertically offset or mismatched external monitors.

# What's New in Version 2.9.7

MacStash 2.9.7 delivers high-performance in-memory icon caching for the Stash Shelf, instant drag extraction without disk latency, unified left-edge peek handle hit-testing, and bidirectional shake-to-summon gestures.

## Key Enhancements in Version 2.9.7

- In-Memory Icon Caching & 120 FPS Scrolling: Eliminated main-thread LaunchServices queries during SwiftUI rendering with `StashIconCache`, maintaining silky-smooth list scrolling and zero interaction stutter.
- Zero-Latency Drag Out: Streamlined item provider generation with lightweight NSURL referencing, eliminating temporary file copy operations on drag start.
- Rock-Solid Peek Handle Summoning: Expanded left edge handle hit zone to 44pt with single-click activation, eliminating hover fluttering.
- Bidirectional Shake-to-Summon: Enhanced cursor shake gesture to detect both vertical and horizontal direction reversals with a 12pt threshold.
- Drag Feedback & Animated Banners: Introduced animated drop banners over populated shelf lists and expanded dropped item type recognition.

# What's New in Version 2.9.6

MacStash 2.9.6 introduces a comprehensive Apple-grade Liquid Glass UI/UX transformation across all floating overlay panels, sculpted 3D radial dials, glowing fluid volume tracks, and an interactive Liquid Glass Studio stage.

## Key Enhancements in Version 2.9.6

- Apple Liquid Glass Optical Shading: Re-engineered all floating overlay panels with multi-layer refraction, dual-path 135° specular bevel highlights, and dynamic caustic ambient illumination.
- Sculpted Radial Dials: 3D-curved glass quadrant backdrops with luminous fluid gauges, meniscus droplets, laser-etched illuminated notches, and floating glass jewel center badges.
- The Liquid Docking Bay: The Stash Shelf features an interactive liquid ripple aura on file hover, elevated glass file tiles, and circular glass micro-actions.
- Crystal Tube Slider & Dynamic Artwork Aurora: Precision crystal tube volume/brightness track with glowing fluid volume, dynamic album art aurora backlighting, and fluid dancing visualizers.
- Floating Glass Writing Slate: Ephemeral scratchpad drawer with translucent writing surface, glowing emerald rim, and floating capsule word/char counter.
- Liquid Glass Compass: 4-petal magnetic fluid palette blooming centered at the cursor for Ultrawide monitors.
- Interactive Liquid Glass Studio Stage: Live interactive preview in Settings > Appearance for tuning dial radius, glass opacity, and testing tactile haptics and mechanical clicks in real-time.

# What's New in Version 2.9.5

MacStash 2.9.5 resolves the layout overlap issue when clicking the application menu bar icon, ensuring the popover panel anchors properly below the top menu bar with dynamic intrinsic content sizing.

## Key Enhancements in Version 2.9.5

- Dynamic Popover Intrinsic Sizing: Eliminated the obsolete hardcoded 350pt content height constraint, dynamically measuring the full fitting size of the menu bar panel before presentation to anchor its top edge accurately beneath the menu bar.
- Downward Layout Expansion: Guaranteed that the menu bar popover expands strictly downwards and remains within visible screen bounds, eliminating upward drift over the macOS menu bar and notch.
- Enhanced Menu Bar Button Hit-Testing: Added boundary verification with margin inset for the status item window, ensuring clicks on the status item icon always route cleanly to the physical button.

# What's New in Version 2.9.4

MacStash 2.9.4 eliminates premature opening of the Right Edge Slider with strict extreme-edge boundary gating, delivers bidirectional macOS Silent/Mute hardware synchronization, and introduces 1-click silent toggling across all audio controls.

## Key Enhancements in Version 2.9.4

- Strict Physical Edge Triggering: The Right Edge Slider now strictly requires the cursor to touch the physical screen edge (within 2.0pt) and dwell intentionally, removing container hover expansions so background scrollbars and rightmost windows remain undisturbed.
- Bidirectional Silent / Mute Synchronization: Real-time hardware listeners for CoreAudio mute and volume events guarantee immediate reflection of macOS keyboard mute and Control Center changes.
- 1-Click Silent / Unmute: Clicking the speaker icon on the Right Edge Slider or the center action badge on the Bottom-Right dial toggles mute with tactile haptic confirmation.
- Distinct Visual Silent Indication: When muted, audio indicators clearly display a red speaker-slash icon, red MUTE label, and 0-level gauge tracks.

# What's New in Version 2.9.3

MacStash 2.9.3 harmonizes corner dial gestures and radial gauge filling across all four quadrants with intuitive, unified upward-increasing gesture physics.

## Key Enhancements in Version 2.9.3

- Unified Natural Swipe Directions: All four corner dials (volume, brightness, timer, keyboard brightness) now strictly follow unified gesture physics. Swiping UP or RIGHT turns values up; swiping DOWN or LEFT turns values down.
- Harmonized Gauge Filling: Aligned Bottom-Left and Top-Right radial gauges so 0% aligns at the bottom and 100% rises toward the top, matching visual arcs with physical finger movement.
- Local Deployment Verification: Automatically synchronizes and refreshes the installed application bundle in /Applications/Stash.app with the latest release build.

# What's New in Version 2.9.2

MacStash 2.9.2 eliminates layout shifting and screen edge clipping on the Right Edge Slider, ensuring all rounded borders remain fully visible and removing detached hover cards.

## Key Enhancements in Version 2.9.2

- Elimination of Edge Clipping: Removed width overflow from media controls, restoring crisp 8pt edge margins and fully unclipped rounded capsule borders.
- Streamlined Media Controls: Replaced overflowing detached hover popups with native macOS tooltips and click-to-activate app gestures on album artwork.
- Exact Layout Stability: Constrained the edge slider strictly to 50pt width, preventing rightward drift.

# What's New in Version 2.9.1

MacStash 2.9.1 refines the Right Edge Slider with perfect vertical screen centering, fluid spring slide-in and slide-out animations, and rapid auto-hide when the cursor departs the edge.

## Key Enhancements in Version 2.9.1

- Exact Vertical Screen Centering: The right edge bar is now precisely centered on the physical screen height across all displays.
- Fluid Spring Slide-In and Slide-Out: The slider view hierarchy remains active during dismissal, allowing spring slide-out animations to glide off-screen smoothly without popping out of existence.
- Reliable Auto-Hide on Mouse Exit: Integrated native AppKit NSTrackingArea callbacks and tightened the active footprint to 80pt, ensuring instant auto-hide when moving your cursor away from the screen edge.

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
