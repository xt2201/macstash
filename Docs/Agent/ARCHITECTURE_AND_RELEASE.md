# MacStash Architecture, Refactor Roadmap & Release Reference

Tài liệu tham chiếu kỹ thuật sâu về phân rã module, quy trình phát hành Sparkle 2, lộ trình giảm nợ file lớn và định hướng kiến trúc Milestone M6.

---

## 1. Trạng thái Kiến trúc Thực tế & Các Ngoại lệ được Phê duyệt

### 1.1 Hệ điều hành & Concurrency
- **Minimum OS**: `macOS 14.0+` (Sonoma, Sequoia và mới hơn) — khớp với `Package.swift` (`.macOS(.v14)`), `project.yml` (`14.0`), `Scripts/Info.plist` (`LSMinimumSystemVersion = 14.0`) và SwiftUI API sử dụng trong dự án (ví dụ hai-tham-số `.onChange(of:)`).
- **StrictConcurrency**: Bật ở `MacStashCore`, `SideDockCore`, `SideDockWidgets`, `SideDockUI`, `SideDockSystem`, `MacStash`.

### 1.2 Biên giới Private Framework & Hardware Bridges
- Không được thêm bất kỳ Private Framework mới nào.
- Hai cầu nối đặc thù đang được phê duyệt (cập nhật thực tế từ `DECISIONS.md` ADR-004 / ADR-010):
  1. `BuiltInBrightnessService` (`Sources/MacStashCore/Services/Implementations/BuiltInBrightnessService.swift`): tải động `DisplayServices.framework` qua `dlopen` / `dlsym` cho màn hình tích hợp Apple Silicon/Retina; nếu thất bại tự động fallback qua `SoftwareDimmingService` hoặc `DDCBrightnessService` (I2C/DDC với timeout `0.1s` trên background queue).
  2. `MacStashNowPlaying` (`Sources/MacStashNowPlaying/NowPlayingAdapter.swift` + `now-playing.pl`): tải `MediaRemote.framework` bên trong tiến trình platform binary `/usr/bin/perl` để khắc phục giới hạn entitlement trên macOS 15.4+; phải fail-graceful khi không khả dụng và fallback sang AppleScript.

---

## 2. Lộ trình Giảm Nợ God-Files (Refactor-on-Touch Map)

Khi chỉnh sửa đáng kể một trong các file vượt ngưỡng 400 dòng dưới đây, ưu tiên tách theo ranh giới trách nhiệm thay vì thêm logic vào file gốc:

| File hiện tại | Dòng (tham chiếu) | Hướng tách module đề xuất |
|---|---|---|
| `Sources/MacStash/Core/ScreenManager.swift` | ~1170 | `CornerDwellCoordinator`, `EdgeTriggerCoordinator`, `GlobalHotkeyCoordinator`, `DragShakeDetector` |
| `Sources/MacStashCore/Localization/LocalizationService.swift` | ~1033 | Tách bảng chuỗi thành `LocalizationCatalog+Core.swift`, `LocalizationCatalog+Settings.swift`, `LocalizationCatalog+SideDock.swift` (hoặc JSON bundle trong `Bundle.main`) |
| `Sources/MacStash/Views/CornerDials/CornerDialView.swift` | ~1031 | `DialMeniscusLayer`, `DialTransportOverlay`, `DialUtilityDropTarget` |
| `Sources/MacStash/Views/Settings/HotCornersTab.swift` | ~944 | `InteractiveScreenMapView`, `CornerConfigSection`, `AppProfileListSection`, `SuppressionRulesSection` |
| `Sources/MacStashNowPlaying/NowPlayingAdapter.swift` | ~746 | Tách phần `dlopen` symbol bindings khỏi session polling & artwork serializer |
| `Sources/MacStash/Core/NowPlayingManager.swift` | ~714 | Tách Perl subprocess transport khỏi state & visualizer gating |
| `Sources/MacStash/Views/Guide/UserGuideView.swift` | ~703 | Tách Markdown parser/block renderer khỏi Split Sidebar Shell |
| `Sources/MacStash/App/AppState.swift` | ~690 | Tách `AppState+SettingsSync.swift`, `AppState+Pomodoro.swift`, `AppState+ControlActions.swift` |
| `Sources/MacStash/Views/MenuBar/MenuBarExtraView.swift` | ~665 | Tách thành các card riêng: `MenuBarDisplayBrightnessCard`, `MenuBarModulesGrid`, `MenuBarMediaCard` |
| `Sources/SideDockUI/Settings/DockSettingsTabView.swift` | ~575 | Tách `DockProfilesSection`, `DockPlacementSection`, `DockBehaviorSection`, `DockItemsSection` |

