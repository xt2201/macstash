# AGENTS.md — MacStash & SideDock Engineering Harness

Tài liệu điều phối trung tâm cho mọi AI coding agent (Antigravity, Claude Code, Codex, Cursor) làm việc trên repository **MacStash** (`v2.15+`, Swift 6 `StrictConcurrency`, `macOS 14.0+` Universal `arm64 + x86_64`).

Mục lục tài liệu chuyên sâu (Progressive Disclosure — chỉ đọc khi tác vụ đụng tới mảng tương ứng):
- UI/UX & Design Tokens chi tiết: [Docs/Agent/UI_DESIGN_SYSTEM.md](Docs/Agent/UI_DESIGN_SYSTEM.md)
- Kiến trúc chi tiết, lộ trình tách God-file, Release Checklist & M6: [Docs/Agent/ARCHITECTURE_AND_RELEASE.md](Docs/Agent/ARCHITECTURE_AND_RELEASE.md)
- Quyết định kỹ thuật lịch sử: [DECISIONS.md](DECISIONS.md) | Lộ trình tiến độ: [PROGRESS.md](PROGRESS.md) | Asset nguồn: [ASSETS.md](ASSETS.md)

---

## 0. Bản đồ Kiến trúc & Ranh giới Module

| Target (`Sources/`) | Vai trò | Ranh giới Import Bắt buộc |
|---|---|---|
| `MacStashCore` | Domain thuần túy (`CornerGeometry`, `OverlayStateMachine`, `PomodoroEngine`, `BrightnessPolicy`, `ShortcutValidator`), `Defaults`, `AppLogger`, `LocalizationService`, Hardware/Persistence Services | **Không** import SwiftUI views hay AppKit window/panel; logic domain phải test offline không cần WindowServer |
| `SideDockCore` | Domain Second Dock (`DockLayoutEngine`, `ReserveSpacePolicy`, `DockConfigStore`, `DockProfileTransferService`, Models) | **Không** import SwiftUI / AppKit UI |
| `SideDockWidgets` | Protocol `DockWidget`, `WidgetRegistry`, 16 widget cục bộ | Phụ thuộc `MacStashCore`, `SideDockCore` |
| `SideDockUI` | `SideDockBarView`, `DockTileView`, `SideDockGlassBackdrop`, `WidgetGalleryView`, `WidgetConfigSheet`, `DockSettingsTabView` | Phụ thuộc `MacStashCore`, `SideDockCore`, `SideDockWidgets` |
| `SideDockSystem` | `SideDockPanel` (`NSPanel`), `SideDockHostingView`, `EdgeTriggerManager`, `ReserveSpaceManager`, `RunningAppsMonitor`, `LazyPermissionManager` | Phụ thuộc `SideDockCore`, `SideDockWidgets`, `SideDockUI` |
| `MacStashNowPlaying` | Dynamic dylib bridge chạy trong `/usr/bin/perl` (`now-playing.pl`) truy vấn `MediaRemote` | Cô lập hoàn toàn khỏi UI và App target chính |
| `MacStash` | Composition root (`Main.swift`, `AppDelegate`, `AppState`, `ScreenManager`), Corner Dials, Edge Sliders, Stash Shelf, Scratchpad, Settings (8 tab), Onboarding & Guide | Tầng kết nối UI/AppKit; không chứa nghiệp vụ tính toán thuần túy có thể đặt ở Core |
| `MacStashTestRunner` | Test executable CLI (`Tests/MacStashTests/`) chạy bằng `make test` (< 100ms, không cần Xcode.app) | Không phụ thuộc `XCTest` |

Các đường dẫn trọng yếu (lưu ý `Scripts/` viết hoa chữ `S`):
- Version SSOT: `VERSION` | Info.plist mẫu: `Scripts/Info.plist` | Sparkle feed: `appcast.xml`
- SVG nguồn thương hiệu: `Design/Logo/source/*.svg` | Script render asset: `./Scripts/render_icons.sh`
- Tài liệu người dùng song ngữ: `Docs/Guide/en/*.md` và `Docs/Guide/vi/*.md`

---

