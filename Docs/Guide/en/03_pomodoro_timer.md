# Pomodoro and Focus Timer

The built-in Pomodoro engine integrates into corner dials and the menu bar status item.

## Key Features

1. **Monotonic Timing Invariant**:
   Unlike timers that rely on simple countdown increments, MacStash computes remaining duration against target timestamps using system monotonic clocks. Dragging dials or moving windows will never freeze or stall the countdown.

2. **System Sleep and Wake Handling**:
   When your Mac sleeps, elapsed duration is accurately recalculated upon waking.

3. **System Notifications**:
   Optional alerts notify you upon completion of focus sessions and rest intervals.
