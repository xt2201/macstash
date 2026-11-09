import SwiftUI

/// Draws delicate laser-etched radial tick marks around the dial arc that illuminate
/// as luminous liquid fills the gauge.
public struct DialTicksView: View {
    public let geometry: RadialDialGeometry
    public let value: Double
    public let accentColor: Color
    public let tickCount: Int = 19

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
                let isMajor = (i % 4 == 0)
                let isActive = frac <= value
                let isAtMeniscus = abs(frac - value) < 0.06

                let rInner = geometry.outerRadius - (isMajor ? 16 : 9)
                let rOuter = geometry.outerRadius

                let p1 = geometry.point(radius: rInner, angleDegrees: deg)
                let p2 = geometry.point(radius: rOuter, angleDegrees: deg)

                var path = Path()
                path.move(to: p1)
                path.addLine(to: p2)

                if isActive {
                    // Luminous illuminated notch with subtle optical bloom
                    if isAtMeniscus {
                        // Specular glisten at the liquid meniscus
                        context.stroke(
                            path,
                            with: .color(Color.white),
                            lineWidth: isMajor ? 2.6 : 1.8
                        )
                    } else {
                        // Soft glow under-layer
                        context.stroke(
                            path,
                            with: .color(accentColor.opacity(0.4)),
                            lineWidth: isMajor ? 3.0 : 2.0
                        )
                        // Sharp glowing core
                        context.stroke(
                            path,
                            with: .color(accentColor),
                            lineWidth: isMajor ? 1.8 : 1.2
                        )
                    }
                } else {
                    // Laser-etched frosted groove on inactive glass surface
                    context.stroke(
                        path,
                        with: .color(Color.white.opacity(isMajor ? 0.32 : 0.12)),
                        lineWidth: isMajor ? 1.6 : 1.0
                    )
                }
            }
        }
    }
}
