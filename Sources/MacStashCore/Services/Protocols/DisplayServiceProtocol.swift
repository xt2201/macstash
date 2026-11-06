import Foundation
import CoreGraphics

public struct DisplayInfo: Identifiable, Equatable, Sendable {
    public let id: CGDirectDisplayID
    public let uuid: String
    public let name: String
    public let frame: CGRect
    public let isBuiltIn: Bool

    public init(id: CGDirectDisplayID, uuid: String, name: String, frame: CGRect, isBuiltIn: Bool) {
        self.id = id
        self.uuid = uuid
        self.name = name
        self.frame = frame
        self.isBuiltIn = isBuiltIn
    }
}

public protocol DisplayServiceProtocol: Sendable {
    func activeDisplays() -> [DisplayInfo]
    func display(containing point: CGPoint) -> DisplayInfo?
    func display(id: CGDirectDisplayID) -> DisplayInfo?
}

public protocol BrightnessControlProtocol: Sendable {
    func getBrightness(for display: DisplayInfo) async -> Float
    func setBrightness(_ level: Float, for display: DisplayInfo) async -> Bool
}

public protocol NotificationServiceProtocol: Sendable {
    func requestAuthorization() async -> Bool
    func deliverNotification(title: String, body: String, sound: Bool) async
}
