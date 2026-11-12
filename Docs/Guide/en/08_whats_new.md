# Release Notes & Changelog

## Version 2.16.7 (2026-11-12)

### In-Place Dynamic Island Audio Expansion & Zero-Jump Polish

- **In-Place Horizontal Audio Expansion**: When hovering over the album artwork thumbnail to scrub audio, the Dynamic Island now smoothly expands horizontally right where the artwork capsule is. It no longer spontaneously shifts upward to the screen center, keeping your pointer directly inside the controls.
- **Stable Volume Column Dropdown**: Moving to the volume button smoothly reveals the vertical volume slider above the island while the Dynamic Island remains solidly anchored in place.
- **Accurate Trackpad Scrubbing Hit Zone**: Refined the interaction area and volume button detection coordinates, guaranteeing 100% reliable two-finger scrubbing without hover loss.

---

## Version 2.16.6 (2026-11-12)

### Edge Bar Vertical Centering & Screen Placement Symmetries

- **Symmetrical Vertical Centering for Edge Sliders**: Both Left and Right Edge Sliders are now positioned at the exact vertical center of the screen. Inside the panel, the slider content is vertically centered instead of anchored to the bottom, ensuring the slider appears right at the cursor position without any vertical displacement.
- **Harmonious Edge Slider and Drawer Coexistence**: Resolved dwell timer overlap between Edge Sliders and Left Edge Drawer when sharing an edge. Normal cursor dwell now reveals the Edge Slider at the vertical center, dragging files from Finder smoothly opens Stash Shelf to receive drops, and Edge Sliders stay hidden while the drawer is open.
- **Symmetrical Dynamic Island Hit Zone**: Updated the hit testing area for the expanded Dynamic Island and dropped-in volume slider to match the vertically centered layout.

---

## Version 2.16.5 (2026-11-12)

### Dynamic Island Two-Finger Scrub & Volume Hover Fixes

- **Fixed Horizontal Two-Finger Scrub Direction**: Swiping right with two fingers on the expanded Dynamic Island audio scrubber (as well as Corner Dials and Cursor Palette) now seeks forward accurately under both Natural Scrolling ON and OFF, matching vertical up/down scrub ergonomics.
- **Volume Icon Hover Mode Switching**: Moving the pointer onto the Dynamic Island's outer-edge Volume icon immediately switches two-finger swiping (both up/down and right/left) from audio scrubbing to system volume control, while moving back to the scrubber immediately restores audio seeking.

---

## Version 2.16.4 (2026-11-12)

### Critical Launch Stability Hotfix

- **Fixed App Hang After Updating to v2.16.3**: Resolved an infinite SwiftUI view re-evaluation loop at startup caused by mutating `@Published` keyboard backlight state inside `CornerDialView`'s rendering pass. MacStash now launches instantaneously with near-zero idle CPU usage.
- **Pure Hardware Read Architecture**: Separated non-mutating hardware reads (`currentHardwareBrightness()` and `readBrightnessLevel(for:)`) for SwiftUI rendering from periodic hardware syncs, and guarded audio/brightness/keyboard publishers against redundant updates when physical values have not changed.

---

## Version 2.16.3 (2026-11-12)

### Audio Scrubbing Mechanics, Scrubber Alignment & Hit-Testing Audit

- **Vertical Two-Finger Audio Scrubbing in Dynamic Island**: Once hovered over audio to reveal the Dynamic Island panel, vertical two-finger swipes (up = forward, down = backward) scrub playback directly without accidentally changing system volume. System volume adjusts only when explicitly moving the pointer into the dropped-down volume bar.
- **Exact Trackpad Seeking Engine**: Fixed the underlying MediaRemote `SeekToPlaybackPosition` command (`24`), added targeted player PID routing, Spotify/Apple Music AppleScript fallback, and seek-grace synchronization so scrubbed positions stick accurately.
- **Sub-Pixel Scrubber Dot Alignment**: Fixed scrubber thumb scaling order so the circular indicator always stays aligned with the progress bar fill and current timestamp from 0% to 100%.
- **Overlay Coordinate & Full-System Polish**: Unified coordinate conversion in `hitTest` across all corner dials, drawers, edge bars, and SideDock; added Escape key dismissal for Left Edge Slider and dials; prevented Left Drawer and Left Slider overlap; and added keyboard backlight hardware synchronization.

---

## Version 2.16.2 (2026-11-12)

### Edge Bar Stability Fix

- **Edge Bar no longer disappears when hovering the audio artwork**: The interactive area of the Edge Bar is now tall enough to contain the full bar, so opening the Dynamic Island audio controls keeps the bar on screen.
- **Stable Edge Bar window size**: The Edge Bar window keeps a fixed size so its hit zone always matches what you see.

---

## Version 2.16.1 (2026-11-12)

### Two-Finger Trackpad Audio Scrubbing, Settings Polish & Dial Clearance

- **Two-Finger Trackpad Audio Scrubbing**: Hovering over the Edge Bar media island or a corner dial allows two-finger horizontal trackpad swiping to scrub backward or forward through the current track. Features natural scrolling inversion, duration-adaptive physical scaling, 120fps visual feedback, and tactile 5-second haptic detent ticks.
- **Dynamic Island Outer-Edge Volume Dropdown**: Placed a dedicated Volume Logo button at the screen-outermost edge of the Dynamic Island (to the right of Next on the right edge, to the left of Previous on the left edge). Hovering reveals the matching vertical volume slider flush against the screen border with artwork glass tint.
- **Settings Card Anti-Clipping Standards**: Overhauled Segmented Pickers in SettingsCard across Hot Corners, General, Appearance, and Displays tabs into full-width vertical stacks with independent left/right edge configuration rows, preventing text clipping and card border overflow in all languages.
- **Corner Dial Polar Non-Overlap Guarantee**: Mathematically re-engineered center badge and satellite coordinates to guarantee >= 8.0pt clearance at standard dial sizes and >= 3.0pt clearance down to 110pt, eliminating any overlap between Play/Pause and the Center Action Badge.
- **Live Scrubber Time Synchronization**: Fixed playback position reset bug on hover; live player position continuously reflects active Spotify, Music, or system media playback with monotonic timestamps.

