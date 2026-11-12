import Foundation
import CoreGraphics

/// Pure domain geometry metrics for Corner Radial Dials (100pt - 250pt).
/// Acts as the single source of truth shared by live corner overlays, Appearance settings preview,
/// and automated geometric non-overlap tests.
public struct CornerDialMetrics: Sendable, Equatable {
    public let dialSize: CGFloat

    public init(dialSize: CGFloat) {
        self.dialSize = max(80.0, dialSize)
    }

    // MARK: - Outer Instrument Bezel & Laser Ticks

    public var outerBezelMargin: CGFloat {
        max(5.0, min(8.5, dialSize * 0.04))
    }

    public var tickOuterRadius: CGFloat {
        dialSize - outerBezelMargin
    }

    public var majorTickLength: CGFloat {
        max(7.0, min(11.5, dialSize * 0.056))
    }

    public var minorTickLength: CGFloat {
        majorTickLength * 0.56
    }

    public var tickInnerRadius: CGFloat {
        tickOuterRadius - majorTickLength
    }

    // MARK: - Luminous Liquid Track & Thumb Knob

    public var trackTickGap: CGFloat {
        max(6.5, min(10.5, dialSize * 0.048))
    }

    public var trackRadius: CGFloat {
        tickInnerRadius - trackTickGap
    }

    public var trackStrokeWidth: CGFloat {
        max(6.0, min(9.0, dialSize * 0.046))
    }

    public var trackTrenchWidth: CGFloat {
        trackStrokeWidth + 2.0
    }

    public var trackBloomWidth: CGFloat {
        trackStrokeWidth + 5.5
    }

    public var knobOuterRadius: CGFloat {
        max(6.5, min(8.8, dialSize * 0.045))
    }

    public var knobInnerRadius: CGFloat {
        knobOuterRadius * 0.46
    }

    public var trackInnerBoundary: CGFloat {
        trackRadius - knobOuterRadius - 0.75
    }

    // MARK: - Unclipped Hero Center Action Hub

    /// Minimum floating air gap between the circular hub border and each screen edge.
    public var edgeWallMargin: CGFloat {
        max(5.5, min(15.0, dialSize * 0.062))
    }

    public var badgeDiameter: CGFloat {
        max(36.0, dialSize * 0.375)
    }

    public var badgeRadius: CGFloat {
        badgeDiameter * 0.5
    }

    /// Axial distance from either corner screen wall to the center of the circular hub.
    public var badgeCenterAxisDistance: CGFloat {
        edgeWallMargin + badgeRadius
    }

    /// Scalar horizontal/vertical offset from the square dial center `(dialSize / 2, dialSize / 2)`.
    public var badgeCenterOffsetDistance: CGFloat {
        (dialSize * 0.5) - badgeCenterAxisDistance
    }

    /// Offset delta applied in SwiftUI center-aligned coordinates for the given screen corner.
    public func badgeOffset(for corner: CornerPosition) -> CGPoint {
        let d = badgeCenterOffsetDistance
        switch corner {
        case .topLeft:
            return CGPoint(x: -d, y: -d)
        case .topRight:
            return CGPoint(x: d, y: -d)
        case .bottomLeft:
            return CGPoint(x: -d, y: d)
        case .bottomRight:
            return CGPoint(x: d, y: d)
        }
    }

    /// True Euclidean distance from the physical corner vertex `(0, 0)` along the 45-degree symmetry axis
    /// to the outermost edge of the circular Center Action Hub.
    public var badgeOuterRadius: CGFloat {
        (badgeCenterAxisDistance * sqrt(2.0)) + badgeRadius
    }

    /// Concentric luminous halo framing radius slightly outside the hub boundary.
    public var hubHaloArcRadius: CGFloat {
        badgeOuterRadius + max(3.5, min(6.5, dialSize * 0.032))
    }

    // MARK: - Orbital Channel & Satellite Micro-Controls

    public var satelliteDiameter: CGFloat {
        max(14.0, min(25.0, dialSize * 0.135))
    }

    public var satelliteRadius: CGFloat {
        (badgeOuterRadius + trackInnerBoundary) * 0.5
    }

    /// Proportional typography & symbol scaling relative to default 145pt dial (`badgeDiameter == 54.375pt`).
    public var contentScale: CGFloat {
        max(0.76, min(1.55, badgeDiameter / 54.375))
    }
}
