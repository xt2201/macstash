import SwiftUI
import AppKit
import MacStashCore

public struct GuideArticle: Identifiable, Equatable {
    public let id: String
    public let title: String
    public let iconName: String
    public let content: String
}

public struct UserGuideView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var appState: AppState
    @State private var articles: [GuideArticle] = []
    @State private var selectedArticleID: String?
    @State private var searchText: String = ""

    public init(appState: AppState = .shared) {
        self.appState = appState
    }

    private var filteredArticles: [GuideArticle] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if query.isEmpty {
            return articles
        }
        return articles.filter {
            $0.title.localizedCaseInsensitiveContains(query) ||
            $0.content.localizedCaseInsensitiveContains(query)
        }
    }

    private var selectedArticle: GuideArticle? {
        filteredArticles.first(where: { $0.id == selectedArticleID }) ?? filteredArticles.first
    }

    public var body: some View {
        HStack(spacing: 0) {
            sidebarView
                .frame(width: 245)
                .background(GuideSidebarEffectBackground())

            Divider()

            detailView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(minWidth: 680, minHeight: 480)
        .macStashTheme(appState.resolvedColorScheme)
        .onAppear {
            reloadArticles()
        }
        .onChange(of: appState.effectiveLanguage) { _, _ in
            reloadArticles()
        }
        .onChange(of: searchText) { _, _ in
            ensureValidSelection()
        }
    }

    // MARK: - Sidebar

    private var sidebarView: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                StashBrandLogoView(size: 26, showWordmark: false)
                Text(appState.localized("guide.windowTitle"))
                    .font(.system(size: 13.5, weight: .bold))
                    .lineLimit(1)
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 10)

            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)

                TextField(appState.localized("guide.searchPlaceholder"), text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.primary.opacity(0.06))
            )
            .padding(.horizontal, 12)
            .padding(.bottom, 10)

            Divider()
                .padding(.horizontal, 12)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(filteredArticles) { article in
                        let isSelected = selectedArticle?.id == article.id
                        Button {
                            selectedArticleID = article.id
                        } label: {
                            HStack(spacing: 9) {
                                Image(systemName: article.iconName)
                                    .font(.system(size: 11.5, weight: .semibold))
                                    .foregroundColor(isSelected ? .white : .accentColor)
                                    .frame(width: 22, height: 22)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .fill(isSelected ? AnyShapeStyle(Color.accentColor.gradient) : AnyShapeStyle(Color.accentColor.opacity(0.12)))
                                    )

                                Text(article.title)
                                    .font(.system(size: 12.5, weight: isSelected ? .semibold : .medium))
                                    .foregroundColor(.primary)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)

                                Spacer(minLength: 0)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(10)
            }
        }
    }

    // MARK: - Detail Reader

    private var detailView: some View {
        Group {
            if let article = selectedArticle {
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 14) {
                        MarkdownArticleView(markdown: article.content)
                    }
                    .padding(28)
                    .frame(maxWidth: 740, alignment: .leading)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                }
                .id(article.id)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary.opacity(0.6))
                    Text(appState.localized("guide.emptySelection"))
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    // MARK: - Loading

    private func reloadArticles() {
        let lang = appState.effectiveLanguage
        articles = Self.loadArticles(language: lang)
        ensureValidSelection()
    }

    private func ensureValidSelection() {
        if let current = selectedArticleID,
           filteredArticles.contains(where: { $0.id == current }) {
            return
        }
        selectedArticleID = filteredArticles.first?.id
    }

    public static func loadArticles(language: String = "en") -> [GuideArticle] {
        let folder = language == "vi" ? "vi" : "en"
        let specs: [(file: String, icon: String)] = [
            ("01_getting_started.md", "play.circle.fill"),
            ("02_display_brightness.md", "sun.max.fill"),
            ("03_pomodoro_timer.md", "timer"),
            ("04_troubleshooting.md", "wrench.and.screwdriver.fill"),
            ("05_settings.md", "gearshape.fill"),
            ("06_shortcuts.md", "keyboard.fill"),
            ("07_faq.md", "questionmark.circle.fill"),
            ("08_whats_new.md", "sparkles")
        ]

        var result: [GuideArticle] = []
        for spec in specs {
            let candidates = [
                "Docs/Guide/\(folder)/\(spec.file)",
                "../Docs/Guide/\(folder)/\(spec.file)",
                "../../Docs/Guide/\(folder)/\(spec.file)"
            ]

            var loadedContent: String?
            for path in candidates where FileManager.default.fileExists(atPath: path) {
                loadedContent = try? String(contentsOfFile: path, encoding: .utf8)
                if loadedContent != nil { break }
            }

            if loadedContent == nil {
                if let bundleURL = Bundle.main.url(forResource: spec.file, withExtension: nil, subdirectory: "Docs/Guide/\(folder)") ??
                    Bundle.main.url(forResource: spec.file, withExtension: nil, subdirectory: "Guide/\(folder)") {
                    loadedContent = try? String(contentsOf: bundleURL, encoding: .utf8)
                }
            }

            if let text = loadedContent {
                let firstHeading = text.components(separatedBy: .newlines).first(where: { $0.hasPrefix("# ") })
                let title = firstHeading?.replacingOccurrences(of: "# ", with: "").trimmingCharacters(in: .whitespaces)
                    ?? spec.file.replacingOccurrences(of: ".md", with: "")
                result.append(GuideArticle(id: spec.file, title: title, iconName: spec.icon, content: text))
            }
        }

        if !result.isEmpty {
            return result
        }
        return fallbackArticles(language: folder)
    }

    private static func fallbackArticles(language: String) -> [GuideArticle] {
        let isVi = language == "vi"
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? Defaults.appVersion

        return [
            GuideArticle(
                id: "01_getting_started.md",
                title: isVi ? "Bắt đầu nhanh với MacStash" : "Getting Started with MacStash",
                iconName: "play.circle.fill",
                content: isVi ? """
                # Bắt đầu nhanh với MacStash

                MacStash bổ sung **Vòng xoay góc màn hình (Corner Dials)**, **Thanh trượt cạnh màn hình**, **Bảng chọn tại con trỏ (Cursor Palette)**, **Kệ thả tệp (Stash Shelf)**, **Ghi chú nhanh (Scratchpad)** và **Thanh Dock thứ hai (Second Dock)** ngay trên màn hình macOS.

                ## 3 bước sử dụng nhanh
                1. **Cấp quyền Trợ năng (Accessibility)** để MacStash theo dõi con trỏ chuột tại góc và mép màn hình.
                2. **Đưa con trỏ chuột vào 1 trong 4 góc ngoài màn hình** và dừng lại 0.2 giây để núm xoay Liquid Glass mở ra.
                3. **Kéo theo cung tròn** hoặc dùng **cuộn hai ngón** để tinh chỉnh độ sáng, âm lượng, đèn bàn phím, hoặc Pomodoro.
                """ : """
                # Getting Started with MacStash

                MacStash brings **Hot Corner Dials**, **Edge Sliders**, a **Cursor Radial Palette**, a **Stash Drop Shelf**, **Quick Scratchpad**, and a widget-powered **Second Dock** to macOS.

                ## Quick Start
                1. **Grant Accessibility Permission** so MacStash can detect outer corners and vertical edges cleanly.
                2. **Hover into any outer screen corner** for 0.2s to bloom a Liquid Glass radial dial.
                3. **Drag along the arc** or **scroll with two fingers** to adjust brightness, volume, backlight, or focus timers.
                """
            ),
            GuideArticle(
                id: "05_settings.md",
                title: isVi ? "Hướng dẫn 8 mục Cài đặt" : "Settings Reference Guide",
                iconName: "gearshape.fill",
                content: isVi ? """
                # Cửa sổ Cài đặt MacStash (8 mục)

                Mở Cài đặt bất kỳ lúc nào qua menu bar hoặc phím tắt `Command+,`:

                - **Tổng quan (General)**: Công tắc tổng, bảng trạng thái 6 module, thời lượng Keep Awake mặc định, ngôn ngữ, quyền hệ thống và đặt lại mặc định.
                - **Góc nóng (Hot Corners)**: Sơ đồ màn hình tương tác, cấu hình 4 góc, hồ sơ theo ứng dụng (App Profiles), thanh trượt cạnh Trái/Phải và loại trừ ứng dụng.
                - **Thanh Dock thứ hai (Second Dock)**: Quản lý hồ sơ, chọn 16 tiện ích trực tiếp từ Widget Gallery, vị trí neo hoặc thả nổi.
                - **Giao diện (Appearance)**: Thử nghiệm Liquid Glass trực tiếp trên nền sáng/tối, bán kính, độ mờ kính và phản hồi rung/âm thanh.
                - **Màn hình (Displays)**: Chọn DDC/CI phần cứng hay giảm sáng phần mềm, các mức đặt nhanh (25–100%) và ngưỡng tối thiểu/tối đa.
                - **Pomodoro**: Vòng đếm ngược trực tiếp, chuyển chế độ tập trung/nghỉ và cấu hình thời lượng.
                - **Phím tắt (Shortcuts)**: Bộ ghi phím trực quan và phát hiện xung đột phím tắt macOS.
                - **Thông tin & Sao lưu (About / Advanced)**: Kiểm tra cập nhật tự động Sparkle 2, xuất/nhập cấu hình JSON và nhật ký gỡ lỗi.
                """ : """
                # MacStash Settings (8 Categories)

                Open Settings anytime from the Menu Bar or press `Command+,`:

                - **General**: Master switch, 6-module status matrix, default Keep Awake duration, language, system permissions, and factory reset.
                - **Hot Corners**: Interactive screen overview map, per-corner assignments, per-app profiles, configurable Left/Right edge slider and drawers, and excluded apps.
                - **Second Dock**: Multi-profile dock management, 16 live widgets from the Widget Gallery, fixed or floating placement.
                - **Appearance**: Live Interactive Liquid Glass Studio with light/dark backdrop testing, radius, translucency, motion, and haptics.
                - **Displays**: DDC/CI hardware vs software dimming, quick brightness presets, and safe hardware min/max clamps.
                - **Pomodoro**: Live circular countdown hero, manual mode switching, intervals, and chimes.
                - **Shortcuts**: Keycap shortcut recorders with automatic macOS reserved conflict detection.
                - **About / Advanced**: Sparkle 2 updates, Console diagnostics, JSON backup & restore, and factory reset.
                """
            ),
            GuideArticle(
                id: "06_shortcuts.md",
                title: isVi ? "Bảng tra cứu phím tắt" : "Keyboard Shortcuts",
                iconName: "keyboard.fill",
                content: isVi ? """
                # Phím tắt chuẩn

                | Phím tắt | Chức năng |
                | --- | --- |
                | `Option+S` | Bật / Tắt toàn bộ vòng xoay góc |
                | `Option+Space` | Mở Vòng xoay tại con trỏ chuột (Cursor Palette) |
                | `Control+Option+S` | Mở / Đóng Kệ thả tệp (Stash Shelf) |
                | `Control+Option+N` | Mở / Đóng Ghi chú nhanh (Scratchpad) |
                | `Control+Option+D` | Ẩn / Hiện Thanh Dock thứ hai |
                | `Command+1..8` | Chuyển nhanh hồ sơ Thanh Dock thứ hai |
                | `Command+,` | Mở cửa sổ Cài đặt |
                | `Command+?` | Mở Hướng dẫn sử dụng |
                | `Command+W` | Đóng cửa sổ hiện tại |
                | `Command+Q` | Thoát MacStash |
                | `Esc` | Đóng lớp phủ đang mở |
                """ : """
                # Standard Shortcuts

                | Shortcut | Action |
                | --- | --- |
                | `Option+S` | Toggle Corner Dials on/off |
                | `Option+Space` | Summon Cursor Radial Palette |
                | `Control+Option+S` | Toggle Stash Drop Shelf |
                | `Control+Option+N` | Toggle Quick Scratchpad |
                | `Control+Option+D` | Toggle Second Dock |
                | `Command+1..8` | Switch Second Dock profile |
                | `Command+,` | Open Settings Window |
                | `Command+?` | Open User Guide |
                | `Command+W` | Close active window |
                | `Command+Q` | Quit MacStash |
                | `Esc` | Dismiss active overlay |
                """
            ),
            GuideArticle(
                id: "08_whats_new.md",
                title: isVi ? "Có gì mới (\(currentVersion))" : "What's New (\(currentVersion))",
                iconName: "sparkles",
                content: isVi ? """
                # Phiên bản \(currentVersion)

                - Thiết kế lại toàn diện giao diện Cài đặt dạng sidebar hiện đại, bảng Menu Bar Control Center, Onboarding và trình đọc tài liệu Markdown.
                - Bổ sung Sơ đồ màn hình tương tác, bộ ghi phím tắt Keycap và Studio thử nghiệm Liquid Glass trực tiếp.
                - Khắc phục hoàn toàn lỗi phát hiện cạnh Trái/Phải cho Edge Slider và Drawer, lỗi trạng thái Widget khi mở Second Dock, cùng nhiều cải tiến hiệu năng.
                """ : """
                # Version \(currentVersion)

                - Complete UI/UX overhaul across sidebar Settings, Menu Bar Control Center, Onboarding graphics, and rich Markdown User Guide.
                - Added Interactive Screen Map, Keycap Shortcut Recorders, and Live Interactive Liquid Glass Studio.
                - Fixed symmetric Left/Right edge slider and drawer triggers, Second Dock persistent widget hosting, and background CPU/polling efficiency.
                """
            )
        ]
    }
}

private struct GuideSidebarEffectBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .sidebar
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
