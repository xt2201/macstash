import SwiftUI

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
            // 180° (left) to 270° (up)
            return 180.0 + (clamped * 90.0)
        case .bottomLeft:
            // 270° (up) to 360° (right)
            return 270.0 + (clamped * 90.0)
        case .topRight:
            // 180° (left) to 90° (down)
            return 180.0 - (clamped * 90.0)
        case .topLeft:
            // 90° (down) to 0° (right)
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
            // Range 270° to 360°
            if deg < 225 { return 0.0 }
            if deg < 270 { return 0.0 }
            return Double((deg - 270.0) / 90.0)
        case .topRight:
            // Range 180° down to 90°
            if deg < 45 { return 1.0 }
            if deg > 225 { return 0.0 }
            return Double((180.0 - deg) / 90.0)
        case .topLeft:
            // Range 90° down to 0°
            if deg > 135 { return 0.0 }
            if deg > 90 { return 0.0 }
            return Double((90.0 - deg) / 90.0)
        }
    }
}
