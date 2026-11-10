import Foundation

public enum HotCornerDisplayTarget: String, CaseIterable, Identifiable, Codable, Sendable {
    case builtIn
    case external
    case all

    public var id: String { rawValue }

    public func localizedDisplayName(using language: String) -> String {
        switch self {
        case .builtIn:
            return language == "vi" ? "Màn hình máy Mac (Mặc định)" : "Built-in Mac Screen (Default)"
        case .external:
            return language == "vi" ? "Màn hình ngoài" : "External Displays"
        case .all:
            return language == "vi" ? "Cả hai (Tất cả màn hình)" : "Both (All Displays)"
        }
    }
}
