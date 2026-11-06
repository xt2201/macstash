import SwiftUI
import AppKit
import MacStashCore

public struct ShortcutsTab: View {
    @ObservedObject var appState: AppState

    public init(appState: AppState) {
        self.appState = appState
    }

    private var detectedConflict: String? {
        let cleaned = appState.settings.globalToggleDialsShortcut
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "+")

        if cleaned == "command+space" || cleaned == "cmd+space" {
            return "Spotlight Search (⌘Space)"
        }
        if cleaned == "command+tab" || cleaned == "cmd+tab" {
            return "Application Switcher (⌘Tab)"
        }
        if cleaned == "command+option+escape" || cleaned == "cmd+opt+esc" || cleaned == "command+alt+escape" {
            return "Force Quit Applications (⌘⌥Esc)"
        }
        if cleaned == "command+q" || cleaned == "cmd+q" {
            return "Quit Application (⌘Q)"
        }
        if cleaned == "command+w" || cleaned == "cmd+w" {
            return "Close Window (⌘W)"
        }
        return nil
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
                    if let conflict = detectedConflict {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("\(appState.localized("shortcuts.conflictDetected")): \(conflict)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.orange)
                        }
                    } else {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(appState.localized("shortcuts.noConflicts"))
                                .font(.system(size: 12, weight: .medium))
                        }
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
