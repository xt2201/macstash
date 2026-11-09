import Foundation
import CoreGraphics

public struct ReserveSpacePolicy: Sendable {
    public init() {}

    /// Adjusts an application window's frame so it stops before the reserved dock zone without overlapping.
    public func adjustWindowFrame(
        windowFrame: CGRect,
        dockFrame: CGRect,
        placement: DockPlacement,
        screenVisibleFrame: CGRect
    ) -> CGRect {
        guard windowFrame.intersects(dockFrame) else { return windowFrame }

        var adjusted = windowFrame

        switch placement {
        case .fixedBottom:
            if adjusted.minY < dockFrame.maxY {
                let overlap = dockFrame.maxY - adjusted.minY
                adjusted.origin.y = dockFrame.maxY
                adjusted.size.height = max(100.0, adjusted.size.height - overlap)
            }

        case .fixedTop:
            if adjusted.maxY > dockFrame.minY {
                let overlap = adjusted.maxY - dockFrame.minY
                adjusted.size.height = max(100.0, adjusted.size.height - overlap)
            }

        case .fixedLeft:
            if adjusted.minX < dockFrame.maxX {
                let overlap = dockFrame.maxX - adjusted.minX
                adjusted.origin.x = dockFrame.maxX
                adjusted.size.width = max(100.0, adjusted.size.width - overlap)
            }

        case .fixedRight:
            if adjusted.maxX > dockFrame.minX {
                let overlap = adjusted.maxX - dockFrame.minX
                adjusted.size.width = max(100.0, adjusted.size.width - overlap)
            }

        case .floating:
            break
        }

        return adjusted
    }
}
