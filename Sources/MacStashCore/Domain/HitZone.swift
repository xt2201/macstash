import Foundation
import CoreGraphics

public struct HitZone: Equatable, Sendable {
    public let corner: CornerPosition
    public let screenFrame: CGRect
    public let sizePoints: CGFloat

    public init(corner: CornerPosition, screenFrame: CGRect, sizePoints: CGFloat = Defaults.HotCorner.defaultHitZoneSizePoints) {
        self.corner = corner
        self.screenFrame = screenFrame
        self.sizePoints = max(Defaults.HotCorner.minHitZoneSizePoints, min(Defaults.HotCorner.maxHitZoneSizePoints, sizePoints))
    }

    public var vertex: CGPoint {
        switch corner {
        case .bottomLeft:
            return CGPoint(x: screenFrame.minX, y: screenFrame.minY)
        case .bottomRight:
            return CGPoint(x: screenFrame.maxX, y: screenFrame.minY)
        case .topLeft:
            return CGPoint(x: screenFrame.minX, y: screenFrame.maxY)
        case .topRight:
            return CGPoint(x: screenFrame.maxX, y: screenFrame.maxY)
        }
    }

    public var boundingBox: CGRect {
        switch corner {
        case .bottomLeft:
            return CGRect(x: screenFrame.minX, y: screenFrame.minY, width: sizePoints, height: sizePoints)
        case .bottomRight:
            return CGRect(x: screenFrame.maxX - sizePoints, y: screenFrame.minY, width: sizePoints, height: sizePoints)
        case .topLeft:
            return CGRect(x: screenFrame.minX, y: screenFrame.maxY - sizePoints, width: sizePoints, height: sizePoints)
        case .topRight:
            return CGRect(x: screenFrame.maxX - sizePoints, y: screenFrame.maxY - sizePoints, width: sizePoints, height: sizePoints)
        }
    }

    public func contains(point: CGPoint) -> Bool {
        boundingBox.contains(point)
    }

    public func distanceFromVertex(to point: CGPoint) -> CGFloat {
        let v = vertex
        return hypot(point.x - v.x, point.y - v.y)
    }
}
