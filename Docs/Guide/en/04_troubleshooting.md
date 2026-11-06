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
   Grant access in macOS System Settings > Notifications > MacStash.
   MacStash integrates native foreground presentation (`UNUserNotificationCenterDelegate`), audible alert chimes (`Glass`), and Dock icon bouncing (`requestUserAttention`) ensuring completion alerts are never missed even when working in other applications.

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

## Pomodoro Duration Scrubbing & Dial Interaction

- To adjust session duration when the timer is idle, drag the outer dial arc band (outside the central circular badge). The dial tracks precisely from 1 to 60 minutes with subtle haptic detents.
- Tapping directly on the center badge starts or pauses the timer and will never overwrite your configured session minutes.
- Use the satellite buttons inside the dial to quickly Reset or Skip to the next mode.

## Right Edge Slider Visibility

- The right-edge vertical slider is completely hidden when idle to keep your display clean and unobstructed.
- To reveal the slider, move your mouse cursor to the rightmost edge of your screen. It will smoothly glide into view, allowing quick adjustment of volume or display brightness.

## Keyboard Backlight Slider & Top Bar Controls

- The keyboard backlight slider provides buttery-smooth, real-time tracking that stays in immediate lockstep with MacBook hardware sensors.
- Whenever you open the Menu Bar popover, MacStash automatically refreshes the current hardware backlight level and master volume, ensuring the sliders reflect external adjustments made via physical keys or macOS Control Center.
- You can tap directly on the keyboard icon to quickly toggle the keyboard backlight on or off.
