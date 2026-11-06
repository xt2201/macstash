import Foundation

public struct AppProfile: Identifiable, Codable, Equatable {
    public var id: UUID
    public var name: String
    public var bundleIdentifier: String? // nil for default profile
    public var cornerActions: [CornerPosition: ControlAction]
    public var rightEdgeAction: ControlAction
    public var dockPosition: EdgePosition
    public var isEnabled: Bool

    public init(
        id: UUID = UUID(),
        name: String,
        bundleIdentifier: String? = nil,
        cornerActions: [CornerPosition: ControlAction] = [
            .bottomRight: .volume,
            .topRight: .brightness,
            .bottomLeft: .timer,
            .topLeft: .keyboardBrightness
        ],
        rightEdgeAction: ControlAction = .brightness,
        dockPosition: EdgePosition = .left,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.cornerActions = cornerActions
        self.rightEdgeAction = rightEdgeAction
        self.dockPosition = dockPosition
        self.isEnabled = isEnabled
    }

    public static var defaultProfile: AppProfile {
        AppProfile(
            name: "Default Profile",
            bundleIdentifier: nil,
            cornerActions: [
                .bottomRight: .volume,
                .topRight: .brightness,
                .bottomLeft: .timer,
                .topLeft: .keyboardBrightness
            ],
            rightEdgeAction: .brightness,
            dockPosition: .left,
            isEnabled: true
        )
    }
}
