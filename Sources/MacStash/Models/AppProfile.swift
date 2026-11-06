import Foundation
import MacStashCore

public struct AppProfile: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var name: String
    public var bundleIdentifier: String?
    public var cornerActions: [CornerPosition: ControlAction]
    public var rightEdgeAction: ControlAction
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
        isEnabled: Bool = true
    ) {
        self.id = id
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.cornerActions = cornerActions
        self.rightEdgeAction = rightEdgeAction
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
            isEnabled: true
        )
    }
}
