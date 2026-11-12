import SwiftUI
import AppKit
import MacStashCore
import MacStashDesignSystem

public struct MenuBarModulesGrid: View {
    @ObservedObject var appState: AppState

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                quickToggleTile(
                    title: appState.localized("menubar.cornerDials"),
                    icon: "circle.dashed",
                    tint: .blue,
                    isActive: appState.isCornerDialsEnabled
                ) {
                    appState.isCornerDialsEnabled.toggle()
                }

                quickToggleTile(
                    title: appState.localized("menubar.edgeSlider"),
                    icon: "slider.vertical.3",
                    tint: .indigo,
                    isActive: appState.isEdgeSlidersEnabled
                ) {
                    appState.isEdgeSlidersEnabled.toggle()
                }
            }

            HStack(spacing: 6) {
                quickToggleTile(
                    title: appState.localized("general.secondDock"),
                    icon: "dock.rectangle",
                    tint: .teal,
                    isActive: appState.sideDock.config.isDockVisible
                ) {
                    appState.sideDock.toggleDock()
                }

                KeepAwakeTile(keepAwake: appState.keepAwake)
            }

            if appState.settings.isStashShelfEnabled || appState.settings.isScratchpadEnabled {
                HStack(spacing: 6) {
                    if appState.settings.isStashShelfEnabled {
                        quickToggleTile(
                            title: "\(appState.localized("menubar.stash")) (\(appState.stashShelf.items.count))",
                            icon: "tray.2.fill",
                            tint: .cyan,
                            isActive: appState.stashShelf.isShelfOpen
                        ) {
                            if appState.stashShelf.isShelfOpen {
                                appState.stashShelf.closeShelf()
                            } else {
                                appState.scratchpad.isScratchpadOpen = false
                                appState.stashShelf.openShelf()
                            }
                        }
                    }

                    if appState.settings.isScratchpadEnabled {
                        quickToggleTile(
                            title: appState.localized("menubar.notes"),
                            icon: "note.text",
                            tint: .green,
                            isActive: appState.scratchpad.isScratchpadOpen
                        ) {
                            if appState.scratchpad.isScratchpadOpen {
                                appState.scratchpad.isScratchpadOpen = false
                            } else {
                                appState.stashShelf.closeShelf()
                                appState.scratchpad.isScratchpadOpen = true
                            }
                        }
                    }
                }
            }
        }
    }

    private func quickToggleTile(
        title: String,
        icon: String,
        tint: Color,
        isActive: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(isActive ? tint : .secondary)
                    .frame(width: 16)

                Text(title)
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundColor(isActive ? .primary : .secondary)
                    .lineLimit(1)

                Spacer(minLength: 2)

                Circle()
                    .fill(isActive ? tint : Color.secondary.opacity(0.3))
                    .frame(width: 6, height: 6)
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(isActive ? tint.opacity(0.14) : Color.primary.opacity(0.045))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .strokeBorder(isActive ? tint.opacity(0.35) : Color.clear, lineWidth: 0.8)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct KeepAwakeTile: View {
    @ObservedObject var keepAwake: KeepAwakeManager

    private func localized(_ key: String) -> String {
        LocalizationService.shared.localized(key)
    }

    var body: some View {
        Menu {
            Button(localized("menubar.keepAwakeOff")) { keepAwake.deactivate() }
            Divider()
            Button(localized("menubar.keepAwake15m")) { keepAwake.activate(minutes: 15) }
            Button(localized("menubar.keepAwake30m")) { keepAwake.activate(minutes: 30) }
            Button(localized("menubar.keepAwake1h")) { keepAwake.activate(minutes: 60) }
            Button(localized("menubar.keepAwake2h")) { keepAwake.activate(minutes: 120) }
            Button(localized("menubar.keepAwakeIndefinite")) { keepAwake.activate(minutes: -1) }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(keepAwake.isActive ? .orange : .secondary)

                Text(keepAwake.isActive ? keepAwake.formattedRemaining : localized("menubar.keepAwake"))
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundColor(keepAwake.isActive ? .primary : .secondary)
                    .lineLimit(1)

                Spacer(minLength: 2)

                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(keepAwake.isActive ? Color.orange.opacity(0.14) : Color.primary.opacity(0.045))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .strokeBorder(keepAwake.isActive ? Color.orange.opacity(0.35) : Color.clear, lineWidth: 0.8)
            )
        }
        .menuStyle(.borderlessButton)
    }
}
