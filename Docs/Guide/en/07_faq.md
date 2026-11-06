# Frequently Asked Questions

## General Questions

### Does MacStash consume background CPU when idle?
No. When corner dials are hidden, MacStash uses zero CPU cycles. It operates without polling timers or background loops.

### Can I click buttons located behind corner dials?
Yes. When the dial is hidden, hit testing returns nil, allowing clicks to pass directly through to underlying applications.

### How does multi-display outer corner detection work?
MacStash evaluates desktop geometry dynamically. It detects when two monitors share an adjacent boundary and suppresses triggering along that interior seam, reserving dials exclusively for true exterior boundaries.

### What happens if an external monitor does not support DDC/CI?
MacStash seamlessly falls back to Software Dimming via hardware gamma tables. When quitting the application, color tables are automatically restored to normal.
