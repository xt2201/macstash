import Foundation
import CoreGraphics

/// Physical finger movement vector normalized from AppKit `NSEvent` scroll deltas.
/// Positive `x` represents movement/scrolling to the RIGHT; positive `y` represents movement UP.
public struct ScrollVector: Equatable, Sendable {
    public let x: Double
    public let y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    public var totalMotion: Double {
        hypot(x, y)
    }
}

/// Pure domain policy for normalizing macOS trackpad and mouse-wheel scroll vectors.
public enum ScrollInputPolicy {
    /// Normalizes raw `NSEvent` deltas into consistent physical finger/slider axes:
    /// `+y` = up/forward, `-y` = down/backward, `+x` = right/forward, `-x` = left/backward.
    ///
    /// Per AppKit `NSEvent` semantics (`NSEvent.h`), un-inverted deltas use `+1` for up and `+1` for left
    /// (`-1` for right). Enabling macOS Natural Scrolling (`isDirectionInvertedFromDevice == true`)
    /// negates both axes, producing negative `rawDeltaY` for upward swipes and positive `rawDeltaX`
    /// for rightward swipes.
    public static func normalize(
        rawDeltaX: Double,
        rawDeltaY: Double,
        isDirectionInvertedFromDevice: Bool
    ) -> ScrollVector {
        let physicalX = isDirectionInvertedFromDevice ? rawDeltaX : -rawDeltaX
        let physicalY = isDirectionInvertedFromDevice ? -rawDeltaY : rawDeltaY
        return ScrollVector(x: physicalX, y: physicalY)
    }

    /// Selects the dominant gesture axis without double-counting diagonal jitter.
    public static func dominantAxisStep(x: Double, y: Double) -> Double {
        abs(y) >= abs(x) ? y : x
    }
}

/// Target action resolved for a scroll gesture on an active Edge Bar overlay.
public enum EdgeBarScrollTarget: Equatable, Sendable {
    case audioScrub
    case control(ControlAction)
}

/// Pure domain routing policy deciding whether an Edge Bar scroll gesture scrubs media
/// or adjusts a hardware/control slider.
public enum EdgeBarScrollPolicy {
    /// Resolves whether a scroll event should scrub active audio or adjust a control value.
    public static func resolveTarget(
        action: ControlAction,
        isMediaExpanded: Bool,
        isVolumeButtonHovered: Bool,
        isVolumeColumnHovered: Bool,
        isVolumeColumnVisible: Bool,
        isCursorInUpperColumn: Bool,
        isCursorInVolumeButtonRect: Bool = false
    ) -> EdgeBarScrollTarget {
        if isMediaExpanded {
            let isTargetingVolume = isVolumeButtonHovered
                || isCursorInVolumeButtonRect
                || isVolumeColumnHovered
                || (isVolumeColumnVisible && isCursorInUpperColumn)
            return isTargetingVolume ? .control(.volume) : .audioScrub
        }

        if action == .mediaPlayback {
            return .audioScrub
        }
        return .control(action)
    }

    /// Geometric fallback bounds for the outer-edge Volume button inside the expanded
    /// 312x98 Dynamic Island (`EdgeMediaIslandView`) so hover transitions remain deterministic
    /// without waiting an extra SwiftUI layout frame.
    public static func isCursorInIslandVolumeButton(
        localPoint: CGPoint,
        bounds: CGRect,
        edge: EdgePosition,
        isFlipped: Bool,
        bottomInset: CGFloat = 60.0
    ) -> Bool {
        let minX: CGFloat
        let maxX: CGFloat
        switch edge {
        case .right:
            minX = bounds.maxX - 52.0
            maxX = bounds.maxX - 10.0
        case .left:
            minX = bounds.minX + 10.0
            maxX = bounds.minX + 52.0
        case .top, .bottom:
            return false
        }

        let minY = isFlipped ? (bounds.maxY - bottomInset - 42.0) : (bounds.minY + bottomInset + 4.0)
        let maxY = isFlipped ? (bounds.maxY - bottomInset - 4.0) : (bounds.minY + bottomInset + 42.0)

        return localPoint.x >= minX
            && localPoint.x <= maxX
            && localPoint.y >= minY
            && localPoint.y <= maxY
    }
}
