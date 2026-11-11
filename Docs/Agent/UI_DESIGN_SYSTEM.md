# MacStash & SideDock UI Design System Reference

Tài liệu tham chiếu chi tiết về hệ thống thiết kế giao diện (Design System), vật liệu Liquid Glass, công thái học tương tác và tiêu chuẩn hiệu năng/accessibility cho các module `MacStash` và `SideDockUI`.

---

## 1. Triết lý & Ngôn ngữ Vật liệu (Apple HIG + Liquid Glass)

### 1.1 Kiến trúc 4 lớp của Liquid Glass
Được cài đặt chuẩn hóa tại [`LiquidGlassMaterial.swift`](../../Sources/MacStash/Views/Components/LiquidGlassMaterial.swift) (`.liquidGlass(...)`, `.circularLiquidGlass(...)`) và [`SideDockGlassBackdrop.swift`](../../Sources/SideDockUI/Theme/SideDockGlassBackdrop.swift):
1. **Refractive Substrate**: `.ultraThinMaterial` (hoặc `.regularMaterial` cho `lightGlass`).
2. **Contrast Stabilizer**: Lớp phủ màu trung tính mỏng (`black.opacity(0.14–0.28)` ở Dark / `white.opacity(0.24–0.28)` ở Light) đảm bảo chữ và icon đọc rõ trên hình nền phức tạp.
3. **Caustic Ambient Glow**: RadialGradient xuất phát từ `.topLeading` theo màu nhấn của chức năng đang hoạt động (`tint`).
4. **Specular Rim Bevel & Directional Shadow**: Viền `strokeBorder` mô phỏng nguồn sáng ảo 135° từ góc trên-trái kết hợp bóng đổ 2 tầng (contact shadow + ambient tint halo).

### 1.2 Theme Parity & Màu Chức năng
- Luôn hỗ trợ đồng bộ 4 chế độ (`Match System`, `Light`, `Dark`, và `Clear` đối với SideDock) qua `.macStashTheme(appState.resolvedColorScheme)`.
- Bảng màu nhấn chức năng đặc trưng (tham chiếu [01-brief.md](../../Design/Logo/01-brief.md)):
  - **Volume / Audio**: Azure Blue (`#2E9EFF` -> `#0D61F2`)
  - **Display Brightness**: Warm Amber (`#FFC22E` -> `#FF7A00`)
  - **Keyboard Backlight**: Teal / Cyan (`#38D9C7` -> `#1A99BF`)
  - **Pomodoro Focus**: Amethyst Violet (`#C76BFF` -> `#7A38F2`)
  - **Brand Accent**: Electric Azure (`#0A84FF`) trên Deep Space Slate (`#16181D`)
- Tuyệt đối không hardcode `.white` hoặc `.black` cho văn bản nội dung; ưu tiên `.primary`, `.secondary` trừ trường hợp nằm trên badge/button màu nhấn đặc có độ tương phản đạt WCAG AA (`>= 4.5:1`).

---

## 2. Thành phần UI Chuẩn Hóa (Reuse Before Building)

| Component / Modifier | File | Khi nào sử dụng |
|---|---|---|
| `.liquidGlass(...)` / `.circularLiquidGlass(...)` | `Sources/MacStash/Views/Components/LiquidGlassMaterial.swift` | Mọi card nổi, drawer, nút vệ tinh tròn, radial dial |
| `SideDockGlassBackdrop` | `Sources/SideDockUI/Theme/SideDockGlassBackdrop.swift` | Nền thanh Second Dock (`lightGlass`, `darkGlass`, `clear`, `liquidGlass`, `autoSystem`) |
| `SettingsCard` | `Sources/MacStash/Views/Components/MacStashUIComponents.swift` | Mọi nhóm tùy chọn trong cửa sổ Settings 8 tab (thay cho `GroupBox` thô) |
| `StatusBadgePill` | `Sources/MacStash/Views/Components/MacStashUIComponents.swift` | Nhãn trạng thái Active/Paused, Granted/Missing, Sparkle status |
| `StashBrandLogoView` | `Sources/MacStash/Views/Components/StashBrandLogoView.swift` | Header sidebar Settings, Onboarding, User Guide, About |
| `LiquidFluidTrack` | `Sources/MacStash/Views/Components/LiquidFluidTrack.swift` | Thanh trượt chất lỏng cho Edge Slider |
| `DancingVisualizerView` | `Sources/MacStash/Views/Components/DancingVisualizerView.swift` | Sóng nhạc 5 cột (bắt buộc idle-gated khi overlay ẩn) |

