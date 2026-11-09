import SwiftUI
import MacStashCore

/// Draws quarter-circle radial gauges, tick marks, and arc tracks for corner dials
public struct RadialDialGeometry {
    public let corner: CornerPosition
    public let size: CGSize
    public let outerRadius: CGFloat
    public let innerRadius: CGFloat

    public init(corner: CornerPosition, size: CGSize, outerRadius: CGFloat = 135, innerRadius: CGFloat = 65) {
        self.corner = corner
        self.size = size
        self.outerRadius = outerRadius
        self.innerRadius = innerRadius
    }

    /// Center point (the physical screen corner inside the local view)
    public var center: CGPoint {
        switch corner {
        case .topLeft:
            return CGPoint(x: 0, y: 0)
        case .topRight:
            return CGPoint(x: size.width, y: 0)
        case .bottomLeft:
            return CGPoint(x: 0, y: size.height)
        case .bottomRight:
            return CGPoint(x: size.width, y: size.height)
        }
    }

    /// Angle in degrees for a given normalized value (0.0 ... 1.0)
    public func angle(for value: Double) -> Double {
        let clamped = max(0.0, min(1.0, value))
        switch corner {
        case .bottomRight:
            // 180° (left/bottom edge) rising to 270° (up/right edge)
            return 180.0 + (clamped * 90.0)
        case .bottomLeft:
            // 360° (right/bottom edge) rising to 270° (up/left edge)
            return 360.0 - (clamped * 90.0)
        case .topRight:
            // 90° (down/right edge) rising to 180° (up/top edge)
            return 90.0 + (clamped * 90.0)
        case .topLeft:
            // 90° (down/left edge) rising to 0° (up/top edge)
            return 90.0 - (clamped * 90.0)
        }
    }

    /// Convert polar coordinates (radius, angle in degrees) to Cartesian CGPoint
    public func point(radius: CGFloat, angleDegrees: Double) -> CGPoint {
        let rad = angleDegrees * .pi / 180.0
        let c = center
        return CGPoint(
            x: c.x + radius * cos(CGFloat(rad)),
            y: c.y + radius * sin(CGFloat(rad))
        )
    }

    /// Convert a drag touch point to normalized value 0.0 ... 1.0
    public func value(for touch: CGPoint) -> Double {
        let c = center
        let dx = touch.x - c.x
        let dy = touch.y - c.y
        var deg = atan2(dy, dx) * 180.0 / .pi
        if deg < 0 { deg += 360.0 }

        switch corner {
        case .bottomRight:
            // Range 180° to 270°
            if deg < 135 { return 1.0 }
            if deg > 315 { return 0.0 }
            return Double((deg - 180.0) / 90.0)
        case .bottomLeft:
            // Range 360° down to 270° (0.0 at 360°, 1.0 at 270°)
            if deg < 225 { return 1.0 }
            if deg < 270 { return 1.0 }
            return Double((360.0 - deg) / 90.0)
        case .topRight:
            // Range 90° to 180° (0.0 at 90°, 1.0 at 180°)
            if deg < 45 { return 0.0 }
            if deg > 225 { return 1.0 }
            return Double((deg - 90.0) / 90.0)
        case .topLeft:
            // Range 90° down to 0°
            if deg > 135 { return 0.0 }
            if deg > 90 { return 0.0 }
            return Double((90.0 - deg) / 90.0)
        }
    }
}
