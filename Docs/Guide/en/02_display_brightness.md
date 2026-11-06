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
