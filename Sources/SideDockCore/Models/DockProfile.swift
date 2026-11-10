import Foundation

public struct DockProfile: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var name: String
    public var items: [DockItem]
    public var layoutConfig: DockLayoutConfig
    public var theme: DockTheme
    public var hotkeyNumber: Int?

    public init(
        id: UUID = UUID(),
        name: String,
        items: [DockItem] = [],
        layoutConfig: DockLayoutConfig = DockLayoutConfig(),
        theme: DockTheme = DockTheme(),
        hotkeyNumber: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.items = items
        self.layoutConfig = layoutConfig
        self.theme = theme
        self.hotkeyNumber = hotkeyNumber
    }

    public static func defaultProfiles() -> [DockProfile] {
        let defaultProfile = DockProfile(
            name: "Default",
            items: [
                .widget(WidgetItem(widgetKind: "clock", size: .small)),
                .widget(WidgetItem(widgetKind: "date", size: .small)),
                .separator(UUID()),
                .app(AppItem(bundleIdentifier: "com.apple.Safari", displayName: "Safari", appPath: "/Applications/Safari.app")),
                .app(AppItem(bundleIdentifier: "com.apple.Terminal", displayName: "Terminal", appPath: "/System/Applications/Utilities/Terminal.app")),
                .separator(UUID()),
                .widget(WidgetItem(widgetKind: "weather", size: .medium)),
                .widget(WidgetItem(widgetKind: "nowPlaying", size: .medium)),
                .widget(WidgetItem(widgetKind: "systemStats", size: .medium))
            ],
            layoutConfig: DockLayoutConfig(placement: .fixedBottom),
            hotkeyNumber: 1
        )

        let workProfile = DockProfile(
            name: "Work",
            items: [
                .widget(WidgetItem(widgetKind: "calendar", size: .medium)),
                .widget(WidgetItem(widgetKind: "reminders", size: .medium)),
                .separator(UUID()),
                .widget(WidgetItem(widgetKind: "pomodoro", size: .small)),
                .widget(WidgetItem(widgetKind: "search", size: .medium)),
                .widget(WidgetItem(widgetKind: "fileShelf", size: .small))
            ],
            layoutConfig: DockLayoutConfig(placement: .fixedBottom),
            hotkeyNumber: 2
        )

        let focusProfile = DockProfile(
            name: "Focus",
            items: [
                .widget(WidgetItem(widgetKind: "pomodoro", size: .medium)),
                .widget(WidgetItem(widgetKind: "nowPlaying", size: .medium))
            ],
            layoutConfig: DockLayoutConfig(placement: .floating, floatingX: 300, floatingY: 200),
            hotkeyNumber: 3
        )

        return [defaultProfile, workProfile, focusProfile]
    }
}
