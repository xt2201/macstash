# Troubleshooting and Permissions

## Permissions Setup

1. **Accessibility**:
   Required for global cursor position tracking, hot corners, vertical edges, and non-activating overlay management.
   Grant access in macOS System Settings > Privacy & Security > Accessibility.

2. **Input Monitoring**:
   Required to monitor modifier keys and two-finger scroll events while adjusting dials or the Cursor Palette.
   Grant access in macOS System Settings > Privacy & Security > Input Monitoring.

3. **Notifications**:
   Required to post completion banners for Pomodoro focus intervals.
   Grant access in macOS System Settings > Notifications > MacStash.

Permission statuses refresh automatically when MacStash Settings or Onboarding returns to the foreground.

## Accidental Trigger Prevention

If corner dials appear too easily or interfere with app controls:
- Reduce Hit-Zone Sensitivity to 3-5 points in Settings > Hot Corners.
- Increase Dwell Activation Delay to 200-300 milliseconds.
- Enable window dragging and full screen suppression.
- Add specific full-screen or creative software to the Excluded Applications list using the Running Apps menu or Browse Applications picker.

## Changing Interface Language & Glass Theme

You can switch language or visual glass theme anytime without restarting:
- **Language**: Open Settings (`Command+,`) > **General** > **Interface Language** (System Default, Tiếng Việt, or English).
- **Theme**: Open Settings > **Appearance** > **Appearance Theme** (`Match System`, `Light`, or `Dark`) to synchronize Liquid Glass overlays, Dock, Settings, and Menu Bar contrast.

## Edge Slider or Drawer Not Appearing on Left / Right Edge

- Verify that **Edge Slider Position** (`Left Edge` or `Right Edge`) and **Attached Edge** for Drawers match the physical screen boundary you hover over in Settings > Hot Corners.
- Ensure you hold the cursor flush at the outer screen border (`x = minX` for Left Edge, `x = maxX` for Right Edge) for the dwell interval, and check that no adjacent monitor is attached to that seam if **Trigger only outer desktop corners** is enabled.
- Notice clicking outside an open Cursor Palette, Edge Slider, or unpinned Stash/Scratchpad dismisses it cleanly.

## Menu Bar Icon Visibility

- If you hide the Menu Bar icon under Settings > **General** (`Show Icon in Menu Bar`), reopen MacStash anytime via Spotlight or `/Applications/MacStash.app` to bring Settings back to the front.

## Second Dock Widget & Floating Drag Tips

- When Placement is set to **Floating Window**, drag the dock using its grip handle (`dock.dragToMove`) to reposition smoothly 1:1 across displays; its position saves automatically when released.
- Right-click any widget tile on the dock or click the gear icon in Settings > **Second Dock** to configure widget options (such as Weather city & temperature scale, Clock analog/digital/flip style & timezone, System Stats sensors, or Bookmarks).

## Two-Finger Trackpad & Scroll Wheel Adjustment

- Verify that **Two-finger scroll to adjust** is enabled under Settings > **Hot Corners**.
- On the Cursor Radial Palette (`Option+Space`), hover any of the four sectors (Brightness, Volume, Timer, Keep Awake) and scroll two fingers to scrub smoothly, or click a sector to toggle.
