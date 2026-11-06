# Changelog

All notable changes to MacStash are documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [2.1.1] - 2026-11-06

### Fixed
- Fixed interface language switching in Settings > General: UI labels, toolbar tabs, status bar popup, and in-app User Guide now update dynamically upon selecting Vietnamese (`vi`), English (`en`), or System Default.
- Integrated Apple String Catalog (`Localizable.xcstrings`) and thread-safe `LocalizationService` in `MacStashCore` with 150 translated keys and zero emojis.
- Added comprehensive unit test coverage (`LocalizationTests`) validating language resolution, key symmetry, Vietnamese diacritics, and dynamic fallback.

---

## [2.1.0] - 2026-11-06

### Added
- Official brand identity and app icon: "The Radial Corner Bloom", embodying the physical hot corner dial mechanics.
- Multi-layered vector asset catalog (`background.svg`, `foreground.svg`, `mono.svg`) compliant with Apple Human Interface Guidelines and Liquid Glass requirements.
- Native monochrome Menu Bar template images (`stash_menubar` at 18pt @1x/@2x/@3x) with dynamic active Pomodoro state indication (`stash_menubar_active`).
- Reusable `StashBrandLogoView` component integrated across About tab, Onboarding flow, Menu Bar popover, and User Guide.
- Reproducible asset rendering pipeline (`scripts/render_icons.sh`) producing `.icns`, PNG scale pyramids, vector PDFs, social preview banners, and favicons.
- Professional DMG distribution pipeline (`scripts/build_dmg.sh`) featuring custom drag-and-drop installer background artwork and `.VolumeIcon.icns`.
- Comprehensive design specification suite in `Design/Logo/`: Brief & Research (`01-brief.md`), Concepts (`02-concepts.md`), Refinement & Testing (`03-refinement.md`), Rationale (`04-rationale.md`), Icon Composer Guide (`05-icon-composer-guide.md`), and Asset Licenses (`LICENSES.md`).

### Changed
- Replaced generic placeholder symbols in status bar, onboarding, and about panels with official brand mark.
- Added Design Governance section to `AGENTS.md` designating SVGs in `Design/Logo/source/` as the single source of truth.
- Updated User Guide (both English and Vietnamese editions) with brand identity and status bar appearance documentation.
- Standardized all Vietnamese documentation across Docs/Guide/vi/ and Design/Logo/ with complete diacritics and typography.

---

## [2.0.0] - 2026-11-06

### Added
- Core domain model, overlay state machine, and hardware display services in `MacStashCore`.
- Multi-monitor support across MacBook built-in Retina displays and external monitors via DDC/CI and Software Dimming.
- Pass-through hit-testing architecture with configurable dwell delay and sensitivity thresholds.
- Monotonic Pomodoro focus timer engine with radial progress visualization.
- Automated domain unit test runner with 67 assertions.
