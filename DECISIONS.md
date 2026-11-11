# Technical Decisions Log (DECISIONS.md)

This log records major technical and architecture decisions for SideDock with rationale and trade-offs.

## ADR-001: Multi-target modular package structure
- **Context:** SideDock needs high testability, clean boundaries between domain models, widget implementations, UI rendering, and AppKit windowing.
- **Decision:** Split code into `SideDockCore` (domain models, layout engine, config store, no AppKit UI), `SideDockWidgets` (widget protocol and 10 local widgets), `SideDockUI` (SwiftUI views and glass styling), and `SideDockSystem` (NSPanel, mouse tracking, running apps).
- **Rationale:** Ensures domain logic can be tested in milliseconds via CLI without window server dependencies, keeping test runtimes < 100ms.

## ADR-002: Standalone test runner vs XCTest
- **Context:** macOS CLI environment lacks full Xcode.app bundle (`xcode-select` points to CommandLineTools). XCTest runner requires Xcode.
- **Decision:** Implement domain and integration tests via `MacStashTestRunner` executable target, with structured assertion helpers mirroring XCTest assertions.
- **Rationale:** Allows 100% offline, rapid CI and local verification without requiring full multi-gigabyte Xcode IDE installations.

## ADR-003: AppKit NSPanel for Dock Windowing
- **Context:** SwiftUI `WindowGroup` or `MenuBarExtra` cannot provide non-activating panels (`.nonactivatingPanel`), multiple space presentation (`.canJoinAllSpaces`), or borderless floating levels.
- **Decision:** Use an AppKit `NSPanel` subclass (`SideDockPanel`) wrapping SwiftUI views in a custom `SideDockHostingView`.
- **Rationale:** Prevents the dock from stealing keyboard focus from active user apps when buttons/widgets are clicked, and allows mouse clicks on transparent regions to pass through to underlying windows.

## ADR-004: AppleScript / ScriptingBridge for Media Control
- **Context:** Apple has no public MediaRemote framework; private frameworks are strictly prohibited by rule 0.2-5.
- **Decision:** Query Apple Music and Spotify via AppleScript / `NSAppleScript` events, caching responses with timestamp-based validity (TTL 5s).
- **Rationale:** 100% compliant with public Apple APIs, zero private framework usage, robust fallback when music players are paused or terminated.

## ADR-005: Open-Meteo for Weather Data
- **Context:** Weather widget needs live forecasts without requiring third-party API keys or compulsory Location Services permissions.
- **Decision:** Use Open-Meteo REST API (`api.open-meteo.com` and `geocoding-api.open-meteo.com`) with manual city selection as default, with optional CoreLocation.
- **Rationale:** Completely free, open, requires no secret API tokens, complies with network privacy requirements in BRD section 7.4.

## ADR-006: EventKit for Calendars & Reminders
- **Context:** Need next event countdown and reminders checklist with quick-add.
- **Decision:** Use Apple `EventKit` (`EKEventStore`) with lazy permission requests preceded by an informative in-app explainer dialog.
- **Rationale:** Native macOS integration with built-in Calendar and Reminders apps; zero external network dependencies.

## ADR-007: Release Packaging with Sparkle 2 and SemVer 2.11.0
- **Context:** The addition of SideDock Second Dock constitutes a major new feature (backward-compatible minor release), requiring bump to v2.11.0 and synchronized updates across all 6 versioning locations.
- **Decision:** Bump version to 2.11.0, sign zip archive using local Ed25519 key, update appcast.xml, and build universal ad-hoc signed DMG.
- **Rationale:** Strict adherence to AGENTS.md single source of truth rules and Sparkle 2 background update verification.

## ADR-008: Reserve Space via Accessibility AXUIElement
- **Context:** FR-CORE-10 requires reserving screen space for fixed dock configurations without private WindowServer APIs.
- **Decision:** Implement pure domain `ReserveSpacePolicy` for frame geometry math, coupled with `ReserveSpaceManager` using public Accessibility `AXUIElement` APIs to adjust frontmost non-desktop windows when enabled.
- **Rationale:** 100% compliant with public Apple APIs, respects user privacy with opt-in default OFF configuration.

## ADR-009: Profile Export/Import and Phase 2 Local Widgets
- **Context:** Users need to backup, share, and migrate dock profiles between setups, and access fast utility widgets (clipboard, notes, screenshots, color picker, converter, bookmarks).
- **Decision:** Implement `DockProfileTransferService` with standardized `.sidedock-profile` JSON envelope, generating fresh UUIDs on import to prevent profile collisions. Add 6 local-first Phase 2 widgets without external network dependencies.
- **Rationale:** 100% offline, privacy-first, zero telemetry, seamless user customization.

## ADR-010: MediaRemote Perl Bridge, DisplayServices Boundary, and macOS 14.0+ Baseline
- **Context:** macOS 15.4+ restricted `MediaRemote.framework` entitlements to platform binaries, limiting AppleScript-only metadata (ADR-004) for browsers and modern media apps. Meanwhile, `Package.swift` and SwiftUI views already rely on macOS 14.0+ APIs (such as two-parameter `.onChange`), whereas `Scripts/Info.plist` and `README.md` still advertised `13.0`.
- **Decision:** Supersede ADR-004's AppleScript-only constraint with the isolated `MacStashNowPlaying` dylib loaded inside `/usr/bin/perl` (`now-playing.pl`) plus AppleScript fallback, retain `BuiltInBrightnessService` dynamic `dlopen` (`DisplayServices.framework`) with DDC/CI and gamma fallbacks, prohibit adding any new private frameworks, and standardize `LSMinimumSystemVersion` and docs on `14.0`.
- **Rationale:** Preserves universal media detection and native Retina brightness while enforcing strict crash-safe boundaries and factual platform metadata.

## ADR-011: Two-Mode Agent Harness (`AGENTS.md` + `CLAUDE.md`) and Automated Code Hygiene Gates
- **Context:** `AGENTS.md` previously referenced a missing "Section 1", lacked domain invariants and UI/UX Liquid Glass specifications, mixed iterative development with mandatory DMG/tag releases, and lacked automated enforcement against `NSLog` or `as!` regressions.
- **Decision:** Reconstruct `AGENTS.md` as a concise control plane backed by progressive-disclosure specs under `Docs/Agent/`, add `CLAUDE.md` (`@AGENTS.md`) for cross-agent interoperability, separate Dev Inner Loop from Release Pipeline, and enforce banned-pattern/OS-alignment/documentation checks via `CodeHygieneTests` and updated `DocumentationIntegrityTests`.
- **Rationale:** Keeps AI agent context crisp, prevents architectural drift deterministically in `make test`, and accelerates iterative development without sacrificing release rigor.
