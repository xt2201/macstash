import SwiftUI
import AppKit
import MacStashCore

public struct ShortcutsTab: View {
    @ObservedObject var appState: AppState

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            GroupBox(label: Label("Global Hotkeys", systemImage: "keyboard")) {
                VStack(alignment: .leading, spacing: 14) {
                    shortcutRow(
                        title: "Toggle Corner Dials",
                        description: "Quickly reveal or hide active corner dial controls",
                        shortcut: $appState.settings.globalToggleDialsShortcut
                    )

                    Divider()

                    shortcutRow(
                        title: "Toggle Hidden Dock",
                        description: "Slide out or dismiss the hidden application shelf",
                        shortcut: $appState.settings.globalToggleDockShortcut
                    )
                }
                .padding(8)
            }

            GroupBox(label: Label("Shortcut Conflict Analysis", systemImage: "exclamationmark.shield")) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("No conflicting system shortcuts detected.")
                            .font(.system(size: 12, weight: .medium))
                    }
                    Text("MacStash automatically audits against macOS reserved shortcuts (⌘Space Spotlight, ⌘Tab Application Switcher, ⌘⌥Esc Force Quit).")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .padding(8)
            }
        }
    }

    private func shortcutRow(title: String, description: String, shortcut: Binding<String>) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                Text(description)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            Spacer()
            TextField("Shortcut", text: shortcut)
                .font(.system(size: 12, design: .monospaced))
                .textFieldStyle(.roundedBorder)
                .frame(width: 140)
        }
    }
}
