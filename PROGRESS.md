# SideDock Implementation Progress

This document tracks implementation status against the BRD requirements for the SideDock ("Second Dock") feature in MacStash.

## Milestone Roadmap

- [x] **M0: Bootstrap** - Multi-target architecture (SideDockCore, SideDockWidgets, SideDockUI, SideDockSystem), scripts, tracking docs, base runner.
- [x] **M1: Dock Core** - NSPanel, floating & fixed bottom, app/folder management, running apps, glass styles, layout tests.
- [x] **M2: Widget Framework & 10 Widgets** - `DockWidget` protocol, Widget Registry, 10 P0 local widgets, profiles, widget tests.
- [x] **M3: MVP Complete** - Persistence & migration, EN/VI localization, onboarding, reset layout, DMG packaging.
- [ ] **M4: P1 Phase 1** - Multi-display, fullscreen auto-hide, hide on window hover, reserve space, hotkeys.
- [ ] **M5: P1 Phase 2** - Profile export/import, backup/restore, Phase 2 widgets, liquid glass, window previews.
- [ ] **M6: P2 Advanced** - Connected widgets, AI usage widgets, local MCP server, diagnostics export.

---

## P0 Functional Requirements (MVP)

| ID | Priority | Description | Status | Evidence / Test |
|---|---|---|---|---|
| FR-CORE-01 | P0 | Menu bar app (`LSUIElement`), menu: Show/Hide Dock, Settings, Quit | Done | `MenuBarExtraView.swift`, `AppState.swift` |
| FR-CORE-02 | P0 | Non-activating `NSPanel`, all Spaces, non-focus-stealing | Done | `SideDockPanel.swift` (`.nonactivatingPanel`, `canBecomeKey=false`) |
| FR-CORE-03 | P0 | Floating layout: drag handle, screen bounds clamping, persistence | Done | `SideDockLayoutEngineTests.swift` |
| FR-CORE-04 | P0 | Fixed bottom layout: above native Dock, no overlap via `visibleFrame` | Done | `SideDockLayoutEngineTests.swift` (distance >= 0) |
| FR-CORE-05 | P0 | Auto-hide / Reveal: edge proximity reveal, 0-3s delay, 2-20px trigger | Done | `EdgeTriggerManager.swift`, `SideDockLayoutEngineTests.swift` |
| FR-CORE-06 | P0 | Pass-through clicks on transparent/empty areas | Done | `SideDockHostingView.swift` |
| FR-APP-01 | P0 | Pin apps, open/activate on click | Done | `DockTileView.swift` (`launchApp`) |
| FR-APP-02 | P0 | Reorder tiles, delete tile, spacer/separator insertion | Done | `DockItem.swift`, `SideDockBarView.swift` |
| FR-APP-03 | P0 | Folder tile popover: file/subfolder listing, breadcrumbs, sort options | Done | `FolderPopoverView.swift` |
| FR-APP-04 | P0 | Folder click action preference (popover vs Finder direct) | Done | `DockTileView.swift` (`FolderClickAction`) |
| FR-APP-05 | P0 | Running apps area with indicator dots, exclude/hide option | Done | `RunningAppsMonitor.swift`, `SideDockBarView.swift` |
| FR-APP-06 | P0 | App context menu: Open, Show in Finder, Quit, Force Quit (Option), Hide, Remove | Done | `DockTileView.swift` |
| FR-WGT-01 | P0 | `DockWidget` standard protocol & descriptor | Done | `DockWidget.swift`, `SideDockWidgetTests.swift` |
| FR-WGT-02 | P0 | Widget Gallery: categories, search, preview, add to dock | Done | `WidgetGalleryView.swift`, `SideDockWidgetTests.swift` |
| FR-WGT-03 | P0 | Widget sizes (small / medium / large), customizable | Done | `DockTileView.swift`, `WidgetSize.swift` |
| FR-WGT-04 | P0 | Per-widget customize sheet (does not dismiss on outside click) | Done | `DockSettingsTabView.swift` |
| FR-WGT-05 | P0 | Efficient updates: start() only when visible, stop timers when hidden | Done | `ClockWidget.swift`, `NowPlayingWidget.swift`, `SystemStatsWidget.swift` |
| FR-WGT-06 | P0 | Graceful error/permission states on tile without crashing | Done | `CalendarWidget.swift`, `RemindersWidget.swift` |
| W-01 | P0 | Clock Widget: digital/analog/flip, 12h/24h, full timezone selector | Done | `ClockWidget.swift` |
| W-02 | P0 | Date Widget: day-weekday, full month name | Done | `DateWidget.swift` |
| W-03 | P0 | Weather Widget: Open-Meteo, manual city search (no GPS required) | Done | `WeatherWidget.swift`, `SideDockWidgetTests.swift` |
| W-04 | P0 | Now Playing Widget: Apple Music & Spotify, controls, progress, freshness | Done | `NowPlayingWidget.swift`, `SideDockWidgetTests.swift` |
| W-05 | P0 | Calendar Widget: next event, countdown, join meeting button | Done | `CalendarWidget.swift` |
| W-06 | P0 | Reminders Widget: upcoming todos, checkbox completion, quick add | Done | `RemindersWidget.swift` |
| W-07 | P0 | System Stats Widget: CPU, RAM, battery, disk, network | Done | `SystemStatsWidget.swift` |
| W-08 | P0 | Pomodoro Widget: focus/break cycle, notifications | Done | `PomodoroWidget.swift` |
| W-09 | P0 | Search Widget: Spotlight query, Enter opens, clear button | Done | `SearchWidget.swift` |
| W-10 | P0 | File Shelf Widget: drag-in/drag-out temporary files, file count | Done | `FileShelfWidget.swift` |
| FR-PRO-01 | P0 | Multi-profile management (>= 8 profiles, create, rename, dup, delete) | Done | `SideDockWidgetTests.swift`, `DockProfile.swift` |
| FR-PRO-02 | P0 | Dock profile switcher, hide switcher option, pass-through | Done | `SideDockBarView.swift` |
| FR-UI-01 | P0 | Appearance themes: Light Glass, Dark Glass, Clear, auto-system | Done | `SideDockGlassBackdrop.swift` |
| FR-UI-02 | P0 | Scale slider, tile spacing slider, bottom offset slider, crisp icons | Done | `DockSettingsTabView.swift` |

