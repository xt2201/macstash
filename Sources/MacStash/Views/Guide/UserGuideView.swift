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

// MARK: - Rich Native SwiftUI Markdown Renderer

private struct MarkdownArticleView: View {
    @Environment(\.colorScheme) private var colorScheme
    let markdown: String

    private enum Block: Identifiable {
        case heading(id: Int, level: Int, text: String)
        case paragraph(id: Int, text: String)
        case bullet(id: Int, text: String)
        case numbered(id: Int, prefix: String, text: String)
        case blockquote(id: Int, text: String)
        case codeBlock(id: Int, lines: [String])
        case table(id: Int, headers: [String], rows: [[String]])
        case divider(id: Int)

        var id: Int {
            switch self {
            case .heading(let id, _, _),
                 .paragraph(let id, _),
                 .bullet(let id, _),
                 .numbered(let id, _, _),
                 .blockquote(let id, _),
                 .codeBlock(let id, _),
                 .table(let id, _, _),
                 .divider(let id):
                return id
            }
        }
    }

    var body: some View {
        let blocks = parseBlocks(from: markdown)
        VStack(alignment: .leading, spacing: 10) {
            ForEach(blocks) { block in
                renderBlock(block)
            }
        }
        .textSelection(.enabled)
    }

    @ViewBuilder
    private func renderBlock(_ block: Block) -> some View {
        switch block {
        case .heading(_, let level, let text):
            VStack(alignment: .leading, spacing: 6) {
                inlineText(text)
                    .font(.system(
                        size: level == 1 ? 22 : (level == 2 ? 16 : 13.5),
                        weight: level <= 2 ? .bold : .semibold
                    ))
                    .foregroundColor(.primary)
                    .padding(.top, level == 1 ? 0 : 8)

                if level == 1 {
                    Divider()
                        .padding(.bottom, 4)
                }
            }

        case .paragraph(_, let text):
            inlineText(text)
                .font(.system(size: 13))
                .foregroundColor(.primary.opacity(0.9))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

        case .bullet(_, let text):
            HStack(alignment: .top, spacing: 8) {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 5, height: 5)
                    .padding(.top, 6)

                inlineText(text)
                    .font(.system(size: 13))
                    .foregroundColor(.primary.opacity(0.9))
                    .lineSpacing(3.5)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.leading, 6)

        case .numbered(_, let prefix, let text):
            HStack(alignment: .top, spacing: 8) {
                Text(prefix)
                    .font(.system(size: 12.5, weight: .bold, design: .rounded))
                    .foregroundColor(.accentColor)
                    .frame(minWidth: 18, alignment: .trailing)

                inlineText(text)
                    .font(.system(size: 13))
                    .foregroundColor(.primary.opacity(0.9))
                    .lineSpacing(3.5)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.leading, 4)

        case .blockquote(_, let text):
            HStack(alignment: .top, spacing: 10) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.accentColor)
                    .frame(width: 3)

