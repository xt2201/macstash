import SwiftUI

/// Standardized search text field with magnifying glass icon and instant clear button.
public struct SearchInputField: View {
    public let placeholder: String
    @Binding public var text: String

    public init(placeholder: String, text: Binding<String>) {
        self.placeholder = placeholder
        self._text = text
    }

    public var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)

            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 11.5))

            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.primary.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.6)
        )
    }
}
