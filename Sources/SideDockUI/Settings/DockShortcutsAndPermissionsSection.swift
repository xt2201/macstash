import SwiftUI
import AppKit
import ApplicationServices
import EventKit
import SideDockCore
import MacStashCore

public struct DockShortcutsAndPermissionsSection: View {
    @Binding public var config: SideDockFileConfig
    public let onSave: (Bool) -> Void

    @State private var hasAccessibility: Bool = AXIsProcessTrusted()
    @State private var hasScreenRecording: Bool = CGPreflightScreenCaptureAccess()
    @State private var hasCalendar: Bool = EKEventStore.authorizationStatus(for: .event) == .fullAccess
    @State private var hasReminders: Bool = EKEventStore.authorizationStatus(for: .reminder) == .fullAccess

    public init(config: Binding<SideDockFileConfig>, onSave: @escaping (Bool) -> Void) {
        self._config = config
        self.onSave = onSave
    }

    private func localized(_ key: String) -> String {
        LocalizationService.shared.localized(key)
    }

    public var body: some View {
        DockSettingsCard(title: localized("dock.launchpadAndPermissionsTitle"), systemImage: "square.grid.3x3.fill", accent: .orange) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(localized("dock.launchpadColumns")).font(.system(size: 12, weight: .medium))
                    Spacer()
                    Text("\(config.launchpadLayout.columns)")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                }
                Slider(
                    value: Binding(
                        get: { Double(config.launchpadLayout.columns) },
                        set: { config.launchpadLayout.columns = Int($0); onSave(false) }
                    ),
                    in: 4...10,
                    step: 1
                )
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(localized("dock.launchpadIconSize")).font(.system(size: 12, weight: .medium))
                    Spacer()
                    Text("\(Int(config.launchpadLayout.iconSize)) px")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                }
                Slider(value: $config.launchpadLayout.iconSize, in: 48...104, step: 4)
                    .onChange(of: config.launchpadLayout.iconSize) { _, _ in onSave(false) }
            }

            Divider()

            shortcutRow(
                label: localized("dock.shortcutToggleDock"),
                value: "Control + Option + D"
            )

            HStack {
                Text(localized("dock.shortcutLaunchpad")).font(.system(size: 12, weight: .medium))
                Spacer()
                Picker("", selection: $config.launchpadShortcut) {
                    Text("Control + Option + L").tag("ctrl+opt+l")
                    Text("Option + Space").tag("opt+space")
                    Text("Control + Shift + L").tag("ctrl+shift+l")
                }
                .pickerStyle(.menu)
                .frame(minWidth: 165, maxWidth: 215)
                .onChange(of: config.launchpadShortcut) { _, _ in onSave(true) }
            }

            HStack {
                Text(localized("dock.shortcutWindowSwitcher")).font(.system(size: 12, weight: .medium))
                Spacer()
                Picker("", selection: $config.windowSwitcherShortcut) {
                    Text("Option + Tab").tag("opt+tab")
                    Text("Control + Tab").tag("ctrl+tab")
                    Text("Option + Grave (`)").tag("opt+`")
                }
                .pickerStyle(.menu)
                .frame(minWidth: 165, maxWidth: 215)
                .onChange(of: config.windowSwitcherShortcut) { _, _ in onSave(true) }
            }

            Divider()

            HStack {
                Text(localized("dock.permissionsStatus"))
                    .font(.system(size: 12, weight: .semibold))
                Spacer()
                Button {
                    refreshPermissions()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
            }

            permissionRow(
                title: "Accessibility (Badges, Window Actions, Reserve Space)",
                granted: hasAccessibility,
                settingsURL: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
            )
            permissionRow(
                title: "Screen Recording (Live Window Thumbnails)",
                granted: hasScreenRecording,
                settingsURL: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
            )
            permissionRow(
                title: "Calendar (Calendar Widget)",
                granted: hasCalendar,
                settingsURL: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars"
            )
            permissionRow(
                title: "Reminders (Reminders Widget)",
                granted: hasReminders,
                settingsURL: "x-apple.systempreferences:com.apple.preference.security?Privacy_Reminders"
            )
        }
        .onAppear {
            refreshPermissions()
        }
    }

    private func shortcutRow(label: String, value: String) -> some View {
        HStack {
            Text(label).font(.system(size: 12, weight: .medium))
            Spacer()
            Text(value)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color.primary.opacity(0.06)))
        }
    }

    private func permissionRow(title: String, granted: Bool, settingsURL: String) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(granted ? Color.green : Color.orange)
                .frame(width: 7, height: 7)
            Text(title)
                .font(.system(size: 11.5))
                .lineLimit(1)
            Spacer()
            if !granted {
                Button(localized("dock.grantPermission")) {
                    if let url = URL(string: settingsURL) {
                        NSWorkspace.shared.open(url)
                    }
                }
                .controlSize(.mini)
                .buttonStyle(.bordered)
            } else {
                Text(localized("dock.granted"))
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundColor(.green)
            }
        }
    }

    private func refreshPermissions() {
        hasAccessibility = AXIsProcessTrusted()
        hasScreenRecording = CGPreflightScreenCaptureAccess()
        hasCalendar = EKEventStore.authorizationStatus(for: .event) == .fullAccess
        hasReminders = EKEventStore.authorizationStatus(for: .reminder) == .fullAccess
    }
}
