import Foundation
import MacStashCore

public struct AppProfile: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var name: String
    public var bundleIdentifier: String?
    public var cornerActions: [CornerPosition: ControlAction]
    public var leftEdgeAction: ControlAction
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
        leftEdgeAction: ControlAction = .brightness,
        rightEdgeAction: ControlAction = .volume,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.cornerActions = cornerActions
        self.leftEdgeAction = leftEdgeAction
        self.rightEdgeAction = rightEdgeAction
        self.isEnabled = isEnabled
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, bundleIdentifier, cornerActions, leftEdgeAction, rightEdgeAction, isEnabled
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.name = try container.decode(String.self, forKey: .name)
        self.bundleIdentifier = try container.decodeIfPresent(String.self, forKey: .bundleIdentifier)
        self.cornerActions = try container.decodeIfPresent([CornerPosition: ControlAction].self, forKey: .cornerActions) ?? [:]
        self.leftEdgeAction = try container.decodeIfPresent(ControlAction.self, forKey: .leftEdgeAction) ?? .brightness
        self.rightEdgeAction = try container.decodeIfPresent(ControlAction.self, forKey: .rightEdgeAction) ?? .volume
        self.isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? true
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
            leftEdgeAction: .brightness,
            rightEdgeAction: .volume,
            isEnabled: true
        )
    }
}