## 1. Chuẩn Kỹ thuật, Nghiệp vụ & UI/UX ("Mục 1")

### 1.1 Danh sách Cấm & Quy chuẩn Code Swift 6
- **Concurrency (`StrictConcurrency`)**: Đánh dấu `@MainActor` cho toàn bộ UI/Coordinators (`AppState`, `ScreenManager`, `SideDockManager`, `ReserveSpaceManager`). Mọi I/O phần cứng (`DDCBrightnessService` timeout `0.1s`), mạng (`WeatherWidget`), và `EventKit` chạy off-main-thread; dùng `actor`, `NSLock`, hoặc serial `DispatchQueue` khi cần `@unchecked Sendable` kèm lý do rõ ràng.
- **Logging (`os.Logger`)**: Tuyệt đối **cấm** `print(...)` và `NSLog(...)` trong `Sources/` (chỉ dùng `print` trong `Tests/` và CLI `Scripts/`). Dùng `AppLogger` (subsystem `com.macstash.app`) hoặc `os.Logger` tương đương theo category.
- **Safe Casting & Error Handling**:
  - Tuyệt đối **cấm** `!`, `try!`, `as!`, `fatalError(...)` trong `Sources/`. *Ngoại lệ duy nhất*: `fatalError` trong `@available(*, unavailable) required init?(coder:)` / `init(rootView:)` của `NSView`/`NSPanel` subclass. Với CoreFoundation (`AXUIElement`, `AXValue`), bắt buộc kiểm tra `CFGetTypeID(...)` trước khi `unsafeBitCast`, cấm `as!`.
  - **Không nuốt lỗi bằng `try?` im lặng** ở persistence, `Process.run()`, `EventKit.save()`, JSON decode/encode hay file I/O; phải log ở mức `.debug`/`.warning` hoặc xử lý fallback tường minh.
- **Cấm `Bundle.module`**: SwiftPM `Bundle.module` gây `fatalError` khi đóng gói thành `.app` bundle ngoài Xcode. Mọi resource (`Docs/Guide`, ảnh, script) phải phân giải qua `Bundle.main` kèm fallback đường dẫn repo cho test CLI.
- **Cấm Hardcode & Magic Numbers**: Hằng số ngưỡng vật lý, thời gian, kích thước panel đặt tập trung trong `Defaults.swift` với tên có đơn vị rõ ràng (`...Points`, `...Seconds`). Tuyệt đối **cấm hardcode số phiên bản** trong UI hoặc catalog; đọc động từ `Bundle.main.infoDictionary?["CFBundleShortVersionString"]` fallback `Defaults.appVersion`.
- **Cấm Emoji**: Không emoji trong code, comment, log, chuỗi UI, `CHANGELOG.md`, `Docs/Guide/`, `Docs/Agent/` và `README.md`. Biểu tượng sử dụng Apple SF Symbols hoặc SVG vector tại `Design/Logo/source/`.
- **Kích thước File & Chính sách Refactor-on-Touch**: File mới giữ mục tiêu **<= 400 dòng**, hàm ngắn, early return, không trùng lặp logic. Với các file legacy hiện > 400 dòng (xem `Docs/Agent/ARCHITECTURE_AND_RELEASE.md`), khi chỉnh sửa mở rộng tính năng cần ưu tiên tách phần mới/liên quan ra subview hoặc coordinator riêng thay vì tiếp tục phình file gốc.

### 1.2 Logic Nghiệp vụ & Luật Bất biến (Business & Domain Invariants)
- **Domain Purity**: Mọi thuật toán hình học, state machine, validation, layout engine và policy (`CornerGeometry`, `OverlayStateMachine`, `PomodoroEngine`, `BrightnessPolicy`, `ShortcutValidator`, `DockLayoutEngine`, `ReserveSpacePolicy`) phải nằm ở `MacStashCore` / `SideDockCore`, thuần Swift giá trị (value types) và test được bằng CLI.
- **Single Source of Truth (SSOT) cho Trạng thái**:
  - `AppState.settings` (`AppSettings`) là trạng thái bền vững duy nhất. Không tạo state song song gây split-brain; nếu buộc phải mirror ra `@Published` cho SwiftUI, bắt buộc đồng bộ một chiều qua `syncMirroredProperties` với guard `isSyncingSettings`.
  - **Hardware Truth Over Stale Cache**: Với Độ sáng (`CompositeBrightnessService`) và Âm lượng (`CoreAudio`), người dùng có thể nhấn phím cứng F1/F2/F11/F12 bất kỳ lúc nào. Luôn truy vấn giá trị phần cứng trực tiếp khi dwell/hover/wake; không trả về cache cũ làm lệch trạng thái dial và edge bar.
