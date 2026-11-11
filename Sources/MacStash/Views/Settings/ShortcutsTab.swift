import SwiftUI
import AppKit
import MacStashCore

public struct ShortcutsTab: View {
    @ObservedObject var appState: AppState

    public init(appState: AppState) {
        self.appState = appState
    }

    private var detectedConflicts: [ShortcutConflict] {
        ShortcutValidator.auditConflicts(
            shortcuts: [
                (appState.localized("shortcuts.toggleDials"), appState.settings.globalToggleDialsShortcut),
                (appState.localized("shortcuts.cursorPalette"), appState.settings.cursorPaletteShortcut),
                (appState.localized("shortcuts.stashShelf"), appState.settings.stashShelfShortcut),
                (appState.localized("shortcuts.scratchpad"), appState.settings.scratchpadShortcut)
            ],
            language: appState.effectiveLanguage
        )
    }

    public var body: some View {
        let conflicts = detectedConflicts

        VStack(alignment: .leading, spacing: 18) {
            // Section 1: Interactive Global Hotkeys
            SettingsCard(
                title: appState.localized("shortcuts.globalHotkeys"),
                systemImage: "keyboard.fill",
                accentColor: .indigo
            ) {
                HStack {
                    Spacer()
                    Button(appState.localized("shortcuts.resetDefault")) {
                        appState.settings.globalToggleDialsShortcut = "Option+S"
                        appState.settings.cursorPaletteShortcut = "Option+Space"
                        appState.settings.stashShelfShortcut = "Control+Option+S"
                        appState.settings.scratchpadShortcut = "Control+Option+N"
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                }

                hotkeyRow(
                    title: appState.localized("shortcuts.toggleDials"),
                    subtitle: appState.localized("shortcuts.toggleDialsDesc"),
                    shortcut: $appState.settings.globalToggleDialsShortcut,
                    defaultValue: "Option+S"
                )

                Divider()

                hotkeyRow(
                    title: appState.localized("shortcuts.cursorPalette"),
                    subtitle: appState.localized("shortcuts.cursorPaletteDesc"),
                    shortcut: $appState.settings.cursorPaletteShortcut,
                    defaultValue: "Option+Space"
                )

                Divider()

                hotkeyRow(
                    title: appState.localized("shortcuts.stashShelf"),
                    subtitle: appState.localized("shortcuts.stashShelfDesc"),
                    shortcut: $appState.settings.stashShelfShortcut,
                    defaultValue: "Control+Option+S"
                )

                Divider()

                hotkeyRow(
                    title: appState.localized("shortcuts.scratchpad"),
                    subtitle: appState.localized("shortcuts.scratchpadDesc"),
                    shortcut: $appState.settings.scratchpadShortcut,
                    defaultValue: "Control+Option+N"
                )
            }

            // Section 2: Conflict Analysis
            SettingsCard(
                title: appState.localized("shortcuts.conflictAnalysis"),
                systemImage: conflicts.isEmpty ? "checkmark.shield.fill" : "exclamationmark.triangle.fill",
                accentColor: conflicts.isEmpty ? .green : .orange
            ) {
                if conflicts.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(appState.localized("shortcuts.noConflicts"))
                            .font(.system(size: 12.5, weight: .medium))
                    }
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text(appState.localized("shortcuts.conflictDetected"))
                                .font(.system(size: 12.5, weight: .semibold))
                                .foregroundColor(.orange)
                        }

                        ForEach(conflicts) { conflict in
                            HStack(spacing: 8) {
                                Text(conflict.actionKey)
                                    .font(.system(size: 11.5, weight: .semibold))
                                Spacer()
                                Text(conflict.reason)
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .fill(Color.orange.opacity(0.1))
                            )
                        }
                    }
                }

                Text(appState.localized("shortcuts.conflictHint"))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            // Section 3: Built-in & Second Dock Reference
            SettingsCard(
                title: appState.localized("shortcuts.referenceTitle"),
                systemImage: "command.square.fill",
                accentColor: .teal
            ) {
                referenceRow(title: appState.localized("shortcuts.dockToggle"), tokens: ["⌃", "⌥", "D"])
                Divider()
                referenceRow(title: appState.localized("shortcuts.dockProfiles"), tokens: ["⌘", "1–8"])
                Divider()
                referenceRow(title: appState.localized("shortcuts.openSettings"), tokens: ["⌘", ","])
                Divider()
                referenceRow(title: appState.localized("shortcuts.openGuide"), tokens: ["⌘", "?"])
                Divider()
                referenceRow(title: appState.localized("shortcuts.dismissOverlay"), tokens: ["⎋", appState.localized("shortcuts.escKey")])
            }
        }
    }

    private func hotkeyRow(
        title: String,
        subtitle: String,
        shortcut: Binding<String>,
        defaultValue: String
    ) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12.5, weight: .semibold))
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()

            ShortcutRecorderView(
                shortcut: shortcut,
                defaultValue: defaultValue,
                recordLabel: appState.localized("shortcuts.record"),
                pressKeysLabel: appState.localized("shortcuts.pressKeys"),
                clearLabel: appState.localized("shortcuts.clear")
            )
        }
    }

    private func referenceRow(title: String, tokens: [String]) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 12, weight: .medium))
            Spacer()
            HStack(spacing: 4) {
                ForEach(Array(tokens.enumerated()), id: \.offset) { _, token in
                    Text(token)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(Color.primary.opacity(0.08))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .strokeBorder(Color.primary.opacity(0.14), lineWidth: 0.7)
                        )
                }
            }
        }
    }
}
