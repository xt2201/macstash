# Multi-Monitor Display Brightness

MacStash provides individual brightness regulation across both MacBook built-in displays and external monitors.

## Control Methods

### Native Display Services
Used for built-in Apple Retina displays. Communicates directly with macOS DisplayServices.

### DDC/CI Hardware Control
For compatible external monitors connected via DisplayPort, HDMI, or USB-C. Adjusts physical monitor backlight levels via VESA DDC/CI commands on an isolated background queue.

### Software Dimming
Used as an automatic fallback when external hardware does not support DDC/CI. Employs hardware gamma table manipulation to dim screen output down to 0% smoothly.
Upon application termination or crash, MacStash automatically restores system color sync tables to original state.

## Menu Bar Brightness Controls

When multiple displays are connected, the MacStash menu bar extra popover displays an independent brightness slider for each active monitor. Each slider clearly indicates the display name and device category (built-in notebook screen or external monitor).

## Profile Persistence

Brightness settings and preferred control methods are automatically saved per display UUID in your user preferences. When disconnecting and reconnecting external monitors, MacStash restores your previous brightness levels and hardware profiles automatically.
