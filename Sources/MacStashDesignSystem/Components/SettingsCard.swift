import SwiftUI
import AppKit

/// Clean macOS Sequoia-style grouped inset card replacing boxy GroupBox borders.
public struct SettingsCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    public let title: String
    public let systemImage: String
    public let accentColor: Color
    public let trailingText: String?
    public let content: () -> Content

    public init(
        title: String,
        systemImage: String,
        accentColor: Color = .accentColor,
        trailingText: String? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.systemImage = systemImage
        self.accentColor = accentColor
        self.trailingText = trailingText
        self.content = content
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 22, height: 22)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(accentColor.gradient)
                    )

                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)

                Spacer()

                if let trailingText {
                    Text(trailingText)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                content()
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.045) : Color.black.opacity(0.032))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.primary.opacity(colorScheme == .dark ? 0.09 : 0.07), lineWidth: 0.8)
            )
        }
    }
}
