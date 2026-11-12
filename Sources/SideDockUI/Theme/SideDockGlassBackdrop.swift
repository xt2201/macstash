import SwiftUI
import SideDockCore

public struct SideDockGlassBackdrop: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    public let theme: DockTheme

    public init(theme: DockTheme) {
        self.theme = theme
    }

    private var customTint: Color? {
        guard let hex = theme.tintHex?.trimmingCharacters(in: .whitespacesAndNewlines),
              !hex.isEmpty else {
            return nil
        }
        return Color(hexString: hex)
    }

    public var body: some View {
        let isDark = colorScheme == .dark
        let effectiveRadius = theme.preset == .floatingPill ? 28.0 : theme.cornerRadius
        let shape = RoundedRectangle(cornerRadius: CGFloat(effectiveRadius), style: .continuous)

        ZStack {
            switch theme.preset {
            case .clear:
                Color.clear
            case .classicShelf:
                classicShelfBackdrop(isDark: isDark, shape: shape)
            case .highContrast:
                highContrastBackdrop(isDark: isDark, shape: shape)
            case .floatingPill, .macosGlass, .liquidGlass:
                glassBackdrop(isDark: isDark, shape: shape)
            }
        }
        .shadow(
            color: Color.black.opacity(theme.preset == .clear || theme.backdropStyle == .clear ? 0.0 : (isDark ? 0.34 : 0.18)),
            radius: CGFloat(theme.shadowRadius),
            x: 0,
            y: 6
        )
    }

    @ViewBuilder
    private func glassBackdrop(isDark: Bool, shape: RoundedRectangle) -> some View {
        if reduceTransparency {
            shape
                .fill(Color(white: isDark ? 0.12 : 0.94))
                .overlay(tintOverlay(shape: shape, opacity: 0.12))
                .overlay(shape.strokeBorder(Color.primary.opacity(0.35), lineWidth: 1.0))
        } else {
            switch theme.backdropStyle {
        case .clear:
            Color.clear
        case .lightGlass:
            shape
                .fill(.regularMaterial)
                .overlay(shape.fill(Color.white.opacity(0.28)))
                .overlay(tintOverlay(shape: shape, opacity: 0.12))
                .environment(\.colorScheme, .light)
                .overlay(shape.strokeBorder(Color.white.opacity(0.75), lineWidth: 1))
        case .darkGlass:
            shape
                .fill(.ultraThinMaterial)
                .overlay(shape.fill(Color.black.opacity(0.30)))
                .overlay(tintOverlay(shape: shape, opacity: 0.16))
                .environment(\.colorScheme, .dark)
                .overlay(shape.strokeBorder(Color.white.opacity(theme.borderOpacity * 0.75), lineWidth: 1))
        case .liquidGlass, .autoSystem:
            shape
                .fill(.ultraThinMaterial)
                .overlay(shape.fill(isDark ? Color.black.opacity(0.18) : Color.white.opacity(0.24)))
                .overlay(tintOverlay(shape: shape, opacity: 0.14))
                .overlay(
                    shape.strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(isDark ? max(0.32, theme.borderOpacity) : 0.8),
                                Color.primary.opacity(0.14),
                                Color.primary.opacity(0.06)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.0
                    )
                )
            }
        }
    }

    @ViewBuilder
    private func classicShelfBackdrop(isDark: Bool, shape: RoundedRectangle) -> some View {
        shape
            .fill(
                LinearGradient(
                    colors: isDark
                        ? [Color(white: 0.20, opacity: 0.88), Color(white: 0.10, opacity: 0.94)]
                        : [Color.white.opacity(0.78), Color(white: 0.84, opacity: 0.88)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(tintOverlay(shape: shape, opacity: 0.12))
            .overlay(
                VStack {
                    Spacer()
                    Rectangle()
                        .fill(Color.white.opacity(isDark ? 0.18 : 0.65))
                        .frame(height: 1.5)
                }
                .clipShape(shape)
            )
            .overlay(shape.strokeBorder(Color.primary.opacity(0.22), lineWidth: 1))
    }

    @ViewBuilder
    private func highContrastBackdrop(isDark: Bool, shape: RoundedRectangle) -> some View {
        shape
            .fill(isDark ? Color(white: 0.08, opacity: 0.95) : Color(white: 0.97, opacity: 0.96))
            .overlay(tintOverlay(shape: shape, opacity: 0.14))
            .overlay(shape.strokeBorder(Color.primary.opacity(0.45), lineWidth: 1.4))
    }

    @ViewBuilder
    private func tintOverlay(shape: RoundedRectangle, opacity: Double) -> some View {
        if let tint = customTint {
            shape.fill(tint.opacity(opacity))
        }
    }
}

private extension Color {
    init?(hexString: String) {
        let clean = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        guard clean.count == 6, let value = UInt64(clean, radix: 16) else {
            return nil
        }
        let r = Double((value >> 16) & 0xFF) / 255.0
        let g = Double((value >> 8) & 0xFF) / 255.0
        let b = Double(value & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
