import Foundation
import CoreGraphics

/// Computes smooth macOS-style cosine parabolic magnification across dock tiles.
public struct DockMagnificationEngine: Sendable {
    public init() {}

    /// Returns the scale factor (`1.0 ... maxMagnification`) for a tile centered at `tileCenter`.
    public func scaleFactor(
        tileCenter: CGFloat,
        cursorAxisPosition: CGFloat?,
        baseTileSize: CGFloat,
        maxMagnification: Double,
        influenceRadiusTiles: Double = 2.4
    ) -> CGFloat {
        guard let cursor = cursorAxisPosition,
              maxMagnification > 1.001,
              baseTileSize > 0 else {
            return 1.0
        }

        let maxRadius = max(baseTileSize, baseTileSize * CGFloat(influenceRadiusTiles))
        let distance = abs(cursor - tileCenter)
        guard distance < maxRadius else {
            return 1.0
        }

        let normalized = distance / maxRadius
        // Smooth raised-cosine curve: 1.0 at center, 0.0 at maxRadius with zero slope at boundaries
        let weight = 0.5 * (1.0 + cos(.pi * normalized))
        let delta = CGFloat(maxMagnification - 1.0) * weight
        return 1.0 + delta
    }

    /// Computes vertical lift offset (in points) for magnified icons anchored along an edge.
    public func liftOffset(scale: CGFloat, baseTileSize: CGFloat) -> CGFloat {
        guard scale > 1.0 else { return 0 }
        return (scale - 1.0) * baseTileSize * 0.42
    }
}
