# Troubleshooting and Permissions

## Permissions Setup

1. **Accessibility**:
   Required for global cursor position tracking and non-activating overlay management.
   Grant access in macOS System Settings > Privacy & Security > Accessibility.

2. **Input Monitoring**:
   Required to monitor modifier keys and scroll events while adjusting values.
   Grant access in macOS System Settings > Privacy & Security > Input Monitoring.

3. **Notifications**:
   Required to post completion banners for Pomodoro focus intervals.

## Accidental Trigger Prevention

If corner dials appear too easily or interfere with app controls:
- Reduce Hit-Zone Sensitivity to 3-5 points in Settings > Hot Corners.
- Increase Dwell Activation Delay to 200-300 milliseconds.
- Enable window dragging and full screen suppression.
- Add specific full-screen or creative software to the Excluded Applications list.

## Changing Interface Language

You can freely switch between English and Vietnamese at any time:
- Open Settings (`Command+,`) > **General** tab > **Interface Language**.
- Select **English**, **Tiếng Việt**, or **System Default**. All preferences tabs, status item popup, and user guides update dynamically without requiring an application restart.

## Menu Bar Icon Display & Appearance

- If the menu bar icon appears crowded, drag it with `Command + Left Click` to reorder its position on the macOS menu bar.
- The status bar icon is rendered as an alpha-channel template image; if you use third-party menu bar colorizers, MacStash respects the active system appearance palette automatically.