                inlineText(text)
                    .font(.system(size: 12.5))
                    .foregroundColor(.secondary)
                    .lineSpacing(3.5)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.accentColor.opacity(0.08))
            )

        case .codeBlock(_, let lines):
            Text(lines.joined(separator: "\n"))
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.primary)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.7)
                )

        case .table(_, let headers, let rows):
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    ForEach(Array(headers.enumerated()), id: \.offset) { colIdx, header in
                        inlineText(header)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        if colIdx < headers.count - 1 {
                            Divider()
                        }
                    }
                }
                .background(Color.primary.opacity(0.06))

                ForEach(Array(rows.enumerated()), id: \.offset) { rowIdx, row in
                    Divider()
                    HStack(spacing: 0) {
                        ForEach(0..<headers.count, id: \.self) { colIdx in
                            let cell = colIdx < row.count ? row[colIdx] : ""
                            inlineText(cell)
                                .font(.system(size: 12))
                                .foregroundColor(.primary.opacity(0.9))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            if colIdx < headers.count - 1 {
                                Divider()
                            }
                        }
                    }
                    .background(rowIdx % 2 == 1 ? Color.primary.opacity(0.025) : Color.clear)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.12), lineWidth: 0.8)
            )

        case .divider:
            Divider()
                .padding(.vertical, 4)
        }
    }

    private func inlineText(_ raw: String) -> Text {
        if let attr = try? AttributedString(
            markdown: raw,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        ) {
            return Text(attr)
        }
        return Text(raw)
    }

    private func parseBlocks(from raw: String) -> [Block] {
        let lines = raw.components(separatedBy: .newlines)
        var blocks: [Block] = []
        var idx = 0
        var nextID = 0

        func makeID() -> Int {
            defer { nextID += 1 }
            return nextID
        }

        while idx < lines.count {
            let line = lines[idx]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty {
                idx += 1
                continue
            }

            if trimmed.hasPrefix("```") {
                idx += 1
                var codeLines: [String] = []
                while idx < lines.count && !lines[idx].trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                    codeLines.append(lines[idx])
                    idx += 1
                }
                if idx < lines.count { idx += 1 }
                blocks.append(.codeBlock(id: makeID(), lines: codeLines))
                continue
            }

            if trimmed == "---" || trimmed == "***" {
                blocks.append(.divider(id: makeID()))
                idx += 1
                continue
            }

            if trimmed.hasPrefix("# ") {
                blocks.append(.heading(id: makeID(), level: 1, text: String(trimmed.dropFirst(2))))
                idx += 1
                continue
            }

            if trimmed.hasPrefix("## ") {
                blocks.append(.heading(id: makeID(), level: 2, text: String(trimmed.dropFirst(3))))
                idx += 1
                continue
            }

            if trimmed.hasPrefix("### ") {
                blocks.append(.heading(id: makeID(), level: 3, text: String(trimmed.dropFirst(4))))
                idx += 1
                continue
            }

            if trimmed.hasPrefix("> ") {
                var quoteLines = [String(trimmed.dropFirst(2))]
                idx += 1
                while idx < lines.count {
                    let nextTrimmed = lines[idx].trimmingCharacters(in: .whitespaces)
                    if nextTrimmed.hasPrefix("> ") {
                        quoteLines.append(String(nextTrimmed.dropFirst(2)))
                        idx += 1
                    } else {
                        break
                    }
                }
                blocks.append(.blockquote(id: makeID(), text: quoteLines.joined(separator: "\n")))
                continue
            }

            // Markdown table detection: | col1 | col2 |
            if trimmed.hasPrefix("|") && idx + 1 < lines.count {
                let separatorCandidate = lines[idx + 1].trimmingCharacters(in: .whitespaces)
                if separatorCandidate.hasPrefix("|") && separatorCandidate.contains("---") {
                    let headers = parseTableRow(trimmed)
                    idx += 2
                    var rows: [[String]] = []
                    while idx < lines.count {
                        let rowTrimmed = lines[idx].trimmingCharacters(in: .whitespaces)
                        if rowTrimmed.hasPrefix("|") {
                            rows.append(parseTableRow(rowTrimmed))
                            idx += 1
                        } else {
                            break
                        }
                    }
                    blocks.append(.table(id: makeID(), headers: headers, rows: rows))
                    continue
                }
            }

            if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
                blocks.append(.bullet(id: makeID(), text: String(trimmed.dropFirst(2))))
                idx += 1
                continue
            }

            if let dotRange = trimmed.range(of: ". "),
               dotRange.lowerBound > trimmed.startIndex,
               let _ = Int(trimmed[..<dotRange.lowerBound]) {
                let prefix = String(trimmed[...dotRange.lowerBound])
                let rest = String(trimmed[dotRange.upperBound...])
                blocks.append(.numbered(id: makeID(), prefix: prefix, text: rest))
                idx += 1
                continue
            }

            // Merge consecutive plain lines into one paragraph
            var paraLines = [trimmed]
            idx += 1
            while idx < lines.count {
                let peek = lines[idx].trimmingCharacters(in: .whitespaces)
                if peek.isEmpty || peek.hasPrefix("#") || peek.hasPrefix("- ") || peek.hasPrefix("* ") ||
                    peek.hasPrefix("> ") || peek.hasPrefix("```") || peek.hasPrefix("|") || peek == "---" {
                    break
                }
                if let dotRange = peek.range(of: ". "),
                   dotRange.lowerBound > peek.startIndex,
                   let _ = Int(peek[..<dotRange.lowerBound]) {
                    break
                }
                paraLines.append(peek)
                idx += 1
            }
            blocks.append(.paragraph(id: makeID(), text: paraLines.joined(separator: " ")))
        }

        return blocks
    }

    private func parseTableRow(_ line: String) -> [String] {
        var trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("|") { trimmed.removeFirst() }
        if trimmed.hasSuffix("|") { trimmed.removeLast() }
        return trimmed.split(separator: "|", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }
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
