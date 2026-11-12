import SwiftUI
import AppKit
import MacStashCore
import MacStashDesignSystem

public struct DialArcShape: View {
    @Environment(\.colorScheme) private var colorScheme
    public let geometry: RadialDialGeometry
    public let value: Double
    public let gradientColors: [Color]
    public var showOrbitalTrack: Bool

    public init(
        geometry: RadialDialGeometry,
        value: Double,
        gradientColors: [Color],
        showOrbitalTrack: Bool = false
    ) {
        self.geometry = geometry
        self.value = value
        self.gradientColors = gradientColors
        self.showOrbitalTrack = showOrbitalTrack
    }

    public var body: some View {
        let metrics = CornerDialMetrics(dialSize: geometry.size.width)
        let trackRadius = metrics.trackRadius
        let startDeg = geometry.angle(for: 0.0)
        let fullDeg = geometry.angle(for: 1.0)
        let isClockwise = geometry.isClockwise
        let primaryColor = gradientColors.first ?? .accentColor
        let isDark = colorScheme == .dark

        Canvas { context, _ in
            // 0b. Orbital constellation arc when satellites are deployed
            if showOrbitalTrack {
                var orbitPath = Path()
                orbitPath.addArc(
                    center: geometry.center,
                    radius: metrics.satelliteRadius,
                    startAngle: .degrees(startDeg),
                    endAngle: .degrees(fullDeg),
                    clockwise: isClockwise
                )
                context.stroke(
                    orbitPath,
                    with: .color(isDark ? Color.white.opacity(0.09) : Color.black.opacity(0.08)),
                    style: StrokeStyle(lineWidth: 0.8, dash: [3.0, 4.5])
                )
            }

            // 1. Concave glass trench groove (the channel where liquid flows)
            var trenchPath = Path()
            trenchPath.addArc(
                center: geometry.center,
                radius: trackRadius,
                startAngle: .degrees(startDeg),
                endAngle: .degrees(fullDeg),
                clockwise: isClockwise
            )
            context.stroke(
                trenchPath,
                with: .color(isDark ? Color.white.opacity(0.10) : Color.black.opacity(0.10)),
                style: StrokeStyle(lineWidth: metrics.trackTrenchWidth, lineCap: .round)
            )

            guard value > 0.01 else { return }
            let endDeg = geometry.angle(for: value)

            var liquidPath = Path()
            liquidPath.addArc(
                center: geometry.center,
                radius: trackRadius,
                startAngle: .degrees(startDeg),
                endAngle: .degrees(endDeg),
                clockwise: isClockwise
            )

            // 2. Soft luminous fluid bloom (glow under-layer)
            context.stroke(
                liquidPath,
                with: .color(primaryColor.opacity(0.32)),
                style: StrokeStyle(lineWidth: metrics.trackBloomWidth, lineCap: .round)
            )

            // 3. Vibrant liquid core
            context.stroke(
                liquidPath,
                with: .linearGradient(
                    Gradient(colors: gradientColors),
                    startPoint: geometry.point(radius: trackRadius, angleDegrees: startDeg),
                    endPoint: geometry.point(radius: trackRadius, angleDegrees: endDeg)
                ),
                style: StrokeStyle(lineWidth: metrics.trackStrokeWidth, lineCap: .round)
            )

            // 4. Precision tactile thumb knob (Apple concentric ring indicator)
            let tipPoint = geometry.point(radius: trackRadius, angleDegrees: endDeg)
            let outerR = metrics.knobOuterRadius
            let innerR = metrics.knobInnerRadius
            let outerKnob = Path(ellipseIn: CGRect(x: tipPoint.x - outerR, y: tipPoint.y - outerR, width: outerR * 2, height: outerR * 2))
            context.fill(outerKnob, with: .color(primaryColor))
            context.stroke(outerKnob, with: .color(Color.white.opacity(0.92)), lineWidth: 1.25)

            let innerCore = Path(ellipseIn: CGRect(x: tipPoint.x - innerR, y: tipPoint.y - innerR, width: innerR * 2, height: innerR * 2))
            context.fill(innerCore, with: .color(Color.white))
        }
    }
}
