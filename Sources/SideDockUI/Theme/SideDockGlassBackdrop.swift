import SwiftUI
import SideDockCore

public struct SideDockGlassBackdrop: View {
    public let theme: DockTheme

    public init(theme: DockTheme) {
        self.theme = theme
    }

    public var body: some View {
        ZStack {
            switch theme.backdropStyle {
            case .clear:
                Color.clear

            case .lightGlass:
                RoundedRectangle(cornerRadius: CGFloat(theme.cornerRadius), style: .continuous)
                    .fill(.regularMaterial)
                    .environment(\.colorScheme, .light)
                    .overlay(
                        RoundedRectangle(cornerRadius: CGFloat(theme.cornerRadius), style: .continuous)
                            .stroke(Color.white.opacity(theme.borderOpacity), lineWidth: 1)
                    )

            case .darkGlass:
                RoundedRectangle(cornerRadius: CGFloat(theme.cornerRadius), style: .continuous)
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
                    .overlay(
                        RoundedRectangle(cornerRadius: CGFloat(theme.cornerRadius), style: .continuous)
                            .stroke(Color.white.opacity(theme.borderOpacity * 0.6), lineWidth: 1)
                    )

            case .liquidGlass, .autoSystem:
                RoundedRectangle(cornerRadius: CGFloat(theme.cornerRadius), style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: CGFloat(theme.cornerRadius), style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(theme.borderOpacity),
                                        Color.white.opacity(theme.borderOpacity * 0.2),
                                        Color.black.opacity(0.1)
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
            color: Color.black.opacity(theme.backdropStyle == .clear ? 0.0 : 0.25),
            radius: CGFloat(theme.shadowRadius),
            x: 0,
            y: 4
        )
    }
}
