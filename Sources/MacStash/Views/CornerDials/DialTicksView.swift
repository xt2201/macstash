import SwiftUI

/// Draws delicate laser-etched radial tick marks around the dial arc that illuminate
/// as luminous liquid fills the gauge. Formatted with strict mathematical symmetry across 4 quadrants.
public struct DialTicksView: View {
    public let geometry: RadialDialGeometry
    public let value: Double
    public let accentColor: Color
    public let tickCount: Int = 21

    public init(geometry: RadialDialGeometry, value: Double, accentColor: Color) {
        self.geometry = geometry
        self.value = value
        self.accentColor = accentColor
    }

    public var body: some View {
        Canvas { context, _ in
            for i in 0..<tickCount {
                let frac = Double(i) / Double(tickCount - 1)
                let deg = geometry.angle(for: frac)
                // Exactly 5 major ticks: 0%, 25%, 50%, 75%, 100%
                let isMajor = (i % 5 == 0)
                let isActive = frac <= (value + 0.005)

                let rInner = geometry.outerRadius - (isMajor ? 13 : 8)
                let rOuter = geometry.outerRadius

                let p1 = geometry.point(radius: rInner, angleDegrees: deg)
                let p2 = geometry.point(radius: rOuter, angleDegrees: deg)

                var path = Path()
                path.move(to: p1)
                path.addLine(to: p2)

                if isActive {
                    // Soft glow under-layer
                    context.stroke(
                        path,
                        with: .color(accentColor.opacity(0.38)),
                        lineWidth: isMajor ? 2.6 : 1.6
                    )
                    // Sharp glowing core
                    context.stroke(
                        path,
                        with: .color(accentColor),
                        lineWidth: isMajor ? 1.6 : 1.0
                    )
                } else {
                    // Laser-etched frosted groove on inactive glass surface
                    context.stroke(
                        path,
                        with: .color(Color.white.opacity(isMajor ? 0.28 : 0.10)),
                        lineWidth: isMajor ? 1.4 : 0.9
                    )
                }
            }
        }
    }
}
