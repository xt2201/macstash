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

    public init(
        id: UUID = UUID(),
        bundleIdentifier: String,
        displayName: String,
        appPath: String,
        customIconPath: String? = nil
    ) {
        self.id = id
        self.bundleIdentifier = bundleIdentifier
        self.displayName = displayName
        self.appPath = appPath
        self.customIconPath = customIconPath
    }
}

public struct FolderItem: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public var folderPath: String
    public var displayName: String
    public var clickAction: FolderClickAction
    public var sortOrder: FolderSortOrder
    public var tintColorHex: String?

    public init(
        id: UUID = UUID(),
        folderPath: String,
        displayName: String,
        clickAction: FolderClickAction = .openPopover,
        sortOrder: FolderSortOrder = .name,
        tintColorHex: String? = nil
    ) {
        self.id = id
        self.folderPath = folderPath
        self.displayName = displayName
        self.clickAction = clickAction
        self.sortOrder = sortOrder
        self.tintColorHex = tintColorHex
    }
}

public enum WidgetSize: String, Codable, Sendable, CaseIterable {
    case small
    case medium
    case large

    public var defaultWidth: CGFloat {
        switch self {
        case .small: return 56.0
        case .medium: return 120.0
        case .large: return 200.0
        }
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

public enum DockItem: Codable, Identifiable, Equatable, Sendable {
    case app(AppItem)
    case folder(FolderItem)
    case widget(WidgetItem)
    case separator(UUID)
    case spacer(UUID, CGFloat)

    public var id: UUID {
        switch self {
        case .app(let item): return item.id
        case .folder(let item): return item.id
        case .widget(let item): return item.id
        case .separator(let id): return id
        case .spacer(let id, _): return id
        }
    }

    public var isInteractive: Bool {
        switch self {
        case .app, .folder, .widget: return true
        case .separator, .spacer: return false
        }
    }

    public var displayName: String {
        switch self {
        case .app(let item): return item.displayName
        case .folder(let item): return item.displayName
        case .widget(let item): return item.customTitle ?? item.widgetKind.capitalized
        case .separator: return "Separator"
        case .spacer: return "Spacer"
        }
    }

    public var systemIconName: String {
        switch self {
        case .app: return "app.fill"
        case .folder: return "folder.fill"
        case .widget: return "square.grid.2x2.fill"
        case .separator: return "line.diagonal"
        case .spacer: return "space"
        }
    }
}
