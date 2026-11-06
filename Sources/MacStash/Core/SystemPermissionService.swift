import AppKit
import ServiceManagement
import UserNotifications
import MacStashCore

@MainActor
public final class SystemPermissionService: ObservableObject {
    public static let shared = SystemPermissionService()

    @Published public private(set) var isAccessibilityGranted: Bool = false
    @Published public private(set) var isInputMonitoringGranted: Bool = false
    @Published public private(set) var isNotificationGranted: Bool = false
    @Published public private(set) var isLaunchAtLoginEnabled: Bool = false

    private init() {
        checkAllPermissions()
    }

    public func checkAllPermissions() {
        checkAccessibility()
        checkInputMonitoring()
        checkNotificationPermission()
        checkLaunchAtLogin()
    }

    public func checkAccessibility() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        isAccessibilityGranted = AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    public func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    public func checkInputMonitoring() {
        if #available(macOS 10.15, *) {
            isInputMonitoringGranted = CGPreflightListenEventAccess()
        } else {
            isInputMonitoringGranted = true
        }
    }

    public func openInputMonitoringSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent") {
            NSWorkspace.shared.open(url)
        }
    }

    public func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            Task { @MainActor [weak self] in
                self?.isNotificationGranted = (settings.authorizationStatus == .authorized)
            }
        }
    }

    public func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            Task { @MainActor [weak self] in
                self?.isNotificationGranted = granted
                if let err = error {
                    AppLogger.settings.error("Notification authorization request failed: \(err.localizedDescription)")
                } else {
                    AppLogger.settings.info("Notification authorization granted: \(granted)")
                }
            }
        }
    }

    public func openNotificationSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
            NSWorkspace.shared.open(url)
        }
    }

    public func checkLaunchAtLogin() {
        if #available(macOS 13.0, *) {
            isLaunchAtLoginEnabled = (SMAppService.mainApp.status == .enabled)
        } else {
            isLaunchAtLoginEnabled = false
        }
    }

    public func setLaunchAtLogin(_ enabled: Bool) -> Bool {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
                checkLaunchAtLogin()
                return true
            } catch {
                AppLogger.settings.error("Failed to update launch at login: \(error.localizedDescription)")
                checkLaunchAtLogin()
                return false
            }
        }
        return false
    }
}
