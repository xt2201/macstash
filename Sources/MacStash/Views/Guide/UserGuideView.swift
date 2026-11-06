import SwiftUI
import AppKit

public struct GuideArticle: Identifiable, Equatable {
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
    @State private var selectedArticleID: String = "01_getting_started"
    @State private var searchQuery: String = ""
    @State private var articles: [GuideArticle] = []

    public init() {
        _articles = State(initialValue: Self.loadArticles(language: "en"))
    }

    public var body: some View {
        NavigationSplitView {
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search Guide...", text: $searchQuery)
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
                Text("Select an article from the sidebar.")
                    .foregroundColor(.secondary)
            }
        }
        .frame(minWidth: 680, minHeight: 480)
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
        return [
            GuideArticle(
                id: "01_getting_started",
                title: isVi ? "1. Huong Dan Bat Dau" : "1. Getting Started",
                filename: "01_getting_started.md",
                content: """
                MacStash provides tactile, quarter-circle radial dial controls that appear seamlessly at the extreme corners of your macOS displays.

                Core Concepts:
                MacStash is designed to remain completely invisible and zero-resource until you need it. By resting your mouse cursor at an active corner, the corresponding dial emerges smoothly.

                The Four Physical Corners:
                - Top-Left: Configured by default for Keyboard Backlight adjustment.
                - Top-Right: Configured by default for Display Brightness control.
                - Bottom-Left: Configured by default for Pomodoro and Focus Timer.
                - Bottom-Right: Configured by default for Master Audio Volume.

                Outer Corners vs Inner Display Junctions:
                On multi-monitor setups, MacStash utilizes geometric outer corner detection. Dials will only trigger at true desktop perimeter boundaries. When your cursor transitions across adjacent displays along an interior border, MacStash will not interrupt cursor movement.
                """
            ),
            GuideArticle(
                id: "02_display_brightness",
                title: isVi ? "2. Do Sang Da Man Hinh" : "2. Display Brightness",
                filename: "02_display_brightness.md",
                content: """
                MacStash provides individual brightness regulation across both MacBook built-in displays and external monitors.

                Control Methods:
                - Native Display Services: Used for built-in Apple Retina displays. Communicates directly with macOS DisplayServices.
                - DDC/CI Hardware Control: For compatible external monitors connected via DisplayPort, HDMI, or USB-C. Adjusts physical monitor backlight levels via VESA DDC/CI commands on an isolated background queue.
                - Software Dimming: Used as an automatic fallback when external hardware does not support DDC/CI. Employs hardware gamma table manipulation to dim screen output down to 0% smoothly.

                Upon application termination or crash, MacStash automatically restores system color sync tables to original state.
                """
            ),
            GuideArticle(
                id: "03_pomodoro_timer",
                title: isVi ? "3. Dong Ho Pomodoro" : "3. Pomodoro Timer",
                filename: "03_pomodoro_timer.md",
                content: """
                The built-in Pomodoro engine integrates into corner dials and the menu bar status item.

                Key Features:
                - Monotonic Timing Invariant: Unlike timers that rely on simple countdown increments, MacStash computes remaining duration against target timestamps using system monotonic clocks. Dragging dials or moving windows will never freeze or stall the countdown.
                - System Sleep and Wake Handling: When your Mac sleeps, elapsed duration is accurately recalculated upon waking.
                - System Notifications: Optional alerts notify you upon completion of focus sessions and rest intervals.
                """
            ),
            GuideArticle(
                id: "04_troubleshooting",
                title: isVi ? "4. Xu Ly Su Co & Phan Quyen" : "4. Troubleshooting",
                filename: "04_troubleshooting.md",
                content: """
                Permissions Setup:
                - Accessibility: Required for global cursor position tracking and non-activating overlay management. Grant access in macOS System Settings > Privacy & Security > Accessibility.
                - Input Monitoring: Required to monitor modifier keys and scroll events while adjusting values. Grant access in macOS System Settings > Privacy & Security > Input Monitoring.
                - Notifications: Required to post completion banners for Pomodoro focus intervals.

                Accidental Trigger Prevention:
                If corner dials appear too easily or interfere with app controls:
                - Reduce Hit-Zone Sensitivity to 3-5 points in Settings > Hot Corners.
                - Increase Dwell Activation Delay to 200-300 milliseconds.
                - Enable window dragging and full screen suppression.
                - Add specific full-screen or creative software to the Excluded Applications list.
                """
            ),
            GuideArticle(
                id: "05_settings",
                title: isVi ? "5. Chi Tiet 7 Tab Settings" : "5. Settings Reference",
                filename: "05_settings.md",
                content: """
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
            ),
            GuideArticle(
                id: "06_shortcuts",
                title: isVi ? "6. Bang Tra Nhanh Phim Tat" : "6. Shortcuts Quick Reference",
                filename: "06_shortcuts.md",
                content: """
                Default Key Combinations:
                - Command+, : Open Settings window
                - Command+W : Close frontmost window
                - Command+? : Open User Guide
                - Option+S  : Toggle corner dials
                - Option+D  : Toggle hidden dock
                - Command+H : Hide MacStash application
                - Command+Q : Quit MacStash and restore display gamma
                """
            ),
            GuideArticle(
                id: "07_faq",
                title: isVi ? "7. Cau Hoi Thuong Gap (FAQ)" : "7. Frequently Asked Questions",
                filename: "07_faq.md",
                content: """
                Frequently Asked Questions:

                Q: Does MacStash consume CPU when idle?
                A: No. When dials are hidden, MacStash uses zero CPU cycles. It operates without polling timers.

                Q: Can I click buttons located behind corner dials?
                A: Yes. When dials are hidden, hit testing returns nil, allowing clicks to pass through to underlying apps.

                Q: What happens if an external monitor does not support DDC/CI?
                A: MacStash seamlessly falls back to Software Dimming via hardware gamma tables.
                """
            ),
            GuideArticle(
                id: "08_whats_new",
                title: isVi ? "8. Co Gi Moi Trong Phien Ban 2.0.0" : "8. What's New in Version 2.0.0",
                filename: "08_whats_new.md",
                content: """
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
        ]
    }
}
