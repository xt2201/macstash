import Foundation

public enum FolderClickAction: String, Codable, Sendable, CaseIterable {
    case openPopover
    case openInFinder
}

public enum FolderSortOrder: String, Codable, Sendable, CaseIterable {
    case name
    case kind
    case size
    case dateModified
}

public struct AppItem: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public var bundleIdentifier: String
    public var displayName: String
    public var appPath: String
    public var customIconPath: String?
    public var widgetFaceKind: String?
    public var showWidgetFace: Bool

    public init(
        id: UUID = UUID(),
        bundleIdentifier: String,
        displayName: String,
        appPath: String,
        customIconPath: String? = nil,
        widgetFaceKind: String? = nil,
        showWidgetFace: Bool = false
    ) {
        self.id = id
        self.bundleIdentifier = bundleIdentifier
        self.displayName = displayName
        self.appPath = appPath
        self.customIconPath = customIconPath
        self.widgetFaceKind = widgetFaceKind
        self.showWidgetFace = showWidgetFace
    }

    private enum CodingKeys: String, CodingKey {
        case id, bundleIdentifier, displayName, appPath, customIconPath, widgetFaceKind, showWidgetFace
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.bundleIdentifier = try c.decode(String.self, forKey: .bundleIdentifier)
        self.displayName = try c.decode(String.self, forKey: .displayName)
        self.appPath = try c.decode(String.self, forKey: .appPath)
        self.customIconPath = try c.decodeIfPresent(String.self, forKey: .customIconPath)
        self.widgetFaceKind = try c.decodeIfPresent(String.self, forKey: .widgetFaceKind)
        self.showWidgetFace = try c.decodeIfPresent(Bool.self, forKey: .showWidgetFace) ?? false
    }
}

public struct FolderItem: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public var folderPath: String
    public var displayName: String
    public var clickAction: FolderClickAction
    public var sortOrder: FolderSortOrder
    public var presentationStyle: FolderPresentationStyle
    public var tintColorHex: String?

    public init(
        id: UUID = UUID(),
        folderPath: String,
        displayName: String,
        clickAction: FolderClickAction = .openPopover,
        sortOrder: FolderSortOrder = .name,
        presentationStyle: FolderPresentationStyle = .popoverGrid,
        tintColorHex: String? = nil
    ) {
        self.id = id
        self.folderPath = folderPath
        self.displayName = displayName
        self.clickAction = clickAction
        self.sortOrder = sortOrder
        self.presentationStyle = presentationStyle
        self.tintColorHex = tintColorHex
    }

    private enum CodingKeys: String, CodingKey {
        case id, folderPath, displayName, clickAction, sortOrder, presentationStyle, tintColorHex
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.folderPath = try c.decode(String.self, forKey: .folderPath)
        self.displayName = try c.decode(String.self, forKey: .displayName)
        self.clickAction = try c.decodeIfPresent(FolderClickAction.self, forKey: .clickAction) ?? .openPopover
        self.sortOrder = try c.decodeIfPresent(FolderSortOrder.self, forKey: .sortOrder) ?? .name
        self.presentationStyle = try c.decodeIfPresent(FolderPresentationStyle.self, forKey: .presentationStyle) ?? .popoverGrid
        self.tintColorHex = try c.decodeIfPresent(String.self, forKey: .tintColorHex)
    }
}

public struct AppFolderItem: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public var displayName: String
    public var apps: [AppItem]
    public var showRunningAppsInline: Bool
    public var customIconPath: String?
    public var tintColorHex: String?

    public init(
        id: UUID = UUID(),
        displayName: String,
        apps: [AppItem] = [],
        showRunningAppsInline: Bool = true,
        customIconPath: String? = nil,
        tintColorHex: String? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.apps = apps
        self.showRunningAppsInline = showRunningAppsInline
        self.customIconPath = customIconPath
        self.tintColorHex = tintColorHex
    }
}

public enum WidgetSize: String, Codable, Sendable, CaseIterable {
    case small
    case medium
    case large

    public var tileSpan: Int {
        switch self {
        case .small: return 1
        case .medium: return 2
        case .large: return 3
        }
    }

    public var defaultWidth: CGFloat {
        switch self {
        case .small: return 56.0
        case .medium: return 120.0
        case .large: return 200.0
        }
    }

    public func width(forBaseTileSize tileSize: Double, spacing: Double) -> CGFloat {
        let span = CGFloat(tileSpan)
        return CGFloat(tileSize) * span + CGFloat(spacing) * max(0, span - 1)
    }
}

