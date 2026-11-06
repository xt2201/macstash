import AppKit
import Foundation

/// Discovers installed applications on macOS for the Hidden Dock and Quick Launcher
public final class InstalledAppsManager: ObservableObject {
    public static let shared = InstalledAppsManager()

    @Published public private(set) var installedApps: [DockItem] = []
    @Published public private(set) var isLoading: Bool = false

    private init() {
        refreshApps()
    }

    public func refreshApps() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            var items: [DockItem] = []
            let searchDirs = [
                URL(fileURLWithPath: "/Applications"),
                URL(fileURLWithPath: "/System/Applications"),
                URL(fileURLWithPath: "/System/Applications/Utilities")
            ]

            let fileManager = FileManager.default

            for dir in searchDirs {
                guard let contents = try? fileManager.contentsOfDirectory(
                    at: dir,
                    includingPropertiesForKeys: [.isApplicationKey, .localizedNameKey],
                    options: [.skipsHiddenFiles]
                ) else { continue }

                for url in contents where url.pathExtension == "app" {
                    if let bundle = Bundle(url: url) {
                        let name = (bundle.infoDictionary?["CFBundleDisplayName"] as? String)
                            ?? (bundle.infoDictionary?["CFBundleName"] as? String)
                            ?? url.deletingPathExtension().lastPathComponent
                        let bundleId = bundle.bundleIdentifier ?? url.lastPathComponent

                        let item = DockItem(
                            name: name,
                            bundleIdentifier: bundleId,
                            appPath: url.path
                        )
                        if !items.contains(where: { $0.bundleIdentifier == bundleId }) {
                            items.append(item)
                        }
                    }
                }
            }

            items.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

            DispatchQueue.main.async {
                self.installedApps = items
                self.isLoading = false
            }
        }
    }

    /// Default starter dock items
    public static var defaultDockItems: [DockItem] {
        let defaults: [(name: String, bundleId: String, path: String)] = [
            ("Finder", "com.apple.finder", "/System/Library/CoreServices/Finder.app"),
            ("Safari", "com.apple.Safari", "/Applications/Safari.app"),
            ("Terminal", "com.apple.Terminal", "/System/Applications/Utilities/Terminal.app"),
            ("System Settings", "com.apple.systempreferences", "/System/Applications/System Settings.app"),
            ("Notes", "com.apple.Notes", "/System/Applications/Notes.app"),
            ("Calculator", "com.apple.calculator", "/System/Applications/Calculator.app")
        ]

        return defaults.compactMap { item in
            DockItem(
                name: item.name,
                bundleIdentifier: item.bundleId,
                appPath: item.path
            )
        }
    }
}
