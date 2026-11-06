import AppKit
import Foundation
import Combine

/// Manages macOS System Appearance (Dark Mode vs Light Mode)
@MainActor
public final class AppearanceManager: ObservableObject {
    public static let shared = AppearanceManager()

    @Published public private(set) var isDarkMode: Bool = false

    private init() {
        checkCurrentAppearance()
        observeSystemThemeChanges()
    }

    public func checkCurrentAppearance() {
        let isDark = NSApp?.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        DispatchQueue.main.async {
            self.isDarkMode = isDark
        }
    }

    public func toggleAppearance() {
        let scriptSource = """
        tell application "System Events"
            tell appearance preferences
                set dark mode to not dark mode
            end tell
        end tell
        """
        runAppleScript(scriptSource)
    }

    public func setDarkMode(_ enable: Bool) {
        let scriptSource = """
        tell application "System Events"
            tell appearance preferences
                set dark mode to \(enable ? "true" : "false")
            end tell
        end tell
        """
        runAppleScript(scriptSource)
    }

    private func runAppleScript(_ source: String) {
        DispatchQueue.global(qos: .userInitiated).async {
            if let script = NSAppleScript(source: source) {
                var error: NSDictionary?
                script.executeAndReturnError(&error)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.checkCurrentAppearance()
                }
            }
        }
    }

    private func observeSystemThemeChanges() {
        DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("AppleInterfaceThemeChangedNotification"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.checkCurrentAppearance()
            }
        }
    }
}
