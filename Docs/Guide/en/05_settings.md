# Settings Scene Reference

MacStash provides a comprehensive 7-tab configuration window compliant with macOS Human Interface Guidelines. Open using Command+, or via the menu bar icon.

## Tab Directory

1. **General**:
   Master switch, menu bar icon toggle, language switcher (English, Vietnamese), launch at login, and permissions status dashboard for Accessibility, Input Monitoring, and Notifications.

2. **Hot Corners**:
   Application Profile manager (Default plus custom per-app profiles with automatic frontmost app detection), per-corner enable toggles and action assignments (Volume, Brightness, Backlight, Pomodoro, None), Edge Sliders toggle and action assignment, with Now Playing media controls option under Volume (live album artwork, dancing audio waveform visualizer, and vertical transport controls: Previous on top, Play/Pause in middle, Next at bottom), hit-zone sensitivity (1-20pt), dwell activation delay (0-1000ms), auto-hide delay (50-1000ms), interaction gestures (two-finger scroll adjustment without click-and-drag), mouse drag suppression, fullscreen suppression, inner display seam suppression, and excluded applications.

3. **Appearance**:
   Dial radius (110-200pt), glass opacity (30-100%), theme selection (System, Light, Dark), animation speed, Reduce Motion support, mechanical audio click sounds, and trackpad haptic intensity.

4. **Displays**:
   Active display inventory with UUIDs, method selector (Auto, DDC/CI, Software Dimming, Native), fallback status explanation, live brightness testing sliders, hardware clamp limits, and persistent per-display profile storage.

5. **Pomodoro**:
   Focus duration, short break duration, long break duration, rounds before long break, auto-start breaks, and completion chime alerts.

6. **Shortcuts**:
   Configurable dynamic global hotkeys for toggling dials, with automated conflict analysis against macOS system reserved combinations.

7. **About / Advanced**:
   Version information, 1-click in-place background updates (Sparkle 2) with Ed25519 cryptographic verification, Console log viewer launcher, user manual link, full JSON backup export and import (AppSettings and App Profiles), and factory reset.

## Left Edge Utilities & Cursor Palette (Hot Corners tab)

- Stash Drop Shelf: enable or disable the left-edge drop shelf for holding dragged files, images, links and text.
- Quick Scratchpad: enable or disable the left-edge notes drawer with automatic local saving.
- Cursor Radial Palette: enable or disable the radial dials summoned at the mouse cursor.
- Corner and edge actions now also accept Keep Awake, Stash Shelf and Scratchpad.
