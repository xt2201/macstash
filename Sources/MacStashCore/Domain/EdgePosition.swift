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

    public func localizedDisplayName(using language: String) -> String {
        let isVi = language == "vi"
        switch self {
        case .left: return isVi ? "Cạnh trái" : "Left Edge"
        case .right: return isVi ? "Cạnh phải" : "Right Edge"
        case .top: return isVi ? "Cạnh trên" : "Top Edge"
        case .bottom: return isVi ? "Cạnh dưới" : "Bottom Edge"
        }
    }
}