---

## Version 2.16.0 (2026-11-11)

### Dynamic Island Audio, Dual Edge Bars & Standalone Media Scrubber

- **Dynamic Island Horizontal Audio Expansion in Edge Bar**: Hovering over the compact artwork capsule smoothly morphs it outward horizontally into a Dynamic Island widget featuring song title, artist, live audio visualizer, interactive scrubber bar, and 5-button transport controls, keeping the vertical Edge Bar height permanently compact.
- **Dual Edge Bars (Simultaneous Left & Right Support)**: You can now enable and configure both Left and Right edge bars simultaneously (default: Both Sides), each with its own independent action assignment (e.g. Left Edge for Brightness / Media Scrubber, Right Edge for Volume).
- **Dedicated Media Player & Audio Scrubber Action**: Added a standalone `mediaPlayback` control action for Hot Corners and Edge Bars, turning the corner dial into a dedicated media jog wheel and the edge slider into an interactive audio track scrubber.
- **Hot Corner Volume Satellite Overlap Fix**: Repositioned volume satellite controls (Rewind 10s, Play/Pause, Forward 10s) to an inner orbit radius with ample breathing room, eliminating visual overlap with the outer volume arc track.

---

## Version 2.15.0 (2026-11-11)

### Real-Time Hardware Sync, Audio Scrubbing & Utility Corners

- **Live Hardware Synchronization**: Synchronously queries physical display brightness and master CoreAudio volume directly from macOS private frameworks and hardware services. Keyboard brightness adjustments (e.g. F1/F2 keys) and volume keys immediately update hot corner dials and edge bars without state drift.
- **Audio Seeking & Transport Controls**: Added full audio scrubbing support to both Edge Bars and Corner Dials. Includes interactive draggable seek bar, Skip Forward 10s (`goforward.10`), Skip Backward 10s (`gobackward.10`), and live time readouts (`1:24 / 3:45`) supporting Apple Music, Spotify, and system media.
- **Hot Corner File Drop & Utility Satellites**: Dragging files to a hot corner mapped to Stash Shelf immediately stores them. When hovering utility corners, satellite micro-controls provide 1-click access to open full drawers, copy notes, toggle indefinite caffeine, or clear items.
- **Edge Bar Utility Cards**: Edge Bars mapped to Scratchpad, Stash Shelf, or Caffeine display dedicated quick cards and stepped presets (OFF, 15m, 30m, 1h, 2h, ∞) rather than generic sliders.
- **Auto-Provisioned Utility Panels**: Configuring any corner dial or edge bar to Scratchpad or Stash Shelf automatically mounts the required edge panels without requiring separate manual activation.

---

## Version 2.14.0 (2026-11-11)

### Major UI/UX Overhaul & Architecture Improvements

- **Modern Split-Sidebar Settings Window**: Replaced the legacy tab bar with a structured 8-category Sequoia-style sidebar showing live status dots, a global header master toggle, and grouped card sections (`SettingsCard`) across General, Hot Corners, Second Dock, Appearance, Displays, Pomodoro, Shortcuts, and About.
- **General & Hot Corners Upgrades**: Added a 6-module quick overview matrix, Default Keep Awake duration picker, Interactive Desktop Screen Map (clickable 4 corners + Edge Slider + Stash/Scratchpad drawer), and graphical `AppPickerHelper` menus for Running Applications and `/Applications` browsing.
- **Interactive Liquid Glass Studio**: Added an interactive corner dial preview stage in Appearance supporting Midnight/Daylight backdrops, corner switching, action switching, direct drag scrubbing with haptics, and synchronized Light/Dark window themes.
- **Menu Bar Control Center Popover**: Upgraded the Menu Bar menu into a clean `296pt` card layout with active context summary, Pomodoro ring controls, cached display sliders, 6 quick module toggles, and direct User Guide (`Command+?`) navigation.
- **Displays, Pomodoro, Shortcuts & About**: Added Max Hardware Brightness Clamp, 25/50/75/100% Quick Presets, Live Pomodoro Focus Ring Hero with manual mode selection, interactive Keycap Shortcut Recorders with `ShortcutValidator` conflict checks, Sparkle 2 status feedback, and richer Onboarding and Markdown User Guide views.
- **Second Dock & Widget Customizer**: Added per-widget configuration sheets (`WidgetConfigSheet` for Weather city search/units, Clock analog/digital/flip style & timezone, Date, System Stats sensors, Pomodoro durations, Bookmarks CRUD), persistent widget hosting state (no timer/clock resets on running-app changes), smooth 1:1 Floating Drag positioning, running indicator dots, and true delta CPU measurement (`CPUTickSample`).
- **Critical Symmetry & Efficiency Fixes**: Resolved Left/Right vertical edge detection asymmetry in `ScreenManager` using `CornerGeometry`, fixed `AppState` settings/mirrored property sync, gated 30fps Media Visualizer timers when overlays are closed, reduced idle audio polling to `2.5s`, and honored display brightness min/max hardware clamps everywhere.

---

## Version 2.13.1 (2026-04-17)

### Bug Fixes & Interaction Polish

- Fixed horizontal trackpad scroll responsiveness on corner dials and normalized right/left edge slider swipe handling.
- Refined dial glass contrast across bright desktop backgrounds.
