import SwiftUI
import SideDockCore

public struct SideDockGlassBackdrop: View {
    @Environment(\.colorScheme) private var colorScheme
    public let theme: DockTheme

    public init(theme: DockTheme) {
        self.theme = theme
    }

    public var body: some View {
        let isDark = colorScheme == .dark
        ZStack {
            switch theme.backdropStyle {
            case .clear:
                Color.clear

            case .lightGlass:
                RoundedRectangle(cornerRadius: CGFloat(theme.cornerRadius), style: .continuous)
                    .fill(.regularMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: CGFloat(theme.cornerRadius), style: .continuous)
                            .fill(Color.white.opacity(0.28))
                    )
                    .environment(\.colorScheme, .light)
                    .overlay(
                        RoundedRectangle(cornerRadius: CGFloat(theme.cornerRadius), style: .continuous)
                            .strokeBorder(Color.white.opacity(0.75), lineWidth: 1)
                    )

            case .darkGlass:
                RoundedRectangle(cornerRadius: CGFloat(theme.cornerRadius), style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: CGFloat(theme.cornerRadius), style: .continuous)
                            .fill(Color.black.opacity(0.28))
                    )
                    .environment(\.colorScheme, .dark)
                    .overlay(
                        RoundedRectangle(cornerRadius: CGFloat(theme.cornerRadius), style: .continuous)
                            .strokeBorder(Color.white.opacity(theme.borderOpacity * 0.7), lineWidth: 1)
                    )

            case .liquidGlass, .autoSystem:
                RoundedRectangle(cornerRadius: CGFloat(theme.cornerRadius), style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: CGFloat(theme.cornerRadius), style: .continuous)
                            .fill(isDark ? Color.black.opacity(0.16) : Color.white.opacity(0.24))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: CGFloat(theme.cornerRadius), style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(isDark ? theme.borderOpacity : 0.75),
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
        .shadow(
            color: Color.black.opacity(theme.backdropStyle == .clear ? 0.0 : (isDark ? 0.28 : 0.16)),
            radius: CGFloat(theme.shadowRadius),
            x: 0,
            y: 4
        )
    }
}