- **Hình học Đa màn hình & Tương tác Cạnh**:
  - Lọc góc màn hình qua `CornerGeometry.isOuterCorner` để không kích hoạt tại cạnh tiếp giáp giữa 2 màn hình.
  - Cấu hình cạnh Trái / Phải phải đối xứng và tự động phân tách hợp lệ giữa Edge Slider và Drawer (Stash Shelf / Scratchpad).
  - Second Dock khi cố định đáy (`fixedBottom`) phải tính theo `NSScreen.visibleFrame` để không đè macOS Dock gốc; mọi vị trí nổi (`floating`) phải clamp trong biên màn hình và lắng nghe `didChangeScreenParametersNotification`.
- **Thời gian Đơn điệu & Kiểm soát Tài nguyên (NFR-02 / NFR-03)**:
  - Mọi bộ đếm (Pomodoro, Dwell, Keep Awake) dùng mốc thời gian đơn điệu (`ProcessInfo.processInfo.systemUptime`) kết hợp `Date` đích trên `RunLoop.main` mode `.common`, không giảm biến đếm thủ công trong `Timer` mặc định (tránh đứng timer khi kéo chuột hoặc sleep).
  - **Idle Resource Gating**: Visualizer 30fps, audio polling, cursor polling và `DockWidget.start()`/`stop()` phải tạm dừng khi overlay/dock đang ẩn (giữ CPU idle < 1%, RAM < 150MB).
  - **Live Playback State Invariants**: Tuyệt đối không ghi đè `elapsedTime = 0` khi cùng một bài hát đang tiếp tục phát (chỉ reset về 0 khi đổi bài `trackChanged` hoặc ngừng phát hẳn). Định kỳ đối soát vị trí phát thực tế từ AppleScript / MediaRemote timestamp để thanh tua (scrubber) và số giây hiển thị luôn đồng bộ chính xác.
- **Persistence An toàn & Phục hồi Phần cứng**:
  - Cấu hình lưu qua debounce + atomic write (`write(..., options: .atomic)` + `replaceItemAt`), có `schemaVersion` + migration, và tự cô lập file hỏng sang `.corrupted.<timestamp>.json`.
  - `SoftwareDimmingService` phải bảo đảm gọi `CGDisplayRestoreColorSyncSettings()` khi thoát app hoặc chuyển phương thức điều chỉnh độ sáng.
- **Privacy, Quyền & Biên giới Private API**:
  - Ứng dụng chạy **100% cục bộ, zero telemetry** (ngoại lệ mạng duy nhất là `WeatherWidget` gọi Open-Meteo theo yêu cầu người dùng).
  - Xin quyền hệ thống (`Accessibility`, `Input Monitoring`, `Apple Events`, `EventKit`, `Notifications`) theo cơ chế Lazy Permission kèm giải thích ngữ cảnh trước khi mở hộp thoại hệ thống.
  - Không thêm Private Framework mới. Hai cầu nối hiện có (`DisplayServices` qua `dlopen` và `MediaRemote` qua `/usr/bin/perl`) phải luôn có fallback an toàn, không crash khi Apple thay đổi symbol.

### 1.3 Triết lý Frontend, Design System & UI/UX Hiện đại (Apple HIG + Liquid Glass)
- **Hệ thống Vật liệu Liquid Glass**:
  - Mọi panel nổi và thẻ giao diện dùng bộ token chuẩn: `.liquidGlass(...)` / `.circularLiquidGlass(...)` (`LiquidGlassMaterial.swift`), `SideDockGlassBackdrop`, `SettingsCard`, `StatusBadgePill`, `.macStashTheme(...)`.
  - Đảm bảo đủ 4 lớp quang học (`.ultraThinMaterial` substrate -> contrast stabilizer -> caustic action tint -> viền specular 135° + bóng đổ định hướng) và tương phản ngang hàng trên Light / Dark / Clear / Auto System (WCAG AA >= 4.5:1 cho text, AAA >= 7:1 cho chỉ báo chính).
