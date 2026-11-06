import SwiftUI

/// Draws delicate radial tick marks around the dial arc
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

                let rInner = geometry.outerRadius - (isMajor ? 16 : 9)
                let rOuter = geometry.outerRadius

                let p1 = geometry.point(radius: rInner, angleDegrees: deg)
                let p2 = geometry.point(radius: rOuter, angleDegrees: deg)

                var path = Path()
                path.move(to: p1)
                path.addLine(to: p2)

                let color = isActive ? accentColor : Color.white.opacity(isMajor ? 0.35 : 0.15)
                let lineWidth: CGFloat = isMajor ? 2.0 : 1.2

                context.stroke(
                    path,
                    with: .color(color),
                    lineWidth: lineWidth
                )
            }
        }
    }
}
