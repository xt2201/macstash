import SwiftUI
import AppKit
import MacStashCore
import MacStashDesignSystem

public struct MenuBarFooterBar: View {
    @ObservedObject var appState: AppState
    public var onOpenSettings: () -> Void
    public var onOpenGuide: () -> Void

    public init(
        appState: AppState,
        onOpenSettings: @escaping () -> Void,
        onOpenGuide: @escaping () -> Void
    ) {
        self.appState = appState
        self.onOpenSettings = onOpenSettings
        self.onOpenGuide = onOpenGuide
    }

    public var body: some View {
        VStack(spacing: 2) {
            MenuBarActionRow(
                icon: "arrow.triangle.2.circlepath",
                title: appState.localized("menubar.checkForUpdates"),
                shortcut: nil,
                tint: .primary
            ) {
                appState.updater.checkForUpdates(silent: false)
            }

            MenuBarActionRow(
                icon: "book",
                title: appState.localized("menubar.userGuide"),
                shortcut: "⌘?",
                tint: .primary,
                action: onOpenGuide
            )

            MenuBarActionRow(
                icon: "gearshape",
                title: appState.localized("menubar.quickSettings"),
                shortcut: "⌘,",
                tint: .primary,
                action: onOpenSettings
            )

            Divider().opacity(0.5).padding(.vertical, 2)

            MenuBarActionRow(
                icon: "power",
                title: appState.localized("menubar.quit"),
                shortcut: "⌘Q",
                tint: .red
            ) {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}

private struct MenuBarActionRow: View {
    let icon: String
    let title: String
    let shortcut: String?
    let tint: Color
    let action: () -> Void

    @State private var isHovered: Bool = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundColor(tint)
                    .frame(width: 16)

                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(tint)

                Spacer()

                if let shortcut {
                    Text(shortcut)
                        .font(.system(size: 10.5, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5.5)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(isHovered ? Color.primary.opacity(0.08) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}