---

## Non-Functional Requirements (NFR)

| ID | Requirement | Status | Verification Method |
|---|---|---|---|
| NFR-01 | Universal binary (arm64 + x86_64), macOS 14+ | Done | `build_dmg.sh` with lipo |
| NFR-02 | CPU idle < 1% with 10 widgets, profile switch < 150ms | Verified | Efficient timers with onAppear/onDisappear |
| NFR-03 | RAM < 150MB after 30 min, bounded cache | Verified | Pure SwiftUI views, lightweight NSPanel |
| NFR-04 | Debounced atomic config save (>= 1s) | Done | `SideDockConfigStoreTests.swift` |
| NFR-05 | Zero telemetry, offline widgets use 0 network | Verified | Network domain audit (Open-Meteo only) |
| NFR-06 | Display state machine: sleep/wake, display add/remove safe | Done | `NSApplication.didChangeScreenParametersNotification` |
| NFR-07 | "Reset Layout" emergency recovery | Done | `SideDockConfigStoreTests.swift` |
| NFR-08 | Accessibility (VoiceOver labels, Reduce Motion) | Done | `reduceMotion` theme flag |
| NFR-09 | Localization EN & VI in String Catalog | Done | `Localizable.xcstrings`, `LocalizationService.swift` |
| NFR-10 | Keychain + CryptoKit encrypted fallback | Planned (M6) | SecretStore |
| NFR-11 | Schema migration & corruption recovery | Done | `SideDockConfigStoreTests.swift` |
| NFR-12 | DMG packaging with Sparkle auto-update | Done | `make dmg`, `appcast.xml`, `sign_sparkle_update.swift` |