---

## 3. Công thái học Tương tác Không Điểm Chạm (Fitts's Law & NSPanel)

- **Góc màn hình & Vành cung 45°**:
  - Đối xứng hình học 4 góc qua `CornerGeometry.isOuterCorner` (tránh kích hoạt tại đường nối hai màn hình).
  - Vùng đệm `19pt` / `cornerWindowPaddingPoints` cân bằng; `21` vạch chia độ đối xứng với các vạch chính tại `0%`, `25%`, `50%`, `75%`, `100%`.
- **Cửa sổ Không Cướp Focus & Pass-Through**:
  - Panel nền dùng `.nonactivatingPanel`, `.canJoinAllSpaces`, `canBecomeKey = false` (trừ khi mở nhập liệu chủ động trên Scratchpad hoặc Search Widget).
  - `PassThroughHostingView`, `EdgeSliderHostingView`, `StashShelfHostingView`, `SideDockHostingView` trả về `nil` trong `hitTest(_:)` khi ở vùng trong suốt hoặc trạng thái ẩn.
- **Bảo vệ Chống Kích hoạt Nhầm**:
  - Dwell delay (`Defaults.HotCorner.defaultDwellDelaySeconds = 0.2s`), auto-hide grace (`0.25s`), chặn khi `NSEvent.pressedMouseButtons != 0`, chặn trong fullscreen (khi bật suppress), và bỏ qua ứng dụng trong danh sách loại trừ.

---

## 4. Hiệu năng 120Hz ProMotion & Accessibility Checklist

- **Typography**: Mọi chỉ số thời gian thực (%, timer `MM:SS`, timestamp media, CPU/RAM) dùng `.monospacedDigit()` để cố định độ rộng ký tự.
- **Shape & Spacing**: Lưới khoảng cách 4pt / 8pt; mọi bo góc dùng `style: .continuous`.
- **Cuộn & Xúc giác**: Đồng bộ hướng cuộn tự nhiên qua `event.isDirectionInvertedFromDevice`; tích hợp `NSHapticFeedbackManager` và âm thanh click cơ học với ngưỡng chống dội (`minSoundIntervalSeconds = 0.035s`).
- **Tối ưu Render**:
  - Cô lập item thành subview (`StashItemCardView`) và lấy icon qua `StashIconCache` (zero LaunchServices disk I/O trên main thread).
  - Duy trì `SideDockRootWrapper` làm persistent hosting view để không mất trạng thái scroll/timer widget khi `RunningAppsMonitor` cập nhật.
  - Ngừng timer/visualizer khi overlay ẩn (CPU idle < 1%).
- **Accessibility**:
  - Bắt buộc `.accessibilityLabel`, `.accessibilityValue` (kèm đơn vị), `.accessibilityHint` cho mọi nút chỉ icon, radial dial, edge bar và dock tile.
  - Kiểm tra `NSWorkspace.shared.accessibilityDisplayShouldReduceMotion` (và cài đặt `reduceMotion`) để thu gọn animation sang crossfade hoặc chuyển trạng thái tức thì.
  - Không dùng emoji làm biểu tượng giao diện; dùng SF Symbols (`Image(systemName:)`) với `.symbolRenderingMode(.hierarchical)` hoặc vector SVG.
