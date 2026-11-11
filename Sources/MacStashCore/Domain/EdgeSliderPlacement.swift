import Foundation

public enum EdgeSliderPlacement: String, CaseIterable, Identifiable, Codable, Sendable {
    case both
    case left
    case right

    public var id: String { rawValue }

    public func localizedDisplayName(using language: String) -> String {
        let isVi = language == "vi"
        switch self {
        case .both: return isVi ? "Cả hai bên (Mặc định)" : "Both Sides (Default)"
        case .left: return isVi ? "Chỉ cạnh trái" : "Left Edge Only"
        case .right: return isVi ? "Chỉ cạnh phải" : "Right Edge Only"
        }
    }
}
