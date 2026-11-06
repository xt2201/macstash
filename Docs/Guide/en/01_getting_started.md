# Getting Started with MacStash

MacStash provides tactile, quarter-circle radial dial controls that appear seamlessly at the extreme corners of your macOS displays.

## Core Concepts

MacStash is designed to remain completely invisible and zero-resource until you need it. By resting your mouse cursor at an active corner, the corresponding dial emerges smoothly.

### The Four Physical Corners
1. **Top-Left**: Configured by default for Keyboard Backlight adjustment.
2. **Top-Right**: Configured by default for Display Brightness control.
3. **Bottom-Left**: Configured by default for Pomodoro and Focus Timer.
4. **Bottom-Right**: Configured by default for Master Audio Volume.

### Outer Corners vs Inner Display Junctions
On multi-monitor setups, MacStash utilizes geometric outer corner detection. Dials will only trigger at true desktop perimeter boundaries. When your cursor transitions across adjacent displays along an interior border, MacStash will not interrupt cursor movement.

## Brand Identity & Menu Bar Indicator

MacStash features a dedicated brand identity centered on the **Radial Corner Bloom** motif: an anchor node positioned at the physical corner vertex paired with an expanding precision dial arc.

### Menu Bar States
- **Idle State**: A clean monochrome quarter-arc with a corner anchor pip, resting quietly in your status bar.
- **Active / Pomodoro Running State**: The dial sector fills into an active solid wedge with a focused detent pip, giving you an instantaneous peripheral glance at running focus intervals without needing to open the popover.
- **Dynamic Appearance Support**: Both icons are mastered as native template images, automatically adapting with pixel precision across light, dark, and translucent menu bars.
