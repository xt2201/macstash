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
            GroupBox(label: Label(appState.localized("shortcuts.globalHotkeys"), systemImage: "keyboard")) {
                VStack(alignment: .leading, spacing: 14) {
                    shortcutRow(
                        title: appState.localized("shortcuts.toggleDials"),
                        description: appState.localized("shortcuts.toggleDialsDesc"),
                        shortcut: $appState.settings.globalToggleDialsShortcut
                    )
                }
                .padding(8)
            }

            GroupBox(label: Label(appState.localized("shortcuts.conflictAnalysis"), systemImage: "exclamationmark.shield")) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(appState.localized("shortcuts.noConflicts"))
                            .font(.system(size: 12, weight: .medium))
                    }
                    Text(appState.localized("shortcuts.conflictHint"))
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
