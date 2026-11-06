# Pomodoro and Focus Timer

The built-in Pomodoro engine integrates into corner dials and the menu bar status item, delivering a smooth, resilient, and synchronized workflow for productive focus intervals and scheduled rests.

## Key Features

1. **Comprehensive Pomodoro Cycle**:
   MacStash supports the full standard Pomodoro sequence: Focus Sessions, Short Breaks, and Long Breaks after a designated number of completed rounds. Optional automation allows rest intervals to start immediately when a focus interval finishes.

2. **Real-Time Menu Bar Indicator**:
   While a session is active, the MacStash menu bar icon automatically switches to its active appearance and displays the live countdown string (for example, 24:50). When paused or idle, the status item returns to its compact monochrome icon.

3. **Quick Menu Bar Popover Controls**:
   Clicking the menu bar icon surfaces instant controls:
   - Play / Pause Button: Starts immediately from idle or toggles running intervals.
   - Skip Button: Quickly advances to the next break or next focus session.
   - Reset Button: Restores the current session to its configured starting duration.
   - Compact Progress Bar: Visually depicts elapsed and remaining time at a glance.

4. **Smart Corner Dial Interaction & Micro-Controls**:
   - While running or paused: The radial arc reflects the progress ring narrowing toward completion. Tapping the central badge pauses or resumes the session. Accidental cursor dragging is guarded against to prevent wiping active sessions. The center badge displays current round progression pips (such as Round 1 of 4).
   - While idle: Dragging the dial ring allows precision scrubbing of session duration (from 1 to 60 minutes) with haptic detents every 5 minutes. The arc precisely mirrors the selected minute mark on the 60-minute dial without jumping. Tapping the center Play button starts the session at the selected duration without resetting.
   - Satellite micro-buttons: Dedicated translucent Reset and Skip mode buttons are integrated directly into the corner dial quadrant, allowing one-click resets and mode advances without having to access the menu bar.
   - Distinctive colors: Purple accents for focus sessions and emerald green accents for rest periods.

5. **Monotonic Timing and Sleep/Wake Invariance**:
   Remaining time is computed against monotonic target timestamps rather than fragile decrement timers. Window drags, system lag, and macOS system sleep will never freeze the countdown. Upon waking, remaining duration updates instantly.

6. **Automatic Session Persistence**:
   Session state (mode, remaining time, and completed rounds) persists across application restarts using local system snapshots.

7. **Localized System Notifications**:
   System banner alerts and optional tactile completion chimes notify you when sessions and break periods wrap up.

## Troubleshooting

- **No notifications upon completion**:
  Open macOS System Settings > Notifications > MacStash and ensure that "Allow Notifications" is granted.
- **Customizing default intervals**:
  Open MacStash Preferences (⌘,), select the Pomodoro tab, and adjust the duration steppers for Focus, Short Break, Long Break, and Rounds Before Long Break. Changes apply immediately whenever the timer is in the ready or idle state.
