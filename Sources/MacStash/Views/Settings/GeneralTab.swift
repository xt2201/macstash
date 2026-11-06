import SwiftUI
import AppKit
import MacStashCore

public struct GeneralTab: View {
    @ObservedObject var appState: AppState
    @StateObject private var permissions = SystemPermissionService.shared
    @State private var showingResetAlert: Bool = false

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            GroupBox(label: Label(appState.localized("general.masterControls"), systemImage: "power")) {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle(appState.localized("general.enableMacStash"), isOn: $appState.isEnabled)
                        .font(.system(size: 13, weight: .semibold))

                    Divider()

                    Toggle(appState.localized("general.showMenuBarIcon"), isOn: $appState.settings.showMenuBarIcon)

                    Toggle(appState.localized("general.launchAtLogin"), isOn: Binding(
                        get: { permissions.isLaunchAtLoginEnabled },
                        set: { val in
                            _ = permissions.setLaunchAtLogin(val)
                            appState.settings.launchAtLogin = val
                        }
                    ))
                }
                .padding(8)
            }

            GroupBox(label: Label(appState.localized("general.languageLocale"), systemImage: "globe")) {
                VStack(alignment: .leading, spacing: 10) {
                    Picker(appState.localized("general.interfaceLanguage"), selection: $appState.settings.language) {
                        Text(appState.localized("general.systemDefault")).tag("system")
                        Text(appState.localized("general.vietnamese")).tag("vi")
                        Text(appState.localized("general.english")).tag("en")
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: 240)

                    Text(appState.localized("general.languageHint"))
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .padding(8)
            }

            GroupBox(label: Label(appState.localized("general.systemPermissions"), systemImage: "lock.shield")) {
                VStack(spacing: 12) {
                    permissionRow(
                        title: appState.localized("general.accessibility"),
                        description: appState.localized("general.accessibilityDesc"),
                        isGranted: permissions.isAccessibilityGranted,
                        onOpenSettings: { permissions.openAccessibilitySettings() }
                    )

                    Divider()

                    permissionRow(
                        title: appState.localized("general.inputMonitoring"),
                        description: appState.localized("general.inputMonitoringDesc"),
                        isGranted: permissions.isInputMonitoringGranted,
                        onOpenSettings: { permissions.openInputMonitoringSettings() }
                    )

                    Divider()

                    permissionRow(
                        title: appState.localized("general.notifications"),
                        description: appState.localized("general.notificationsDesc"),
                        isGranted: permissions.isNotificationGranted,
                        onOpenSettings: {
                            permissions.requestNotificationPermission()
                            permissions.openNotificationSettings()
                        }
                    )
                }
                .padding(8)
            }

            HStack {
                Spacer()
                Button(role: .destructive, action: { showingResetAlert = true }) {
                    Label(appState.localized("general.resetButton"), systemImage: "arrow.counterclockwise")
                }
                .confirmationDialog(
                    appState.localized("general.resetAlertTitle"),
                    isPresented: $showingResetAlert,
                    titleVisibility: .visible
                ) {
                    Button(appState.localized("general.resetConfirm"), role: .destructive) {
                        appState.resetToDefaults()
                    }
                    Button(appState.localized("general.cancel"), role: .cancel) {}
                } message: {
                    Text(appState.localized("general.resetAlertMessage"))
                }
            }
        }
        .onAppear {
            permissions.checkAllPermissions()
        }
        .onReceive(Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()) { _ in
            permissions.checkAllPermissions()
        }
    }

    private func permissionRow(
        title: String,
        description: String,
        isGranted: Bool,
        onOpenSettings: @escaping () -> Void
    ) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.system(size: 12, weight: .semibold))

                    if isGranted {
                        Text(appState.localized("general.granted"))
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.green)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.green.opacity(0.15)))
                    } else {
                        Text(appState.localized("general.notGranted"))
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.orange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.orange.opacity(0.15)))
                    }
                }
                Text(description)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(isGranted ? appState.localized("general.openSettings") : appState.localized("general.grantPermission")) {
                onOpenSettings()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
    }
}
