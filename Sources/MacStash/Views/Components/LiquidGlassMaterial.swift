import SwiftUI
import AppKit

/// Apple-grade Liquid Glass optical styling system with automatic Light/Dark adaptive contrast.
///
/// Implements multi-layer optical physics:
/// 1. Translucent refractive substrate (system ultra-thin material).
/// 2. Caustic ambient glow reacting to active action tints and ambient lighting.
/// 3. Dual-path specular glass rim bevel reflecting a virtual 135° top-left light source.
/// 4. Subtle surface sheen simulating curved liquid glass reflection.
/// 5. Directional ambient contact shadow for realistic spatial depth.
public struct LiquidGlassModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    public var cornerRadius: CGFloat
    public var tint: Color
    public var specularIntensity: Double
    public var causticOpacity: Double
    public var shadowRadius: CGFloat
    public var isHighlighted: Bool
    public var backdropOpacity: Double

    public init(
        cornerRadius: CGFloat = 18,
        tint: Color = .clear,
        specularIntensity: Double = 1.0,
        causticOpacity: Double = 0.16,
        shadowRadius: CGFloat = 16,
        isHighlighted: Bool = false,
        backdropOpacity: Double = 1.0
    ) {
        self.cornerRadius = cornerRadius
        self.tint = tint
        self.specularIntensity = specularIntensity
        self.causticOpacity = causticOpacity
        self.shadowRadius = shadowRadius
        self.isHighlighted = isHighlighted
        self.backdropOpacity = backdropOpacity
    }

    private var isDark: Bool { colorScheme == .dark }

    public func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Layer 1: Frosted refractive substrate
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)

                    // Subtle contrast stabilizer for crisp readability over noisy wallpapers
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(isDark ? Color.black.opacity(0.18) : Color.white.opacity(0.28))

                    // Layer 2: Caustic ambient color tint
                    if tint != .clear {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                RadialGradient(
                                    colors: [
                                        tint.opacity(isHighlighted ? causticOpacity * 1.45 : causticOpacity),
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
                                    .init(color: Color.white.opacity((isDark ? 0.12 : 0.32) * specularIntensity), location: 0.0),
                                    .init(color: Color.white.opacity((isDark ? 0.03 : 0.08) * specularIntensity), location: 0.35),
                                    .init(color: Color.clear, location: 0.65)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .opacity(backdropOpacity)
            )
            .overlay(
                // Layer 4: Dual-path specular rim highlight (135° virtual light incidence)
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            stops: [
                                .init(color: (isDark ? Color.white : Color.white).opacity(isHighlighted ? 0.78 * specularIntensity : (isDark ? 0.48 : 0.72) * specularIntensity), location: 0.0),
                                .init(color: (isDark ? Color.white : Color.primary).opacity(isDark ? 0.18 * specularIntensity : 0.12 * specularIntensity), location: 0.4),
                                .init(color: Color.primary.opacity(isDark ? 0.05 : 0.08), location: 0.75),
                                .init(color: (tint == .clear ? Color.primary : tint).opacity(isHighlighted ? 0.48 : 0.22), location: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isHighlighted ? 1.5 : 1.0
                    )
            )
            .shadow(
                color: Color.black.opacity(isDark ? 0.32 : 0.16),
                radius: shadowRadius,
                x: 0,
                y: shadowRadius * 0.38
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
    @Environment(\.colorScheme) private var colorScheme
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

    private var isDark: Bool { colorScheme == .dark }

    public func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)

                    Circle()
                        .fill(isDark ? Color.black.opacity(0.14) : Color.white.opacity(0.24))

                    if tint != .clear {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        tint.opacity(isHighlighted ? causticOpacity * 1.55 : causticOpacity),
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
                                    .init(color: Color.white.opacity((isDark ? 0.18 : 0.40) * specularIntensity), location: 0.0),
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
                                .init(color: Color.white.opacity(isHighlighted ? 0.85 : (isDark ? 0.52 : 0.78) * specularIntensity), location: 0.0),
                                .init(color: Color.primary.opacity(isDark ? 0.14 * specularIntensity : 0.10 * specularIntensity), location: 0.55),
                                .init(color: (tint == .clear ? Color.primary : tint).opacity(0.30), location: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isHighlighted ? 1.4 : 1.0
                    )
            )
            .shadow(color: Color.black.opacity(isDark ? 0.26 : 0.14), radius: 6, x: 0, y: 3)
    }
}

public struct OptionalPreferredColorSchemeModifier: ViewModifier {
    public let colorScheme: ColorScheme?

    public func body(content: Content) -> some View {
        if let scheme = colorScheme {
            content.environment(\.colorScheme, scheme)
        } else {
            content
        }
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
        isHighlighted: Bool = false,
        backdropOpacity: Double = 1.0
    ) -> some View {
        self.modifier(
            LiquidGlassModifier(
                cornerRadius: cornerRadius,
                tint: tint,
                specularIntensity: specularIntensity,
                causticOpacity: causticOpacity,
                shadowRadius: shadowRadius,
                isHighlighted: isHighlighted,
                backdropOpacity: backdropOpacity
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

    /// Applies an optional light/dark color scheme override when user picks an explicit theme in Settings.
    public func macStashTheme(_ scheme: ColorScheme?) -> some View {
        self.modifier(OptionalPreferredColorSchemeModifier(colorScheme: scheme))
    }
}
