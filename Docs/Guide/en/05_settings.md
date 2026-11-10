# Settings Scene Reference

MacStash provides a comprehensive 8-tab configuration window compliant with macOS Human Interface Guidelines. Open using Command+, or via the menu bar icon.

## Tab Directory

1. **General**:
   Master switch, menu bar icon toggle, language switcher (English, Vietnamese), launch at login, and permissions status dashboard for Accessibility, Input Monitoring, and Notifications.

2. **Hot Corners**:
   Application Profile manager (Default plus custom per-app profiles with automatic frontmost app detection), master toggle for corner dials, per-corner enable toggles and action assignments (Volume, Brightness, Backlight, Pomodoro, Keep Awake, Stash Shelf, Scratchpad, None), Display Target selection (Built-in Mac screen only, External displays only, or Both/All screens), Edge Sliders toggle, screen edge selector (Left Edge or Right Edge) and action assignment, with Now Playing media controls option under Volume (live album artwork, dancing audio waveform visualizer, and vertical transport controls: Previous on top, Play/Pause in middle, Next at bottom), hit-zone sensitivity (1-20pt), dwell activation delay (0-1000ms), auto-hide delay (50-1000ms), interaction gestures (two-finger scroll adjustment without click-and-drag), mouse drag suppression, fullscreen suppression, inner display seam suppression, and excluded applications.

3. **Second Dock**:
   Master toggle to display an auxiliary live widget and application dock running alongside native macOS Dock. Configure placement (Fixed Bottom sitting above native Dock with zero overlap, Floating window, Fixed Top, Fixed Left, Fixed Right), scaling (0.7x to 1.5x), tile spacing, edge offset, auto-hide with customizable reveal delay (0.0s to 3.0s) and edge trigger activation thickness (2px to 20px), hide in fullscreen, hide on window hover, reserve dock space, glass backdrop styles (Auto System, Light Glass, Dark Glass, Liquid Glass, Clear frameless), profile switcher, Dock Items & Applications manager (add custom apps from /Applications, delete default apps like Safari and Terminal, reorder items, add separators), widget gallery with 16 live widgets, and Reset Layout emergency recovery.

4. **Appearance**:
   Dial radius (110-200pt), glass opacity (30-100%), theme selection (System, Light, Dark), animation speed, Reduce Motion support, mechanical audio click sounds, and trackpad haptic intensity (Off, Subtle, Medium, Strong).

5. **Displays**:
   Active display inventory with UUIDs, method selector (Auto, DDC/CI, Software Dimming, Native), fallback status explanation, live brightness testing sliders, hardware clamp limits, and persistent per-display profile storage.

6. **Pomodoro**:
   Focus duration, short break duration, long break duration, rounds before long break, auto-start breaks, and completion chime alerts.

7. **Shortcuts**:
   Configurable dynamic global hotkeys for toggling dials, cursor radial palette, stash shelf, and scratchpad notes drawer, with automated conflict analysis against macOS system reserved combinations.

8. **About / Advanced**:
   Version information, 1-click in-place background updates (Sparkle 2) with Ed25519 cryptographic verification, Console log viewer launcher, user manual link, full JSON backup export and import (AppSettings and App Profiles), and factory reset.

## Drawer Utilities & Cursor Palette (Hot Corners tab)

- Stash Drop Shelf: modular enable/disable toggle (default: OFF) for holding dragged files, images, links and text snippets.
- Quick Scratchpad: modular enable/disable toggle (default: OFF) for capturing ephemeral notes with automatic local persistence.
- Attached Edge: configure whether drawer utilities slide out from the Left Edge or Right Edge of the screen.
- Cursor Radial Palette: enable or disable the radial dials summoned directly at the mouse cursor.
- Corner and edge actions accept Volume, Brightness, Keyboard Backlight, Pomodoro, Keep Awake, Stash Shelf, and Scratchpad.