public struct WidgetItem: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public var widgetKind: String
    public var size: WidgetSize
    public var customTitle: String?
    public var configurationData: Data?

    public init(
        id: UUID = UUID(),
        widgetKind: String,
        size: WidgetSize = .medium,
        customTitle: String? = nil,
        configurationData: Data? = nil
    ) {
        self.id = id
        self.widgetKind = widgetKind
        self.size = size
        self.customTitle = customTitle
        self.configurationData = configurationData
    }
}

public struct SmartStackItem: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public var title: String
    public var widgets: [WidgetItem]
    public var activeIndex: Int
    public var size: WidgetSize
    public var autoRotateSeconds: Double?

    public init(
        id: UUID = UUID(),
        title: String = "Smart Stack",
        widgets: [WidgetItem] = [],
        activeIndex: Int = 0,
        size: WidgetSize = .medium,
        autoRotateSeconds: Double? = nil
    ) {
        self.id = id
        self.title = title
        self.widgets = widgets
        self.activeIndex = max(0, activeIndex)
        self.size = size
        self.autoRotateSeconds = autoRotateSeconds
    }

    public var activeWidget: WidgetItem? {
        guard !widgets.isEmpty else { return nil }
        let idx = ((activeIndex % widgets.count) + widgets.count) % widgets.count
        return widgets[idx]
    }
}

public enum DockActionKind: String, Codable, Sendable, CaseIterable {
    case systemCommand
    case appleScript
    case shellScript
    case menuClick
    case url
}

public enum BuiltInSystemCommand: String, Codable, Sendable, CaseIterable {
    case lockScreen
    case sleepDisplay
    case missionControl
    case appExpose
    case showDesktop
    case screenshotArea
    case emptyTrash
    case toggleDarkMode
    case openLaunchpad
    case openWindowSwitcher
    case toggleNativeDockAutoHide
}

public struct DockActionItem: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public var displayName: String
    public var kind: DockActionKind
    public var payload: String
    public var targetBundleIdentifier: String?
    public var systemIconName: String
    public var tintHex: String?

    public init(
        id: UUID = UUID(),
        displayName: String,
        kind: DockActionKind,
        payload: String,
        targetBundleIdentifier: String? = nil,
        systemIconName: String = "bolt.fill",
        tintHex: String? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.kind = kind
        self.payload = payload
        self.targetBundleIdentifier = targetBundleIdentifier
        self.systemIconName = systemIconName
        self.tintHex = tintHex
    }
}

public enum DockItem: Codable, Identifiable, Equatable, Sendable {
    case app(AppItem)
    case folder(FolderItem)
    case appFolder(AppFolderItem)
    case widget(WidgetItem)
    case smartStack(SmartStackItem)
    case action(DockActionItem)
    case launchpad(UUID)
    case trash(UUID)
    case separator(UUID)
    case spacer(UUID, CGFloat)

    public var id: UUID {
        switch self {
        case .app(let item): return item.id
        case .folder(let item): return item.id
        case .appFolder(let item): return item.id
        case .widget(let item): return item.id
        case .smartStack(let item): return item.id
        case .action(let item): return item.id
        case .launchpad(let id): return id
        case .trash(let id): return id
        case .separator(let id): return id
        case .spacer(let id, _): return id
        }
    }

    public var isInteractive: Bool {
        switch self {
        case .app, .folder, .appFolder, .widget, .smartStack, .action, .launchpad, .trash:
            return true
        case .separator, .spacer:
            return false
        }
    }

    public var displayName: String {
        switch self {
        case .app(let item): return item.displayName
        case .folder(let item): return item.displayName
        case .appFolder(let item): return item.displayName
        case .widget(let item): return item.customTitle ?? item.widgetKind.capitalized
        case .smartStack(let item): return item.title
        case .action(let item): return item.displayName
        case .launchpad: return "Launchpad"
        case .trash: return "Trash"
        case .separator: return "Separator"
        case .spacer: return "Spacer"
        }
    }

    public var systemIconName: String {
        switch self {
        case .app: return "app.fill"
        case .folder: return "folder.fill"
        case .appFolder: return "folder.badge.gearshape"
        case .widget: return "square.grid.2x2.fill"
        case .smartStack: return "square.stack.3d.up.fill"
        case .action(let item): return item.systemIconName
        case .launchpad: return "square.grid.3x3.fill"
        case .trash: return "trash.fill"
        case .separator: return "line.diagonal"
        case .spacer: return "space"
        }
    }
}
