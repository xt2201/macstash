import SwiftUI

/// Renders precision liquid fluid level tracks and gauges with optical glass realism.
/// Simulates glowing luminous fluid contained within a crystal glass tube or curved trench.
public struct LiquidVerticalTrack: View {
    @Environment(\.colorScheme) private var colorScheme
    public let progress: Double // 0.0 ... 1.0
    public let primaryTint: Color
    public let secondaryTint: Color
    public let trackWidth: CGFloat
    public let isMuted: Bool

    public init(
        progress: Double,
        primaryTint: Color,
        secondaryTint: Color,
        trackWidth: CGFloat = 16,
        isMuted: Bool = false
    ) {
        self.progress = max(0.0, min(1.0, progress))
        self.primaryTint = primaryTint
        self.secondaryTint = secondaryTint
        self.trackWidth = trackWidth
        self.isMuted = isMuted
    }

    public var body: some View {
        let isDark = colorScheme == .dark
        GeometryReader { geo in
            let totalHeight = geo.size.height
            let fillHeight = totalHeight * CGFloat(progress)

            ZStack(alignment: .bottom) {
                // 1. Crystal Glass Tube Chamber (Concave trench with subtle inner shadow)
                Capsule(style: .continuous)
                    .fill(isDark ? Color.white.opacity(0.09) : Color.black.opacity(0.08))
                    .frame(width: trackWidth, height: totalHeight)
                    .overlay(
                        Capsule(style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    stops: [
                                        .init(color: Color.white.opacity(isDark ? 0.35 : 0.70), location: 0.0),
                                        .init(color: Color.primary.opacity(0.08), location: 0.45),
                                        .init(color: Color.primary.opacity(0.03), location: 1.0)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.0
                            )
                    )

                // 2. Luminous Fluid Column
                if fillHeight > 2.0 {
                    let fluidColors = isMuted
                        ? [Color.red.opacity(0.85), Color.red.opacity(0.5)]
                        : [primaryTint, secondaryTint]

                    ZStack(alignment: .top) {
                        Capsule(style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: fluidColors,
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                            .frame(width: trackWidth - 2, height: fillHeight)
                            .shadow(
                                color: (isMuted ? Color.red : primaryTint).opacity(0.40),
                                radius: 4,
                                x: 0,
                                y: 0
                            )

                        // 3. Fluid Meniscus Highlight (Droplet curve at top of liquid column)
                        Capsule(style: .continuous)
                            .fill(Color.white.opacity(0.85))
                            .frame(width: trackWidth - 6, height: 3.5)
                            .padding(.top, 2)
                    }
                    .padding(.bottom, 1)
                }

                // 4. Subtle center glass wall reflection streak
                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: Color.white.opacity(0.25), location: 0.0),
                                .init(color: Color.clear, location: 0.5)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 2.0, height: totalHeight - 6)
                    .offset(x: -(trackWidth * 0.25))
                    .allowsHitTesting(false)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
