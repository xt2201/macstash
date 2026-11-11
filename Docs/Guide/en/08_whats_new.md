# Release Notes & Changelog

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
