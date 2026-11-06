import SwiftUI
import AppKit
import MacStashCore

public struct GuideArticle: Identifiable {
    public let id: String
    public let title: String
    public let filename: String
    public let content: String

    public init(id: String, title: String, filename: String, content: String) {
        self.id = id
        self.title = title
        self.filename = filename
        self.content = content
    }
}

public struct UserGuideView: View {
    @ObservedObject var appState: AppState
    @State private var selectedArticleID: String = "01_getting_started"
    @State private var searchQuery: String = ""
    @State private var articles: [GuideArticle] = []

    public init(appState: AppState = .shared) {
        self.appState = appState
        _articles = State(initialValue: Self.loadArticles(language: appState.effectiveLanguage))
    }

    public var body: some View {
        NavigationSplitView {
            VStack(spacing: 8) {
                HStack {
                    StashBrandLogoView(size: 26, showWordmark: true)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.top, 10)

                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField(appState.localized("guide.searchPlaceholder"), text: $searchQuery)
                        .textFieldStyle(.plain)
                    if !searchQuery.isEmpty {
                        Button(action: { searchQuery = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(6)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color.secondary.opacity(0.1)))
                .padding(.horizontal, 10)
                .padding(.top, 10)

                List(filteredArticles, id: \.id, selection: $selectedArticleID) { article in
                    NavigationLink(value: article.id) {
                        Label(article.title, systemImage: "doc.text")
                            .font(.system(size: 13, weight: .medium))
                    }
                }
                .listStyle(.sidebar)
            }
            .frame(minWidth: 220, maxWidth: 280)
        } detail: {
            if let active = articles.first(where: { $0.id == selectedArticleID }) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(active.title)
                            .font(.system(size: 20, weight: .bold))

                        Divider()

                        Text(active.content)
                            .font(.system(size: 13))
                            .lineSpacing(4)
                            .textSelection(.enabled)
                    }
                    .padding(24)
                }
            } else {
                Text(appState.localized("guide.emptySelection"))
                    .foregroundColor(.secondary)
            }
        }
        .frame(minWidth: 680, minHeight: 480)
        .onAppear {
            articles = Self.loadArticles(language: appState.effectiveLanguage)
        }
        .onChange(of: appState.effectiveLanguage) { newLang in
            articles = Self.loadArticles(language: newLang)
        }
    }

    private var filteredArticles: [GuideArticle] {
        if searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return articles
        }
        let q = searchQuery.lowercased()
        return articles.filter {
            $0.title.lowercased().contains(q) || $0.content.lowercased().contains(q)
        }
    }

    public static func loadArticles(language: String = "en") -> [GuideArticle] {
        let isVi = language == "vi"
        let folder = isVi ? "vi" : "en"

        func contentFor(filename: String, fallback: String) -> String {
            let paths = [
                "Docs/Guide/\(folder)/\(filename)",
                "../Docs/Guide/\(folder)/\(filename)",
                "../../Docs/Guide/\(folder)/\(filename)"
            ]
            for p in paths {
                if let s = try? String(contentsOfFile: p, encoding: .utf8), !s.isEmpty {
                    return s
                }
            }
            if let bundleUrl = Bundle.main.url(forResource: filename, withExtension: nil, subdirectory: "Docs/Guide/\(folder)") ??
                               Bundle.module.url(forResource: filename, withExtension: nil) {
                if let s = try? String(contentsOf: bundleUrl, encoding: .utf8), !s.isEmpty {
                    return s
                }
            }
            return fallback
        }

        return [
            GuideArticle(
                id: "01_getting_started",
                title: isVi ? "1. Hướng Dẫn Bắt Đầu" : "1. Getting Started",
                filename: "01_getting_started.md",
                content: contentFor(
                    filename: "01_getting_started.md",
                    fallback: isVi ? """
                    MacStash cung cấp các vòng xoay điều khiển hình góc phần tư xuất hiện tinh tế tại bốn góc vật lý của màn hình macOS.

                    Khái Niệm Cốt Lõi:
                    MacStash được thiết kế để duy trì trạng thái ẩn hoàn toàn và không tiêu tốn tài nguyên cho đến khi người dùng cần thao tác. Khi di chuột vào góc kích hoạt và dừng lại trong giây lát, vòng xoay tương ứng sẽ xuất hiện mượt mà.

                    Bốn Góc Vật Lý:
                    - Góc Trên - Trái: Mặc định điều chỉnh đèn bàn phím (Keyboard Backlight).
                    - Góc Trên - Phải: Mặc định điều chỉnh độ sáng màn hình (Display Brightness).
                    - Góc Dưới - Trái: Mặc định đồng hồ tập trung Pomodoro.
                    - Góc Dưới - Phải: Mặc định âm lượng loa tổng (Master Volume).
                    """ : """
                    MacStash provides tactile, quarter-circle radial dial controls that appear seamlessly at the extreme corners of your macOS displays.

                    Core Concepts:
                    MacStash is designed to remain completely invisible and zero-resource until you need it. By resting your mouse cursor at an active corner, the corresponding dial emerges smoothly.

                    The Four Physical Corners:
                    - Top-Left: Configured by default for Keyboard Backlight adjustment.
                    - Top-Right: Configured by default for Display Brightness control.
                    - Bottom-Left: Configured by default for Pomodoro and Focus Timer.
                    - Bottom-Right: Configured by default for Master Audio Volume.
                    """
                )
            ),
            GuideArticle(
                id: "02_display_brightness",
                title: isVi ? "2. Độ Sáng Đa Màn Hình" : "2. Display Brightness",
                filename: "02_display_brightness.md",
                content: contentFor(
                    filename: "02_display_brightness.md",
                    fallback: isVi ? """
                    MacStash hỗ trợ điều chỉnh độ sáng độc lập cho từng màn hình, bao gồm màn hình tích hợp trên MacBook và tất cả các màn hình ngoài.

                    Các Phương Thức Điều Khiển:
                    - Dịch Vụ Mặc Định (DisplayServices): Áp dụng cho màn hình Retina tích hợp của Apple.
                    - Điều Khiển Phần Cứng DDC/CI: Dành cho các màn hình ngoài tương thích kết nối qua DisplayPort, HDMI hoặc USB-C.
                    - Giảm Sáng Bằng Phần Mềm (Software Dimming): Tự động sử dụng khi màn hình ngoài không phản hồi DDC/CI.
                    """ : """
                    MacStash provides individual brightness regulation across both MacBook built-in displays and external monitors.

                    Control Methods:
                    - Native Display Services: Used for built-in Apple Retina displays. Communicates directly with macOS DisplayServices.
                    - DDC/CI Hardware Control: For compatible external monitors connected via DisplayPort, HDMI, or USB-C.
                    - Software Dimming: Used as an automatic fallback when external hardware does not support DDC/CI.
                    """
                )
            ),
            GuideArticle(
                id: "03_pomodoro_timer",
                title: isVi ? "3. Đồng Hồ Pomodoro" : "3. Pomodoro Timer",
                filename: "03_pomodoro_timer.md",
                content: contentFor(
                    filename: "03_pomodoro_timer.md",
                    fallback: isVi ? """
                    Bộ máy Pomodoro được tích hợp trực tiếp vào vòng xoay góc màn hình và biểu tượng trên thanh menu bar.

                    Tính Năng Nổi Bật:
                    - Không Bị Đóng Băng Khi Kéo Chuột: Hệ thống tính toán thời gian còn lại dựa trên mốc thời gian kết thúc và đồng hồ đơn điệu.
                    - Duy Trì Trạng Thái Khi Máy Ngủ: Khi máy tính ngủ, thời gian trôi qua vẫn được tính toán chính xác ngay khi màn hình bật trở lại.
                    """ : """
                    The built-in Pomodoro engine integrates into corner dials and the menu bar status item.

                    Key Features:
                    - Monotonic Timing Invariant: Unlike timers that rely on simple countdown increments, MacStash computes remaining duration against target timestamps using system monotonic clocks.
                    - System Sleep and Wake Handling: When your Mac sleeps, elapsed duration is accurately recalculated upon waking.
                    """
                )
            ),
            GuideArticle(
                id: "04_troubleshooting",
                title: isVi ? "4. Xử Lý Sự Cố & Phân Quyền" : "4. Troubleshooting",
                filename: "04_troubleshooting.md",
                content: contentFor(
                    filename: "04_troubleshooting.md",
                    fallback: isVi ? """
                    Thiết Lập Quyền Hệ Thống:
                    - Accessibility (Trợ Năng): Bắt buộc để theo dõi vị trí con trỏ chuột toàn cục và quản lý lớp overlay không kích hoạt cửa sổ.
                    - Input Monitoring (Theo Dõi Đầu Vào): Bắt buộc để nhận diện phím bổ trợ và thao tác cuộn khi tinh chỉnh thông số.
                    - Notifications (Thông Báo): Dùng để gửi thông báo khi đồng hồ Pomodoro hoàn thành.
                    """ : """
                    Permissions Setup:
                    - Accessibility: Required for global cursor position tracking and non-activating overlay management.
                    - Input Monitoring: Required to monitor modifier keys and scroll events while adjusting values.
                    - Notifications: Required to post completion banners for Pomodoro focus intervals.
                    """
                )
            ),
            GuideArticle(
                id: "05_settings",
                title: isVi ? "5. Chi Tiết 7 Tab Settings" : "5. Settings Reference",
                filename: "05_settings.md",
                content: contentFor(
                    filename: "05_settings.md",
                    fallback: isVi ? """
                    MacStash cung cấp cửa sổ thiết lập gồm 7 tab chuẩn theo Apple Human Interface Guidelines:
                    1. General: Công tắc tổng, ngôn ngữ giao diện, quyền hệ thống.
                    2. Hot Corners: Gán hành động 4 góc, độ nhạy, độ trễ và ứng dụng loại trừ.
                    3. Appearance: Bán kính, độ trong suốt, chủ đề và phản hồi xúc giác.
                    4. Displays: Quản lý độ sáng màn hình theo UUID.
                    5. Pomodoro: Thiết lập thời gian tập trung và nghỉ.
                    6. Shortcuts: Phím tắt toàn cục và kiểm tra xung đột.
                    7. About / Advanced: Chẩn đoán, sao lưu cấu hình JSON và đặt lại gốc.
                    """ : """
                    MacStash provides a comprehensive 7-tab configuration window compliant with macOS Human Interface Guidelines.

                    Tab Directory:
                    1. General: Master switch, menu bar icon toggle, language switcher, launch at login, and system permissions dashboard.
                    2. Hot Corners: Per-corner assignments, sensitivity (1-20pt), dwell activation delay, and suppression rules.
                    3. Appearance: Dial radius (110-200pt), glass opacity, theme selection, motion reduction, and haptic feedback.
                    4. Displays: Connected display inventory with UUIDs, method selector (Auto/DDC/Software), and live testing sliders.
                    5. Pomodoro: Interval duration steppers, rounds before long break, auto-start breaks, and completion chime alerts.
                    6. Shortcuts: Global hotkeys for toggling dials and hidden dock, with conflict analysis.
                    7. About / Advanced: Diagnostics, console log shortcuts, JSON settings backup, and factory reset.
                    """
                )
            ),
            GuideArticle(
                id: "06_shortcuts",
                title: isVi ? "6. Bảng Tra Nhanh Phím Tắt" : "6. Shortcuts Quick Reference",
                filename: "06_shortcuts.md",
                content: contentFor(
                    filename: "06_shortcuts.md",
                    fallback: isVi ? """
                    Các Tổ Hợp Phím Mặc Định:
                    - Command+, : Mở cửa sổ Settings
                    - Command+W : Đóng cửa sổ MacStash hiện tại
                    - Command+? : Mở cửa sổ hướng dẫn sử dụng
                    - Option+S  : Bật/Tắt hiển thị vòng quay góc
                    - Option+D  : Mở/Đóng thanh dock ẩn
                    - Command+H : Ẩn ứng dụng
                    - Command+Q : Thoát ứng dụng
                    """ : """
                    Default Key Combinations:
                    - Command+, : Open Settings window
                    - Command+W : Close frontmost window
                    - Command+? : Open User Guide
                    - Option+S  : Toggle corner dials
                    - Option+D  : Toggle hidden dock
                    - Command+H : Hide MacStash application
                    - Command+Q : Quit MacStash and restore display gamma
                    """
                )
            ),
            GuideArticle(
                id: "07_faq",
                title: isVi ? "7. Câu Hỏi Thường Gặp (FAQ)" : "7. Frequently Asked Questions",
                filename: "07_faq.md",
                content: contentFor(
                    filename: "07_faq.md",
                    fallback: isVi ? """
                    Câu Hỏi Thường Gặp:

                    Hỏi: MacStash có gây tốn CPU khi chạy ngầm không?
                    Đáp: Không. Khi các vòng xoay ở trạng thái ẩn, MacStash không tiêu thụ CPU.

                    Hỏi: Tôi có thể bấm các nút nằm ở góc của app khác không?
                    Đáp: Có. Khi vòng xoay đang ẩn, hit-testing luôn trả về nil, cho phép click xuyên qua.
                    """ : """
                    Frequently Asked Questions:

                    Q: Does MacStash consume CPU when idle?
                    A: No. When dials are hidden, MacStash uses zero CPU cycles. It operates without polling timers.

                    Q: Can I click buttons located behind corner dials?
                    A: Yes. When dials are hidden, hit testing returns nil, allowing clicks to pass through to underlying apps.
                    """
                )
            ),
            GuideArticle(
                id: "08_whats_new",
                title: isVi ? "8. Có Gì Mới Trong Phiên Bản 2.0.0" : "8. What's New in Version 2.0.0",
                filename: "08_whats_new.md",
                content: contentFor(
                    filename: "08_whats_new.md",
                    fallback: isVi ? """
                    Những Cải Tiến Nổi Bật:
                    - Nhận diện hình học góc ngoài biên cho hệ thống đa màn hình.
                    - Máy trạng thái formal state machine quản lý hiện/ẩn với bộ đếm generation.
                    - Hỗ trợ Universal Binary cho cả Apple Silicon (arm64) và Intel (x86_64).
                    - Điều khiển độ sáng đa màn hình tích hợp DisplayServices, DDC/CI và giảm sáng bằng phần mềm.
                    - Đồng hồ tập trung Pomodoro theo thời gian đơn điệu.
                    - Cửa sổ Settings chuẩn 7 tab và cẩm nang hướng dẫn sử dụng song ngữ.
                    """ : """
                    What's New in Version 2.0.0:
                    - Multi-monitor outer corner detection avoiding inner display seam conflicts.
                    - Formal state machine overlay lifecycle with generational delay cancellation.
                    - Universal binary distribution supporting both Apple Silicon (arm64) and Intel (x86_64).
                    - Multi-display brightness controller supporting Apple DisplayServices, DDC/CI, and Software Dimming.
                    - Monotonic Pomodoro focus timer surviving window drags and macOS system sleep.
                    - Standard 7-tab Settings preferences window with permissions deep-links and JSON backup.
                    - In-app offline user guide with search filter and first-launch onboarding walkthrough.
                    """
                )
            )
        ]
    }
}
