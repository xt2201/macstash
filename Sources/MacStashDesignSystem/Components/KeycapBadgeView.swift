import SwiftUI

/// Styled keycap badge representation for keyboard shortcuts conforming to Apple HIG.
public struct KeycapBadgeView: View {
    public let token: String

    public init(_ token: String) {
        self.token = token
    }

    public var body: some View {
        Text(token)
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundColor(.primary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2.5)
            .background(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(Color.primary.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.14), lineWidth: 0.7)
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(token)
    }
}