- **Zero-Pixel & Non-Activating Ergonomics (Định luật Fitts)**:
  - Mọi overlay/dock (`SideDockPanel`, `ScreenOverlayInstance`, `MacStashInteractivePanel`) sử dụng `.nonactivatingPanel`, `.canJoinAllSpaces`, và pass-through `hitTest(_:) -> nil` khi ẩn hoặc ở vùng trống — tuyệt đối không cướp click hay keyboard focus của ứng dụng nền (chỉ nhận key window có chủ đích khi người dùng tương tác ô nhập liệu như Scratchpad hoặc Search Widget).
  - Tôn trọng dwell delay (`0.20s`), hide grace (`0.25s`), và chặn kích hoạt khi đang giữ chuột drag, fullscreen (khi bật suppress), hoặc app nằm trong danh sách loại trừ.
- **Độ tinh xảo Cơ học & Chuyển động 120Hz ProMotion**:
  - Lưới spacing 4pt / 8pt, bo góc liên tục `.continuous`, đối xứng 45° tại 4 góc màn hình.
  - Mọi số liệu thay đổi liên tục (%, đếm ngược, CPU/RAM, thời lượng media) **bắt buộc** dùng `.monospacedDigit()`.
  - Cuộn hai ngón trên trackpad đồng bộ với Natural Scrolling (`NSEvent.isDirectionInvertedFromDevice`); kết hợp haptic detents (`NSHapticFeedbackManager`) và âm thanh click cơ học theo cài đặt.
  - **Zero Main-Thread I/O trong UI**: Icon ứng dụng/file phải qua `StashIconCache`; thẻ danh sách tách subview riêng (`StashItemCardView`) để SwiftUI diff mượt ở 120fps.
  - **Persistent Hosting Identity**: Không hủy/tạo lại root `NSHostingView` khi chỉ cập nhật dữ liệu (giữ trạng thái widget qua `SideDockRootWrapper`).
- **Accessibility & Song ngữ (EN / VI)**:
  - Mọi nút chỉ có icon, radial dial và edge slider phải có `.accessibilityLabel`, `.accessibilityValue` và `.accessibilityHint`. Tôn trọng `accessibilityDisplayShouldReduceMotion` và `Reduce Transparency`.
  - SSOT runtime cho chuỗi UI là `LocalizationService.catalog` (`Sources/MacStashCore/Localization/LocalizationService.swift`), bắt buộc đối xứng 100% EN và VI có dấu tiếng Việt chuẩn. Khi cập nhật/dịch mới hoặc chỉnh key lớn, giữ `Localizable.xcstrings` sạch và không chứa chuỗi phiên bản cứng.
- **Toán học Tránh Trùng đè Hình học (Geometric Non-Overlap & Polar Clearance Invariants)**:
  - Mọi bố cục vòng tròn / hướng tâm (Radial Dials, Center Action Badge, Satellites, Arc Track) phải quy về cùng một hệ tọa độ cực (`RadialDialGeometry`).
  - Cấm dùng offset điểm cố định khi kích thước co giãn theo thiết lập người dùng (`dialRadiusPoints`). Bán kính vệ tinh (`satelliteRadius`) phải luôn nằm tại tâm kênh (`(badgeOuterBoundary + trackInnerBoundary) * 0.5`) và chứng minh khoảng cách an toàn bằng unit test (`clearance >= 8.0pt` ở kích thước mặc định, `>= 3.0pt` ở kích thước tối thiểu, bảo đảm không chạm khi hover scale 1.15x và đổ bóng 6pt).
