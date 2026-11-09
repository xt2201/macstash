import SwiftUI
import AppKit

/// Apple-grade Liquid Glass optical styling system.
///
/// Implements multi-layer optical physics:
/// 1. Translucent refractive substrate (system ultra-thin material).
/// 2. Caustic ambient glow reacting to active action tints and ambient lighting.
/// 3. Dual-path specular glass rim bevel reflecting a virtual 135° top-left light source.
/// 4. Subtle surface sheen simulating curved liquid glass reflection.
/// 5. Directional ambient contact shadow for realistic spatial depth.
public struct LiquidGlassModifier: ViewModifier {
    public var cornerRadius: CGFloat
    public var tint: Color
    public var specularIntensity: Double
    public var causticOpacity: Double
    public var shadowRadius: CGFloat
    public var isHighlighted: Bool

    public init(
        cornerRadius: CGFloat = 18,
        tint: Color = .clear,
        specularIntensity: Double = 1.0,
        causticOpacity: Double = 0.16,
        shadowRadius: CGFloat = 16,
        isHighlighted: Bool = false
    ) {
        self.cornerRadius = cornerRadius
        self.tint = tint
        self.specularIntensity = specularIntensity
        self.causticOpacity = causticOpacity
        self.shadowRadius = shadowRadius
        self.isHighlighted = isHighlighted
    }

    public func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Layer 1: Frosted refractive substrate
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)

                    // Layer 2: Caustic ambient color tint
                    if tint != .clear {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                RadialGradient(
                                    colors: [
                                        tint.opacity(isHighlighted ? causticOpacity * 1.5 : causticOpacity),
                                        tint.opacity(causticOpacity * 0.35),
                                        Color.clear
                                    ],
                                    center: .topLeading,
                                    startRadius: 8,
                                    endRadius: 220
                                )
                            )
                    }

                    // Layer 3: Glass surface gloss sheen
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                stops: [
                                    .init(color: Color.white.opacity(0.12 * specularIntensity), location: 0.0),
                                    .init(color: Color.white.opacity(0.03 * specularIntensity), location: 0.35),
                                    .init(color: Color.clear, location: 0.65)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            )
            .overlay(
                // Layer 4: Dual-path specular rim highlight (135° virtual light incidence)
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            stops: [
                                .init(color: Color.white.opacity(isHighlighted ? 0.75 * specularIntensity : 0.50 * specularIntensity), location: 0.0),
                                .init(color: Color.white.opacity(0.20 * specularIntensity), location: 0.35),
                                .init(color: Color.white.opacity(0.04), location: 0.70),
                                .init(color: (tint == .clear ? Color.white : tint).opacity(isHighlighted ? 0.45 : 0.20), location: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isHighlighted ? 1.5 : 1.0
                    )
            )
            .shadow(
                color: Color.black.opacity(0.30),
                radius: shadowRadius,
                x: 0,
                y: shadowRadius * 0.4
            )
            .shadow(
                color: tint == .clear ? Color.clear : tint.opacity(isHighlighted ? 0.22 : 0.08),
                radius: shadowRadius * 0.75,
                x: 0,
                y: 0
            )
    }
}

/// Circular Liquid Glass modifier for badges, satellite micro-buttons, and circular dials
public struct CircularLiquidGlassModifier: ViewModifier {
    public var tint: Color
    public var specularIntensity: Double
    public var causticOpacity: Double
    public var isHighlighted: Bool

    public init(
        tint: Color = .clear,
        specularIntensity: Double = 1.0,
        causticOpacity: Double = 0.20,
        isHighlighted: Bool = false
    ) {
        self.tint = tint
        self.specularIntensity = specularIntensity
        self.causticOpacity = causticOpacity
        self.isHighlighted = isHighlighted
    }

    public func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)

                    if tint != .clear {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        tint.opacity(isHighlighted ? causticOpacity * 1.6 : causticOpacity),
                                        Color.clear
                                    ],
                                    center: .topLeading,
                                    startRadius: 2,
                                    endRadius: 50
                                )
                            )
                    }

                    Circle()
                        .fill(
                            LinearGradient(
                                stops: [
                                    .init(color: Color.white.opacity(0.18 * specularIntensity), location: 0.0),
                                    .init(color: Color.clear, location: 0.6)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            )
            .overlay(
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            stops: [
                                .init(color: Color.white.opacity(isHighlighted ? 0.8 : 0.55 * specularIntensity), location: 0.0),
                                .init(color: Color.white.opacity(0.15 * specularIntensity), location: 0.5),
                                .init(color: (tint == .clear ? Color.white : tint).opacity(0.3), location: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isHighlighted ? 1.4 : 1.0
                    )
            )
            .shadow(color: Color.black.opacity(0.25), radius: 6, x: 0, y: 3)
    }
}

extension View {
    /// Applies the Apple Liquid Glass visual styling to any rectangular or rounded view
    public func liquidGlass(
        cornerRadius: CGFloat = 18,
        tint: Color = .clear,
        specularIntensity: Double = 1.0,
        causticOpacity: Double = 0.16,
        shadowRadius: CGFloat = 16,
        isHighlighted: Bool = false
    ) -> some View {
        self.modifier(
            LiquidGlassModifier(
                cornerRadius: cornerRadius,
                tint: tint,
                specularIntensity: specularIntensity,
                causticOpacity: causticOpacity,
                shadowRadius: shadowRadius,
                isHighlighted: isHighlighted
            )
        )
    }

    /// Applies the circular Apple Liquid Glass styling to any circular button, badge, or dial
    public func circularLiquidGlass(
        tint: Color = .clear,
        specularIntensity: Double = 1.0,
        causticOpacity: Double = 0.20,
        isHighlighted: Bool = false
    ) -> some View {
        self.modifier(
            CircularLiquidGlassModifier(
                tint: tint,
                specularIntensity: specularIntensity,
                causticOpacity: causticOpacity,
                isHighlighted: isHighlighted
            )
        )
    }
}
