import SwiftUI
import AppKit

/// Hover-aware circular glass micro button used across floating panels, drawers, and popovers.
public struct HoverActionButton: View {
    public let systemImage: String
    public let tint: Color
    public let size: CGFloat
    public let helpText: String
    public let action: () -> Void

    @State private var isHovered: Bool = false

    public init(
        systemImage: String,
        tint: Color = .secondary,
        size: CGFloat = 26,
        helpText: String = "",
        action: @escaping () -> Void
    ) {
        self.systemImage = systemImage
        self.tint = tint
        self.size = size
        self.helpText = helpText
        self.action = action
    }

    private var reduceMotion: Bool {
        NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: size * 0.42, weight: .semibold))
                .foregroundColor(isHovered ? .primary : tint)
                .frame(width: size, height: size)
                .circularLiquidGlass(
                    tint: isHovered ? tint : .clear,
                    specularIntensity: 0.85,
                    causticOpacity: 0.22,
                    isHighlighted: isHovered
                )
                .scaleEffect(reduceMotion ? 1.0 : (isHovered ? 1.07 : 1.0))
                .animation(reduceMotion ? nil : .spring(response: 0.18, dampingFraction: 0.72), value: isHovered)
        }
        .buttonStyle(.plain)
        .help(helpText)
        .accessibilityLabel(helpText.isEmpty ? systemImage : helpText)
        .accessibilityHint(helpText)
        .onHover { isHovered = $0 }
    }
}