- **Bố cục Cài đặt Chống Tràn viền & Cắt chữ (Settings Responsive Form Standards)**:
  - Trong `SettingsCard`, tuyệt đối **cấm đặt `Picker` segmented nằm ngang (`HStack`) cạnh nhãn dài** gây tràn thẻ và cắt chữ khi dịch sang tiếng Việt hoặc ngôn ngữ dài.
  - Mọi Segmented Picker từ 3 lựa chọn trở lên hoặc có nhãn đa ngữ dài phải đặt trong `VStack(alignment: .leading, spacing: 6)` với `.labelsHidden()` để tự động giãn đều 100% chiều rộng thẻ.
  - Hàng gán tính năng (`edgeAssignmentRow`, `cornerAssignmentRow`) phải dùng cấu trúc co giãn linh hoạt, khống chế min/max width của menu picker (`.frame(minWidth: 160, maxWidth: 225)`).

---

## 2. Design, Brand Identity & Đồng bộ README/Showcase

- **Single Source of Truth hình ảnh**: Toàn bộ file SVG nguồn đặt tại `Design/Logo/source/`.
- Sinh lại asset (`MacStash.icns`, `AppIcon.icns`, Menu Bar template `@1x/@2x/@3x`, lockups, `stash_quadrant_overview.png`, `stash_social_preview.png`, `dmg_background.png`) **chỉ thông qua** `./Scripts/render_icons.sh` (dùng `Scripts/render_svg.swift`). Không sửa tay file PNG/ICNS nhị phân.
- Mọi thay đổi tác động tới bố cục 4 góc, Edge Sliders, Stash Shelf, Cursor Palette, Second Dock hoặc Menu Bar phải cập nhật file SVG nguồn tương ứng, chạy lại `./Scripts/render_icons.sh`, và cập nhật tài liệu thiết kế tại `Design/Logo/`.
- `README.md` phải phản ánh trung thực code hiện tại (tính năng, bảng phím tắt, bảng quyền hệ thống, huy hiệu phiên bản và minh họa trực quan).

---

## 3. Quy trình 2 Chế độ: Dev Inner Loop vs Release Pipeline

### Chế độ A — Dev Inner Loop (Tính năng mới / Fix bug / Refactor trong quá trình phát triển)
1. **Đọc trước khi sửa**: Khảo sát file đích, protocol, `Defaults.swift` và test liên quan; giữ nguyên các thay đổi WIP ngoài phạm vi trên working tree nếu không được yêu cầu xử lý.
2. **Sửa đúng tầng & viết test tái hiện**: Domain test đặt trong `Tests/MacStashTests/` và đăng ký vào `TestRunnerMain.swift`.
3. **Kiểm chứng bắt buộc sau chỉnh sửa cuối**:
   - `make test` (toàn bộ assertion pass 100%)
   - `swift build` (không thêm compiler warning mới)
4. **Commit nhỏ theo Conventional Commits**: Chỉ bump `VERSION`, chạy `Scripts/build_dmg.sh` hay tạo tag khi thực hiện **Chế độ B**.

### Chế độ B — Release & Ship Pipeline (Khi hoàn tất phiên bản hoặc người dùng yêu cầu release / DMG / tag)
Một bản phát hành chỉ hoàn thành khi đủ **9 bước** (chi tiết kiểm tra tại `Docs/Agent/ARCHITECTURE_AND_RELEASE.md`):
1. Đảm bảo working tree sạch các thay đổi hợp lệ thuộc bản release và không để lại file thừa/bí mật.
2. **Đồng bộ 6 vị trí Versioning** theo SSOT `VERSION` (semver `X.Y.Z`):
   - `VERSION`
   - `Scripts/Info.plist` (`CFBundleShortVersionString` và `CFBundleVersion`)
   - `CHANGELOG.md` (`## [X.Y.Z] - YYYY-MM-DD`, Added/Changed/Fixed, không emoji)
   - `Docs/Guide/en/08_whats_new.md` và `Docs/Guide/vi/08_whats_new.md` (đối xứng 2 ngôn ngữ)
   - `README.md` (huy hiệu release + link tải `MacStash-vX.Y.Z.dmg` + tính năng/phím tắt/quyền mới)
   - `appcast.xml` (tự cập nhật qua `./Scripts/build_dmg.sh` với chữ ký Ed25519 từ `Scripts/sign_sparkle_update.swift`)
