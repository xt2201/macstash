import SideDockCore
import SideDockWidgets
import SwiftUI

extension WidgetKind {
    nonisolated var stashWidgetKindID: String? {
        switch self {
        case .stashClock: return "clock"
        case .stashPomodoro: return "pomodoro"
        case .stashFileShelf: return "fileShelf"
        case .stashClipboard: return "clipboard"
        case .stashQuickNote: return "quickNote"
        case .stashScreenshot: return "screenshot"
        case .stashColorPicker: return "colorPicker"
        case .stashUnitConverter: return "unitConverter"
        case .stashBookmarks: return "bookmarks"
        default: return nil
        }
    }

    nonisolated var isStashCustomWidget: Bool {
        stashWidgetKindID != nil
    }
}

struct StashWidgetTileContentView: View {
    let widget: WidgetTile
    let cornerRadius: CGFloat
    let renderedSpan: TileSpan
    let isWithinStack: Bool
    let isExpanded: Bool

    @Environment(\.widgetTextScale) private var textScale

    private var widgetSize: WidgetSize {
        if isExpanded {
            return .large
        }
        switch renderedSpan {
        case .one: return .small
        case .two: return .medium
        case .three, .four: return .large
        }
    }

    private var configurationData: Data? {
        guard let encoded = widget.settings["configJSON"]?.stringValue else { return nil }
        return encoded.data(using: .utf8)
    }

    private var item: WidgetItem {
        let kindID = widget.kind.stashWidgetKindID ?? widget.kind.rawValue
        return WidgetItem(
            widgetKind: kindID,
            size: widgetSize,
            customTitle: widget.title,
            configurationData: configurationData
        )
    }

    var body: some View {
        Group {
            if isExpanded {
                ScrollView(.vertical, showsIndicators: false) {
                    WidgetRegistry.shared.makeExpandedView(for: item)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .padding(14)
                }
            } else {
                WidgetRegistry.shared.makeWidgetView(for: item)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(renderedSpan == .one ? 4 : 6)
            }
        }
        .scaleEffect(isExpanded ? 1.0 : min(1.12, max(0.85, textScale)))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(isWithinStack ? Color.clear : Color.primary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

struct StashWidgetSettingsEditorView: View {
    let tileID: String
    let widget: WidgetTile

    @State private var clockConfig: ClockConfig
    @State private var pomodoroConfig: PomodoroConfig
    @State private var bookmarksConfig: BookmarksConfig
    @State private var newBookmarkTitle: String = ""
    @State private var newBookmarkURL: String = ""

    init(tileID: String, widget: WidgetTile) {
        self.tileID = tileID
        self.widget = widget
        let data = widget.settings["configJSON"]?.stringValue?.data(using: .utf8) ?? Data()
        _clockConfig = State(initialValue: (try? JSONDecoder().decode(ClockConfig.self, from: data)) ?? ClockConfig())
        _pomodoroConfig = State(initialValue: (try? JSONDecoder().decode(PomodoroConfig.self, from: data)) ?? PomodoroConfig())
        _bookmarksConfig = State(initialValue: (try? JSONDecoder().decode(BookmarksConfig.self, from: data)) ?? BookmarksConfig())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            switch widget.kind {
            case .stashClock:
                Picker("Style", selection: $clockConfig.style) {
                    ForEach(ClockStyle.allCases, id: \.self) { style in
                        Text(style.rawValue.capitalized).tag(style)
                    }
                }
                .onChange(of: clockConfig) { _, updated in save(updated) }

                Toggle("24-Hour Clock", isOn: $clockConfig.is24Hour)
                    .onChange(of: clockConfig) { _, updated in save(updated) }

                Toggle("Show Seconds", isOn: $clockConfig.showSeconds)
                    .onChange(of: clockConfig) { _, updated in save(updated) }

                Picker("Timezone", selection: $clockConfig.timeZoneIdentifier) {
                    ForEach(commonTimeZones, id: \.self) { tz in
                        Text(tz.replacingOccurrences(of: "_", with: " ")).tag(tz)
                    }
                }
                .onChange(of: clockConfig) { _, updated in save(updated) }

            case .stashPomodoro:
                Stepper("Focus: \(pomodoroConfig.focusMinutes) min", value: $pomodoroConfig.focusMinutes, in: 5...90, step: 5)
                    .onChange(of: pomodoroConfig) { _, updated in save(updated) }
                Stepper("Break: \(pomodoroConfig.shortBreakMinutes) min", value: $pomodoroConfig.shortBreakMinutes, in: 1...30, step: 1)
                    .onChange(of: pomodoroConfig) { _, updated in save(updated) }

            case .stashBookmarks:
                ForEach(bookmarksConfig.bookmarks) { item in
                    HStack {
                        Image(systemName: item.systemIcon)
                            .foregroundStyle(.secondary)
                        Text(item.title)
                            .font(.subheadline)
                        Spacer()
                        Button(role: .destructive) {
                            bookmarksConfig.bookmarks.removeAll { $0.id == item.id }
                            save(bookmarksConfig)
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                    }
                }

                Divider()

                TextField("Title", text: $newBookmarkTitle)
                    .textFieldStyle(.roundedBorder)
                TextField("URL (https://...)", text: $newBookmarkURL)
                    .textFieldStyle(.roundedBorder)
                Button("Add Bookmark") {
                    let cleanTitle = newBookmarkTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                    var cleanURL = newBookmarkURL.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !cleanTitle.isEmpty, !cleanURL.isEmpty else { return }
                    if !cleanURL.contains("://") {
                        cleanURL = "https://\(cleanURL)"
                    }
                    bookmarksConfig.bookmarks.append(BookmarkItem(title: cleanTitle, urlString: cleanURL, systemIcon: "globe"))
                    save(bookmarksConfig)
                    newBookmarkTitle = ""
                    newBookmarkURL = ""
                }
                .buttonStyle(.bordered)
                .disabled(newBookmarkTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                          newBookmarkURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            default:
                EmptyView()
            }
        }
    }

    private var commonTimeZones: [String] {
        var zones = [
            TimeZone.current.identifier,
            "UTC",
            "America/New_York",
            "America/Los_Angeles",
            "Europe/London",
            "Europe/Berlin",
            "Asia/Tokyo",
            "Asia/Ho_Chi_Minh",
            "Asia/Singapore",
            "Australia/Sydney"
        ]
        var seen = Set<String>()
        zones = zones.filter { seen.insert($0).inserted }
        return zones
    }

    private func save<T: Encodable>(_ value: T) {
        guard let data = try? JSONEncoder().encode(value),
              let str = String(data: data, encoding: .utf8) else {
            return
        }
        TileStore.shared.setWidgetSetting(tileID: tileID, key: "configJSON", value: .string(str))
    }
}
