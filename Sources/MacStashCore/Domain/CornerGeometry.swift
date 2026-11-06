import Foundation
import CoreGraphics

public enum CornerGeometry {
    @inline(__always)
    public static func rectContains(_ rect: CGRect, _ point: CGPoint) -> Bool {
        point.x >= rect.minX && point.x <= rect.maxX &&
        point.y >= rect.minY && point.y <= rect.maxY
    }

    /// Determines whether a point inside a candidate screen's corner represents an outer corner
    /// of the multi-display desktop arrangement. If moving across the corner boundary leads
    /// into an adjacent connected monitor, the corner is an internal junction and returns false.
    public static func isOuterCorner(
        point: CGPoint,
        corner: CornerPosition,
        screen: CGRect,
        allScreens: [CGRect],
        hitZoneSizePoints: CGFloat = Defaults.HotCorner.defaultHitZoneSizePoints,
        tolerancePoints: CGFloat = 2.0
    ) -> Bool {
        if allScreens.count <= 1 {
            return true
        }

        let hitZone = HitZone(corner: corner, screenFrame: screen, sizePoints: hitZoneSizePoints)
        guard hitZone.contains(point: point) else {
            return false
        }

        let vertex = hitZone.vertex

        // Direction vector stepping outward from vertex
        let dx: CGFloat
        let dy: CGFloat

        switch corner {
        case .topLeft:
            dx = -1.0
            dy = 1.0
        case .topRight:
            dx = 1.0
            dy = 1.0
        case .bottomLeft:
            dx = -1.0
            dy = -1.0
        case .bottomRight:
            dx = 1.0
            dy = -1.0
        }

        let margin = max(1.0, hitZoneSizePoints / 2.0)
        let step = max(1.0, tolerancePoints)

        // Probe 1: Stepping horizontally outside the corner while remaining along screen's vertical span
        let horizontalProbe = CGPoint(x: vertex.x + dx * step, y: vertex.y - dy * margin)

        // Probe 2: Stepping vertically outside the corner while remaining along screen's horizontal span
        let verticalProbe = CGPoint(x: vertex.x - dx * margin, y: vertex.y + dy * step)

        // Probe 3: Stepping diagonally outside the corner
        let diagonalProbe = CGPoint(x: vertex.x + dx * step, y: vertex.y + dy * step)

        // If any probe lands inside another screen rectangle, this corner is adjacent to that screen
        for other in allScreens where other != screen {
            if rectContains(other, horizontalProbe) {
                return false
            }
            if rectContains(other, verticalProbe) {
                return false
            }
            if rectContains(other, diagonalProbe) {
                return false
            }
            // Vertex strictly inside another screen (overlapping monitors)
            if other.insetBy(dx: 0.5, dy: 0.5).contains(vertex) {
                return false
            }
        }

        return true
    }

    public static func isOuterCorner(
        corner: CornerPosition,
        of screen: CGRect,
        in allScreens: [CGRect],
        hitZoneSizePoints: CGFloat = Defaults.HotCorner.defaultHitZoneSizePoints,
        tolerancePoints: CGFloat = 2.0
    ) -> Bool {
        let hitZone = HitZone(corner: corner, screenFrame: screen, sizePoints: hitZoneSizePoints)
        return isOuterCorner(
            point: hitZone.vertex,
            corner: corner,
            screen: screen,
            allScreens: allScreens,
            hitZoneSizePoints: hitZoneSizePoints,
            tolerancePoints: tolerancePoints
        )
    }

    /// Helper to find candidate corner on a screen if point is within hit zone
    public static func candidateCorner(
        for point: CGPoint,
        on screen: CGRect,
        hitZoneSizePoints: CGFloat = Defaults.HotCorner.defaultHitZoneSizePoints
    ) -> CornerPosition? {
        for corner in CornerPosition.allCases {
            let zone = HitZone(corner: corner, screenFrame: screen, sizePoints: hitZoneSizePoints)
            if zone.contains(point: point) {
                return corner
            }
        }
        return nil
    }

    /// Determines whether a screen's right edge is an outer physical edge (not adjacent to another connected monitor).
    public static func isOuterRightEdge(
        screen: CGRect,
        in allScreens: [CGRect],
        tolerancePoints: CGFloat = 2.0
    ) -> Bool {
        if allScreens.count <= 1 {
            return true
        }

        let midY = screen.midY
        let step = max(1.0, tolerancePoints)
        let probe = CGPoint(x: screen.maxX + step, y: midY)

        for other in allScreens where other != screen {
            if rectContains(other, probe) {
                return false
            }
        }
        return true
    }

    /// Determines whether a screen's left edge is an outer physical edge (not adjacent to another connected monitor).
    public static func isOuterLeftEdge(
        screen: CGRect,
        in allScreens: [CGRect],
        tolerancePoints: CGFloat = 2.0
    ) -> Bool {
        if allScreens.count <= 1 {
            return true
        }

        let midY = screen.midY
        let step = max(1.0, tolerancePoints)
        let probe = CGPoint(x: screen.minX - step, y: midY)

        for other in allScreens where other != screen {
            if rectContains(other, probe) {
                return false
            }
        }
        return true
    }
}
