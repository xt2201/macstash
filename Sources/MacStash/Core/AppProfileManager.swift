import AppKit
import Foundation
import Combine

/// Tracks active frontmost macOS application and manages context-aware profile switching
@MainActor
public final class AppProfileManager: ObservableObject {
    public static let shared = AppProfileManager()

    @Published public private(set) var currentAppName: String = "Finder"
    @Published public private(set) var currentBundleId: String = "com.apple.finder"

    private var cancellables = Set<AnyCancellable>()

    private init() {
        observeFrontmostApp()
        updateFrontmostApp()
    }

    private func observeFrontmostApp() {
        NSWorkspace.shared.notificationCenter
            .publisher(for: NSWorkspace.didActivateApplicationNotification)
            .sink { [weak self] notification in
                if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
                    self?.handleAppChange(app: app)
                }
            }
            .store(in: &cancellables)
    }

    private func updateFrontmostApp() {
        if let app = NSWorkspace.shared.frontmostApplication {
            handleAppChange(app: app)
        }
    }

    private func handleAppChange(app: NSRunningApplication) {
        let name = app.localizedName ?? "Unknown"
        let bundleId = app.bundleIdentifier ?? ""

        // Ignore our own app
        if bundleId == Bundle.main.bundleIdentifier {
            return
        }

        DispatchQueue.main.async {
            self.currentAppName = name
            self.currentBundleId = bundleId
        }
    }
}
