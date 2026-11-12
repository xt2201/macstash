import Foundation

public struct ProfileTriggerRule: Codable, Equatable, Sendable {
    public var isEnabled: Bool
    public var activeAppBundleIDs: [String]
    public var requiredDisplayCount: Int?

    public init(
        isEnabled: Bool = false,
        activeAppBundleIDs: [String] = [],
        requiredDisplayCount: Int? = nil
    ) {
        self.isEnabled = isEnabled
        self.activeAppBundleIDs = activeAppBundleIDs
        self.requiredDisplayCount = requiredDisplayCount
    }
}

public struct LaunchpadFolderGroup: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public var title: String
    public var appBundleIDs: [String]

    public init(id: UUID = UUID(), title: String, appBundleIDs: [String]) {
        self.id = id
        self.title = title
        self.appBundleIDs = appBundleIDs
    }
}

public struct LaunchpadLayoutConfig: Codable, Equatable, Sendable {
    public var columns: Int
    public var rows: Int
    public var iconSize: Double
    public var hiddenBundleIDs: [String]
    public var customOrderBundleIDs: [String]
    public var folders: [LaunchpadFolderGroup]

    public init(
        columns: Int = 7,
        rows: Int = 5,
        iconSize: Double = 72.0,
        hiddenBundleIDs: [String] = [],
        customOrderBundleIDs: [String] = [],
        folders: [LaunchpadFolderGroup] = []
    ) {
        self.columns = max(4, min(10, columns))
        self.rows = max(3, min(8, rows))
        self.iconSize = max(48.0, min(104.0, iconSize))
        self.hiddenBundleIDs = hiddenBundleIDs
        self.customOrderBundleIDs = customOrderBundleIDs
        self.folders = folders
    }
}

public struct DockProfile: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var name: String
    public var items: [DockItem]
    public var layoutConfig: DockLayoutConfig
    public var theme: DockTheme
    public var hotkeyNumber: Int?
    public var triggerRule: ProfileTriggerRule

    public init(
        id: UUID = UUID(),
        name: String,
        items: [DockItem] = [],
        layoutConfig: DockLayoutConfig = DockLayoutConfig(),
        theme: DockTheme = DockTheme(),
        hotkeyNumber: Int? = nil,
        triggerRule: ProfileTriggerRule = ProfileTriggerRule()
    ) {
        self.id = id
        self.name = name
        self.items = items
        self.layoutConfig = layoutConfig
        self.theme = theme
        self.hotkeyNumber = hotkeyNumber
        self.triggerRule = triggerRule
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, items, layoutConfig, theme, hotkeyNumber, triggerRule
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID(),
            name: try c.decode(String.self, forKey: .name),
            items: try c.decodeIfPresent([DockItem].self, forKey: .items) ?? [],
            layoutConfig: try c.decodeIfPresent(DockLayoutConfig.self, forKey: .layoutConfig) ?? DockLayoutConfig(),
            theme: try c.decodeIfPresent(DockTheme.self, forKey: .theme) ?? DockTheme(),
            hotkeyNumber: try c.decodeIfPresent(Int.self, forKey: .hotkeyNumber),
            triggerRule: try c.decodeIfPresent(ProfileTriggerRule.self, forKey: .triggerRule) ?? ProfileTriggerRule()
        )
    }

    public static func defaultProfiles() -> [DockProfile] {
        let defaultProfile = DockProfile(
            name: "Default",
            items: [
                .launchpad(UUID()),
                .separator(UUID()),
                .widget(WidgetItem(widgetKind: "clock", size: .small)),
                .widget(WidgetItem(widgetKind: "date", size: .small)),
                .separator(UUID()),
                .app(AppItem(bundleIdentifier: "com.apple.Safari", displayName: "Safari", appPath: "/Applications/Safari.app")),
                .app(AppItem(bundleIdentifier: "com.apple.Terminal", displayName: "Terminal", appPath: "/System/Applications/Utilities/Terminal.app")),
                .separator(UUID()),
                .smartStack(SmartStackItem(
                    title: "Daily Stack",
                    widgets: [
                        WidgetItem(widgetKind: "weather", size: .medium),
                        WidgetItem(widgetKind: "nowPlaying", size: .medium),
                        WidgetItem(widgetKind: "systemStats", size: .medium)
                    ],
                    size: .medium
                )),
                .separator(UUID()),
                .trash(UUID())
            ],
            layoutConfig: DockLayoutConfig(placement: .fixedBottom),
            hotkeyNumber: 1
        )

        let workProfile = DockProfile(
            name: "Work",
            items: [
                .launchpad(UUID()),
                .widget(WidgetItem(widgetKind: "calendar", size: .medium)),
                .widget(WidgetItem(widgetKind: "reminders", size: .medium)),
                .separator(UUID()),
                .widget(WidgetItem(widgetKind: "pomodoro", size: .small)),
                .widget(WidgetItem(widgetKind: "search", size: .medium)),
                .widget(WidgetItem(widgetKind: "fileShelf", size: .small)),
                .trash(UUID())
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