3. Cập nhật `Docs/Guide/{en,vi}/*.md` nếu đổi tính năng, Settings, phím tắt, hành vi hoặc quyền; cập nhật SVG + chạy `./Scripts/render_icons.sh` nếu đổi giao diện trực quan.
4. Chạy `make test` (`VersionConsistencyTests`, `DocumentationIntegrityTests`, `LocalizationTests`, `CodeHygieneTests` và toàn bộ domain tests pass 100%) và `swift build -c release` sạch warning.
5. Chạy `./Scripts/build_dmg.sh` tạo universal DMG (`arm64 + x86_64`) + update ZIP ký Ed25519; ghi lại đường dẫn artifact và SHA-256. Không build được phải báo rõ nguyên nhân. (Lưu ý: không dùng `Scripts/build_app.sh` cũ cho phát hành chính thức).
6. Kịch bản build/render trong `Scripts/` tuyệt đối không phụ thuộc cứng vào package Python tùy chọn ngoài hệ thống (`weasyprint` phải bọc `try/except`) để CI runner `macos-latest` chạy thành công 100%.
7. Commit theo Conventional Commits, tạo tag `v<version>` và push cả branch lẫn tag (`git push origin <branch> && git push origin v<version>`). Không giữ commit/tag release ở local.
8. Kiểm chứng CI/Release sau khi push: `gh run list --limit 1` / `gh run view` thành công, `gh release view v<version>` tồn tại, file ZIP tải được (HTTP 200/302). Nếu CI lỗi phải khắc phục ngay.
9. Báo cáo cuối bắt buộc có các mục: Test results, Docs/README đã cập nhật (hoặc "không cần đổi docs" nếu refactor thuần nội bộ), DMG/ZIP đã build + SHA-256, và Git commit/tag + trạng thái CI.

---

## 4. Cổng Kiểm thử Tự động (Automated Verification Gates)

Lệnh chuẩn:
- `make test`: chạy `MacStashTestRunner` gồm 13 bộ test (`CornerGeometryTests`, `OverlayStateMachineTests`, `PomodoroEngineTests`, `BrightnessPolicyTests`, `SettingsPersistenceTests`, `DocumentationIntegrityTests`, `LocalizationTests`, `StashFeatureTests`, `VersionConsistencyTests`, `SideDockLayoutEngineTests`, `SideDockConfigStoreTests`, `SideDockWidgetTests`, `CodeHygieneTests`).
- `swift build` / `swift build -c release`: kiểm tra biên dịch toàn bộ target và không phát sinh compiler warning mới.
- `./Scripts/render_icons.sh`: tái tạo toàn bộ brand & UI visual assets từ SVG nguồn.

---

## 5. Không Được Làm (Hard Guardrails)

- Tự ý thêm dependency bên ngoài lớn ngoài Sparkle 2 và system frameworks của Apple.
- Commit khóa bí mật (`Scripts/.sparkle_keys.json`, `.env`, `*.key`, token API).
- Chỉnh sửa phần đang chạy tốt ngoài phạm vi hoặc ghi đè thay đổi WIP của người dùng khi chưa được yêu cầu.
- Che lỗi bằng `try?`, bỏ qua lỗi persistence/process, dùng `NSLog`/`print` trong `Sources/`, dùng `try!`/`as!`/`Bundle.module` hoặc thêm emoji.
- Hardcode số phiên bản trong chuỗi UI/catalog, sửa tay file PNG/ICNS nhị phân, hoặc để `README.md`/hình minh họa bị lệch so với code khi release.
- Đặt Segmented Picker nằm ngang cạnh nhãn dài trong `SettingsCard` gây tràn viền/cắt chữ, hoặc hardcode khoảng cách điểm làm trùng đè các nút điều khiển trong Corner Dial / Edge Bar.
- Ghi đè `elapsedTime` thành 0 khi cùng một bản nhạc đang tiếp tục phát.
- Báo "xong" khi chưa chạy lại `make test` và kiểm chứng thực tế sau chỉnh sửa cuối cùng.
