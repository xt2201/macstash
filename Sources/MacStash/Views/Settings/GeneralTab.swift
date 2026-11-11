import SwiftUI
import AppKit
import MacStashCore
import SideDockSystem

public struct GeneralTab: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var appState: AppState
    @ObservedObject private var permissions = SystemPermissionService.shared
    @ObservedObject private var sideDock = SideDockManager.shared
    @State private var showResetConfirmation: Bool = false

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Section 1: Master Controls
            SettingsCard(
                title: appState.localized("general.masterControls"),
                systemImage: "power",
                accentColor: .blue
            ) {
                Toggle(appState.localized("general.enableMacStash"), isOn: $appState.isEnabled)
                    .font(.system(size: 13, weight: .semibold))

                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    Toggle(appState.localized("general.showMenuBarIcon"), isOn: $appState.settings.showMenuBarIcon)
                        .font(.system(size: 12.5, weight: .medium))

                    if !appState.settings.showMenuBarIcon {
                        HStack(spacing: 6) {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.orange)
                            Text(appState.localized("general.menuBarHiddenHint"))
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        .padding(.leading, 20)
                    }
                }

                Toggle(appState.localized("general.launchAtLogin"), isOn: Binding(
                    get: { appState.settings.launchAtLogin },
                    set: { newValue in
                        appState.settings.launchAtLogin = newValue
                        let applied = permissions.setLaunchAtLogin(newValue)
                        if !applied {
                            appState.settings.launchAtLogin = permissions.isLaunchAtLoginEnabled
                        }
                    }
                ))
                .font(.system(size: 12.5, weight: .medium))

                Divider()

                HStack {
                    Text(appState.localized("general.keepAwakeDefault"))
                        .font(.system(size: 12.5, weight: .medium))
                    Spacer()
                    Picker("", selection: $appState.settings.keepAwakeDefaultMinutes) {
                        Text(appState.localized("menubar.keepAwake15m")).tag(15)
                        Text(appState.localized("menubar.keepAwake30m")).tag(30)
                        Text(appState.localized("menubar.keepAwake1h")).tag(60)
                        Text(appState.localized("menubar.keepAwake2h")).tag(120)
                        Text(appState.localized("menubar.keepAwakeIndefinite")).tag(0)
                    }
                    .pickerStyle(.menu)
                    .frame(width: 170)
                }
            }

            // Section 2: Active Modules Matrix
            SettingsCard(
                title: appState.localized("general.moduleStatus"),
                systemImage: "square.grid.2x2.fill",
                accentColor: .cyan
            ) {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 10),
                        GridItem(.flexible(), spacing: 10),
                        GridItem(.flexible(), spacing: 10)
                    ],
                    spacing: 10
                ) {
                    moduleTile(
                        title: appState.localized("general.cornerDials"),
                        systemImage: "circle.grid.2x2.fill",
                        tint: .cyan,
                        isOn: Binding(
                            get: { appState.isCornerDialsEnabled },
                            set: { appState.isCornerDialsEnabled = $0 }
                        ),
                        targetTab: "Hot Corners"
                    )

                    moduleTile(
                        title: appState.localized("general.edgeSliders"),
                        systemImage: "slider.vertical.3",
                        tint: .blue,
                        isOn: Binding(
                            get: { appState.isEdgeSlidersEnabled },
                            set: { appState.isEdgeSlidersEnabled = $0 }
                        ),
                        targetTab: "Hot Corners"
                    )

                    moduleTile(
                        title: appState.localized("general.secondDock"),
                        systemImage: "dock.rectangle",
                        tint: .teal,
                        isOn: Binding(
                            get: { sideDock.config.isDockVisible },
                            set: { sideDock.setDockVisible($0) }
                        ),
                        targetTab: "Second Dock"
                    )

                    moduleTile(
                        title: appState.localized("general.stashShelf"),
                        systemImage: "tray.2.fill",
                        tint: .orange,
                        isOn: $appState.settings.isStashShelfEnabled,
                        targetTab: "Hot Corners"
                    )

                    moduleTile(
                        title: appState.localized("general.scratchpad"),
                        systemImage: "note.text",
                        tint: .yellow,
                        isOn: $appState.settings.isScratchpadEnabled,
                        targetTab: "Hot Corners"
                    )

                    moduleTile(
                        title: appState.localized("general.cursorPalette"),
                        systemImage: "dial.medium.fill",
                        tint: .purple,
                        isOn: $appState.settings.isCursorPaletteEnabled,
                        targetTab: "Hot Corners"
                    )
                }
            }

            // Section 3: Language & Locale
            SettingsCard(
                title: appState.localized("general.languageLocale"),
                systemImage: "globe",
                accentColor: .indigo
            ) {
                HStack {
                    Text(appState.localized("general.interfaceLanguage"))
                        .font(.system(size: 12.5, weight: .medium))
                    Spacer()
                    Picker("", selection: $appState.settings.language) {
                        Text(appState.localized("general.systemDefault")).tag("system")
                        Text(appState.localized("general.vietnamese")).tag("vi")
                        Text(appState.localized("general.english")).tag("en")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 280)
                }

                Text(appState.localized("general.languageHint"))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            // Section 4: System Permissions
            SettingsCard(
                title: appState.localized("general.systemPermissions"),
                systemImage: "lock.shield.fill",
                accentColor: .orange
            ) {
                permissionRow(
                    title: appState.localized("general.accessibility"),
                    description: appState.localized("general.accessibilityDesc"),
                    isGranted: permissions.isAccessibilityGranted,
                    onRequest: { permissions.requestAccessibilityPermission() },
                    onOpenSettings: { permissions.openAccessibilitySettings() }
                )

                Divider()

                permissionRow(
                    title: appState.localized("general.inputMonitoring"),
                    description: appState.localized("general.inputMonitoringDesc"),
                    isGranted: permissions.isInputMonitoringGranted,
                    onRequest: { permissions.requestInputMonitoringPermission() },
                    onOpenSettings: { permissions.openInputMonitoringSettings() }
                )

                Divider()

                permissionRow(
                    title: appState.localized("general.notifications"),
                    description: appState.localized("general.notificationsDesc"),
                    isGranted: permissions.isNotificationGranted,
                    onRequest: { permissions.requestNotificationPermission() },
                    onOpenSettings: { permissions.openNotificationSettings() }
                )
            }

            // Section 5: Factory Reset
            SettingsCard(
                title: appState.localized("general.factoryReset"),
                systemImage: "arrow.counterclockwise.circle.fill",
                accentColor: .red
            ) {
                HStack(alignment: .center, spacing: 14) {
                    Text(appState.localized("general.resetDesc"))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)

                    Spacer()

                    Button(role: .destructive) {
                        showResetConfirmation = true
                    } label: {
                        Text(appState.localized("general.resetButton"))
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
            }
        }
        .onAppear {
            permissions.checkAllPermissions()
            permissions.checkLaunchAtLogin()
        }
        .alert(appState.localized("general.resetAlertTitle"), isPresented: $showResetConfirmation) {
            Button(appState.localized("general.cancel"), role: .cancel) {}
            Button(appState.localized("general.resetConfirm"), role: .destructive) {
                appState.resetToDefaults()
            }
        } message: {
            Text(appState.localized("general.resetAlertMessage"))
        }
    }

    // MARK: - Subviews

    private func moduleTile(
        title: String,
        systemImage: String,
        tint: Color,
        isOn: Binding<Bool>,
        targetTab: String
    ) -> some View {
        let active = isOn.wrappedValue
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: systemImage)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(active ? .white : .secondary)
                    .frame(width: 26, height: 26)
                    .background(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(active ? AnyShapeStyle(tint.gradient) : AnyShapeStyle(Color.primary.opacity(0.08)))
                    )

                Spacer()

                Toggle("", isOn: isOn)
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .controlSize(.mini)
            }

            HStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.secondary.opacity(0.6))
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(active ? 0.065 : 0.025) : Color.black.opacity(active ? 0.04 : 0.02))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(active ? tint.opacity(0.32) : Color.primary.opacity(0.06), lineWidth: 0.8)
        )
        .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .onTapGesture {
            appState.requestedSettingsTab = targetTab
        }
    }

    private func permissionRow(
        title: String,
        description: String,
        isGranted: Bool,
        onRequest: @escaping () -> Void,
        onOpenSettings: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))

                    StatusBadgePill(
                        text: appState.localized(isGranted ? "general.granted" : "general.notGranted"),
                        color: isGranted ? .green : .orange
                    )
                }

                Text(description)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()

            if !isGranted {
                Button(appState.localized("general.grantPermission")) {
                    onRequest()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }

            Button(appState.localized("general.openSettings")) {
                onOpenSettings()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
    }
}
