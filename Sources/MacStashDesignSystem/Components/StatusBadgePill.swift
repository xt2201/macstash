import SwiftUI

/// Compact pill status indicator with optional pulsing/solid dot.
public struct StatusBadgePill: View {
    public let text: String
    public let color: Color
    public let showDot: Bool

    public init(text: String, color: Color, showDot: Bool = true) {
        self.text = text
        self.color = color
        self.showDot = showDot
    }

    public var body: some View {
        HStack(spacing: 5) {
            if showDot {
                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)
            }
            Text(text)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Capsule().fill(color.opacity(0.14)))
        .overlay(Capsule().strokeBorder(color.opacity(0.28), lineWidth: 0.6))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(text)
    }
}
