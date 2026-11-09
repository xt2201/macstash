import Foundation
import CoreGraphics

public struct DockLayoutEngine: Sendable {
    public init() {}

    /// Calculates the origin and dimensions for the dock window based on layout preferences and screen geometries.
    public func calculateWindowFrame(
        screenFrame: CGRect,
        visibleFrame: CGRect,
        contentSize: CGSize,
        config: DockLayoutConfig
    ) -> CGRect {
        let scaledWidth = contentSize.width * config.scale
        let scaledHeight = contentSize.height * config.scale

        // Constrain width to visible frame width if autoFitScreen is enabled
        let effectiveWidth: CGFloat
        if config.autoFitScreen {
            let maxAllowed = min(scaledWidth, max(200.0, visibleFrame.width - 32.0))
            if let customMax = config.maxDockWidth {
                effectiveWidth = min(maxAllowed, CGFloat(customMax))
            } else {
                effectiveWidth = maxAllowed
            }
        } else {
            effectiveWidth = scaledWidth
        }

        let effectiveHeight = scaledHeight

        switch config.placement {
        case .floating:
            // Clamp floating position so the dock stays within visible screen bounds
            let minX = visibleFrame.minX
            let maxX = max(minX, visibleFrame.maxX - effectiveWidth)
            let clampedX = max(minX, min(maxX, CGFloat(config.floatingX)))

            let minY = visibleFrame.minY
            let maxY = max(minY, visibleFrame.maxY - effectiveHeight)
            let clampedY = max(minY, min(maxY, CGFloat(config.floatingY)))

            return CGRect(x: clampedX, y: clampedY, width: effectiveWidth, height: effectiveHeight)

        case .fixedBottom:
            // Positioned right above the native macOS Dock
            // visibleFrame.minY accounts for the native Dock if placed at the bottom.
            let x = visibleFrame.midX - (effectiveWidth / 2.0)
            let y = visibleFrame.minY + CGFloat(config.bottomOffset)
            return CGRect(x: x, y: y, width: effectiveWidth, height: effectiveHeight)

        case .fixedTop:
            let x = visibleFrame.midX - (effectiveWidth / 2.0)
            let y = visibleFrame.maxY - effectiveHeight - CGFloat(config.bottomOffset)
            return CGRect(x: x, y: y, width: effectiveWidth, height: effectiveHeight)

        case .fixedLeft:
            let x = visibleFrame.minX + CGFloat(config.bottomOffset)
            let y = visibleFrame.midY - (effectiveHeight / 2.0)
            return CGRect(x: x, y: y, width: effectiveWidth, height: effectiveHeight)

        case .fixedRight:
            let x = visibleFrame.maxX - effectiveWidth - CGFloat(config.bottomOffset)
            let y = visibleFrame.midY - (effectiveHeight / 2.0)
            return CGRect(x: x, y: y, width: effectiveWidth, height: effectiveHeight)
        }
    }

    /// Determines whether the mouse location is within the auto-hide edge trigger activation zone.
    public func isInsideEdgeTrigger(
        cursorLocation: CGPoint,
        screenFrame: CGRect,
        placement: DockPlacement,
        triggerThickness: Double
    ) -> Bool {
        let thickness = CGFloat(max(2.0, min(30.0, triggerThickness)))

        switch placement {
        case .fixedBottom, .floating:
            return cursorLocation.y <= screenFrame.minY + thickness
        case .fixedTop:
            return cursorLocation.y >= screenFrame.maxY - thickness
        case .fixedLeft:
            return cursorLocation.x <= screenFrame.minX + thickness
        case .fixedRight:
            return cursorLocation.x >= screenFrame.maxX - thickness
        }
    }

    /// Calculates safe clamped coordinates for drag-to-move floating dock.
    public func clampFloatingCoordinates(
        proposedPoint: CGPoint,
        dockSize: CGSize,
        screenBounds: CGRect
    ) -> CGPoint {
        let minX = screenBounds.minX
        let maxX = max(minX, screenBounds.maxX - dockSize.width)
        let clampedX = max(minX, min(maxX, proposedPoint.x))

        let minY = screenBounds.minY
        let maxY = max(minY, screenBounds.maxY - dockSize.height)
        let clampedY = max(minY, min(maxY, proposedPoint.y))

        return CGPoint(x: clampedX, y: clampedY)
    }
}