---

## 3. Release & Ship Pipeline Checklist (Chế độ B)

### 3.1 Kiểm tra 6 vị trí Versioning (SSOT: `VERSION`)
1. `VERSION`: Chuỗi `X.Y.Z` (ví dụ `2.15.0`).
2. `Scripts/Info.plist`: `CFBundleShortVersionString` = `X.Y.Z`, `CFBundleVersion` = chuỗi số không dấu chấm (ví dụ `2150`).
3. `CHANGELOG.md`: Thêm `## [X.Y.Z] - YYYY-MM-DD` với `Added` / `Changed` / `Fixed` (0 emoji).
4. `Docs/Guide/en/08_whats_new.md` và `Docs/Guide/vi/08_whats_new.md`: Đối xứng hai ngôn ngữ, chứa `Version X.Y.Z` và `Phiên Bản X.Y.Z` (hoặc `Phiên bản X.Y.Z`), 0 emoji.
5. `README.md`: Cập nhật badge `release-vX.Y.Z` và link tải `MacStash-vX.Y.Z.dmg`, cộng mọi thay đổi Feature/Shortcuts/Permissions/Visual Showcase.
6. `appcast.xml`: Tự động cập nhật bằng `./Scripts/build_dmg.sh` gọi `Scripts/sign_sparkle_update.swift` + `Scripts/update_appcast.swift`.

### 3.2 Lệnh Chuẩn Khi Phát hành
```bash
# 1. Nếu có đổi SVG nguồn tại Design/Logo/source/
./Scripts/render_icons.sh

# 2. Chạy toàn bộ kiểm thử tự động & kiểm tra biên dịch sạch warning
make test
swift build -c release

# 3. Đóng gói Universal DMG + Sparkle ZIP ký Ed25519 + cập nhật appcast.xml
./Scripts/build_dmg.sh

# 4. Cập nhật /Applications/Stash.app và mở lại bản mới nhất trên máy cục bộ
pkill -x Stash || true
rm -rf /Applications/Stash.app && ditto .build/package_staging/Stash.app /Applications/Stash.app
open /Applications/Stash.app

# 5. Commit, tag và push lên remote (chỉ chạy khi release tree sạch)
git tag v$(cat VERSION)
git push origin main && git push origin v$(cat VERSION)

# 6. Kiểm chứng GitHub Actions & Release
gh run list --limit 1
gh release view v$(cat VERSION)
```

### 3.3 Bảo mật Khóa Sparkle 2
- Public key đặt tại `SUPublicEDKey` trong `Scripts/Info.plist`.
- Private key lưu ở GitHub Secret `SPARKLE_PRIVATE_KEY` và file cục bộ `Scripts/.sparkle_keys.json` (đã có trong `.gitignore`). Tuyệt đối không commit private key.

---

## 4. Định hướng Chuẩn bị cho Milestone M6 (P2 Advanced)

Khi triển khai các hạng mục M6 từ [`PROGRESS.md`](../../PROGRESS.md#L13) (Connected Widgets, AI Usage Widgets, Local MCP Server, Diagnostics Export):
- **SecretStore (NFR-10)**: Token/API key cho Connected & AI Usage widgets bắt buộc lưu trong macOS Keychain (hoặc mã hóa CryptoKit cục bộ), tuyệt đối không lưu plain-text trong `UserDefaults`, `sidedock_config.json`, hay `.sidedock-profile` khi export.
- **Local MCP Server**: Bind `127.0.0.1` only, mặc định OFF (opt-in trong Settings), yêu cầu xác nhận rõ ràng trước mọi thao tác ghi/điều khiển hệ thống, và tuân thủ `AppLogger` + không block main thread.
- **Diagnostics Export**: Tự động redact mọi token/path nhạy cảm cá nhân trước khi xuất gói chẩn đoán.
