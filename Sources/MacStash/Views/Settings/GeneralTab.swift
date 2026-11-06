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
            GroupBox(label: Label("Master Controls", systemImage: "power")) {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Enable MacStash Controls", isOn: $appState.isEnabled)
                        .font(.system(size: 13, weight: .semibold))

                    Divider()

                    Toggle("Show Icon in Menu Bar", isOn: $appState.settings.showMenuBarIcon)

                    Toggle("Launch at Login", isOn: Binding(
                        get: { permissions.isLaunchAtLoginEnabled },
                        set: { val in
                            _ = permissions.setLaunchAtLogin(val)
                            appState.settings.launchAtLogin = val
                        }
                    ))
                }
                .padding(8)
            }

            GroupBox(label: Label("Language & Locale", systemImage: "globe")) {
                VStack(alignment: .leading, spacing: 10) {
                    Picker("Interface Language", selection: $appState.settings.language) {
                        Text("System Default").tag("system")
                        Text("Tiếng Việt").tag("vi")
                        Text("English").tag("en")
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: 240)

                    Text("Changes apply dynamically to all labels and guides.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .padding(8)
            }

            GroupBox(label: Label("System Permissions", systemImage: "lock.shield")) {
                VStack(spacing: 12) {
                    permissionRow(
                        title: "Accessibility",
                        description: "Required to track cursor and trigger hot corners",
                        isGranted: permissions.isAccessibilityGranted,
                        onOpenSettings: { permissions.openAccessibilitySettings() }
                    )

                    Divider()

                    permissionRow(
                        title: "Input Monitoring",
                        description: "Required to detect hotkey combinations and wheel drags",
                        isGranted: permissions.isInputMonitoringGranted,
                        onOpenSettings: { permissions.openInputMonitoringSettings() }
                    )

                    Divider()

                    permissionRow(
                        title: "Notifications",
                        description: "Used for Pomodoro timer phase alerts",
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
                    Label("Reset All Settings to Defaults", systemImage: "arrow.counterclockwise")
                }
                .confirmationDialog(
                    "Reset All Settings?",
                    isPresented: $showingResetAlert,
                    titleVisibility: .visible
                ) {
                    Button("Reset to Defaults", role: .destructive) {
                        appState.resetToDefaults()
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This will restore hot corners, sensitivity, and appearance to default values.")
                }
            }
        }
        .onAppear {
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
                        Text("Granted")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.green)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.green.opacity(0.15)))
                    } else {
                        Text("Not Granted")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.red)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.red.opacity(0.15)))
                    }
                }
                Text(description)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button("Configure in Settings") {
                onOpenSettings()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
    }
}
