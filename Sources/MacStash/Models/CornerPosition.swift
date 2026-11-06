import Foundation
import CoreGraphics

/// Defines the four physical corners of the macOS display
public enum CornerPosition: String, CaseIterable, Identifiable, Codable, Sendable {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .topLeft: return "Top Left"
        case .topRight: return "Top Right"
        case .bottomLeft: return "Bottom Left"
        case .bottomRight: return "Bottom Right"
        }
    }

    /// The angle span in radians for the quarter-circle dial
    /// In SwiftUI Cartesian space (origin at top-left or corner):
    public var startAngleDegrees: Double {
        switch self {
        case .bottomRight: return 180.0
        case .bottomLeft: return 270.0
        case .topLeft: return 0.0
        case .topRight: return 90.0
        }
    }

    public var endAngleDegrees: Double {
        switch self {
        case .bottomRight: return 270.0
        case .bottomLeft: return 360.0
        case .topLeft: return 90.0
        case .topRight: return 180.0
        }
    }
}
