import SwiftUI
import AppKit
import MacStashCore
import MacStashDesignSystem

public struct QuarterCircleGlassBackdrop: View {
    @Environment(\.colorScheme) private var colorScheme
    public let corner: CornerPosition
    public let dialSize: CGFloat
    public let tint: Color

    public init(corner: CornerPosition, dialSize: CGFloat, tint: Color) {
        self.corner = corner
        self.dialSize = dialSize
        self.tint = tint
    }

    private var isDark: Bool { colorScheme == .dark }
    private var reduceTransparency: Bool {
        NSWorkspace.shared.accessibilityDisplayShouldReduceTransparency
    }

    public var body: some View {
        ZStack {
            if reduceTransparency {
                QuarterCircleBackdrop(corner: corner)
                    .fill(isDark ? Color(red: 0.12, green: 0.13, blue: 0.16) : Color(red: 0.94, green: 0.95, blue: 0.97))
            } else {
                // Layer 1: Frosted refractive glass substrate
                QuarterCircleBackdrop(corner: corner)
                    .fill(.ultraThinMaterial)

                QuarterCircleBackdrop(corner: corner)
                    .fill(isDark ? Color.black.opacity(0.16) : Color.white.opacity(0.28))

                // Layer 2: Caustic ambient reflection originating from screen vertex
                QuarterCircleBackdrop(corner: corner)
                    .fill(
                        RadialGradient(
                            colors: [
                                tint.opacity(0.22),
                                tint.opacity(0.06),
                                Color.clear
                            ],
                            center: unitPoint(for: corner),
                            startRadius: 15,
                            endRadius: dialSize * 0.95
                        )
                    )

                // Layer 3: Glass surface gloss sheen
                QuarterCircleBackdrop(corner: corner)
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: Color.white.opacity(isDark ? 0.12 : 0.35), location: 0.0),
                                .init(color: Color.white.opacity(0.02), location: 0.4),
                                .init(color: Color.clear, location: 0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            // Layer 4: Dual-path specular perimeter bevel
            QuarterCircleBackdrop(corner: corner)
                .stroke(
                    LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity(isDark ? 0.55 : 0.85), location: 0.0),
                            .init(color: Color.primary.opacity(0.14), location: 0.45),
                            .init(color: Color.primary.opacity(0.05), location: 0.8),
                            .init(color: tint.opacity(0.32), location: 1.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.2
                )
        }
        .frame(width: dialSize, height: dialSize)
        .shadow(color: Color.black.opacity(isDark ? 0.32 : 0.16), radius: 14, x: 0, y: 5)
        .shadow(color: tint == .clear ? Color.clear : tint.opacity(0.15), radius: 10, x: 0, y: 0)
    }

    private func unitPoint(for corner: CornerPosition) -> UnitPoint {
        switch corner {
        case .topLeft: return .topLeading
        case .topRight: return .topTrailing
        case .bottomLeft: return .bottomLeading
        case .bottomRight: return .bottomTrailing
        }
    }
}

public struct QuarterCircleBackdrop: Shape {
    public let corner: CornerPosition

    public init(corner: CornerPosition) {
        self.corner = corner
    }

    public func path(in rect: CGRect) -> Path {
        var path = Path()
        switch corner {
        case .topLeft:
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addArc(
                center: CGPoint(x: rect.minX, y: rect.minY),
                radius: rect.width,
                startAngle: .degrees(0),
                endAngle: .degrees(90),
                clockwise: false
            )
            path.closeSubpath()
        case .topRight:
            path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addArc(
                center: CGPoint(x: rect.maxX, y: rect.minY),
                radius: rect.width,
                startAngle: .degrees(180),
                endAngle: .degrees(90),
                clockwise: true
            )
            path.closeSubpath()
        case .bottomLeft:
            path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addArc(
                center: CGPoint(x: rect.minX, y: rect.maxY),
                radius: rect.width,
                startAngle: .degrees(270),
                endAngle: .degrees(360),
                clockwise: false
            )
            path.closeSubpath()
        case .bottomRight:
            path.move(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addArc(
                center: CGPoint(x: rect.maxX, y: rect.maxY),
                radius: rect.width,
                startAngle: .degrees(180),
                endAngle: .degrees(270),
                clockwise: false
            )
            path.closeSubpath()
        }
        return path
    }
}
