import Foundation

public enum EdgePosition: String, CaseIterable, Identifiable, Codable, Sendable {
    case left
    case right
    case top
    case bottom

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .left: return "Left Edge"
        case .right: return "Right Edge"
        case .top: return "Top Edge"
        case .bottom: return "Bottom Edge"
        }
    }
}
