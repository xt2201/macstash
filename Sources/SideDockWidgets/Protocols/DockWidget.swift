import SwiftUI
import SideDockCore

public enum WidgetCategory: String, Codable, Sendable, CaseIterable {
    case general = "General"
    case productivity = "Productivity"
    case system = "System & Hardware"
    case media = "Media & Audio"
    case utility = "Utility & Tools"
}

public enum WidgetPermission: String, Codable, Sendable, CaseIterable {
    case none
    case calendar
    case reminders
    case appleEvents
    case location
    case notifications
}

public enum WidgetVisibilityRule: String, Codable, Sendable {
    case isPlayingMusic
    case hasCalendarEventsToday
    case hasDueReminders
    case isBatteryLow
    case isCpuHigh
}

public enum WidgetVisibility: Equatable, Sendable {
    case always
    case conditional(WidgetVisibilityRule)
}

public struct WidgetDescriptor: Identifiable, Sendable {
    public let id: String
    public let displayName: String
    public let category: WidgetCategory
    public let systemIconName: String
    public let description: String
    public let supportedSizes: [WidgetSize]
    public let requiredPermissions: [WidgetPermission]
    public let networkDomains: [String]
    public let privacyNote: String

    public init(
        id: String,
        displayName: String,
        category: WidgetCategory,
        systemIconName: String,
        description: String,
        supportedSizes: [WidgetSize] = [.small, .medium, .large],
        requiredPermissions: [WidgetPermission] = [.none],
        networkDomains: [String] = [],
        privacyNote: String = "All data processed locally on device."
    ) {
        self.id = id
        self.displayName = displayName
        self.category = category
        self.systemIconName = systemIconName
        self.description = description
        self.supportedSizes = supportedSizes
        self.requiredPermissions = requiredPermissions
        self.networkDomains = networkDomains
        self.privacyNote = privacyNote
    }
}

public protocol DockWidget: Identifiable {
    static var descriptor: WidgetDescriptor { get }
    associatedtype Config: Codable & Equatable
    associatedtype BodyView: View

    init(config: Config)

    @MainActor func start() async
    @MainActor func stop()

    @ViewBuilder @MainActor var body: BodyView { get }
    var visibility: WidgetVisibility { get }
}
