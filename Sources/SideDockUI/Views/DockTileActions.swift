import AppKit
import UniformTypeIdentifiers
import SideDockCore

private final class DroppedURLCollector: @unchecked Sendable {
    private let lock = NSLock()
    private var urls: [URL] = []

    func append(_ url: URL) {
        lock.lock()
        urls.append(url)
        lock.unlock()
    }

    func allURLs() -> [URL] {
        lock.lock()
        defer { lock.unlock() }
        return urls
    }
}

@MainActor
enum DockTileActions {
    static func launchApp(_ appItem: AppItem) {
        if FileManager.default.fileExists(atPath: appItem.appPath) {
            NSWorkspace.shared.open(URL(fileURLWithPath: appItem.appPath))
        } else if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: appItem.bundleIdentifier) {
            NSWorkspace.shared.open(url)
        }
    }

    static func showInFinder(_ appItem: AppItem) {
        if FileManager.default.fileExists(atPath: appItem.appPath) {
            NSWorkspace.shared.selectFile(appItem.appPath, inFileViewerRootedAtPath: "")
        }
    }

    static func hideApp(_ appItem: AppItem) {
        for app in NSRunningApplication.runningApplications(withBundleIdentifier: appItem.bundleIdentifier) {
            app.hide()
        }
    }

    static func quitApp(_ appItem: AppItem) {
        for app in NSRunningApplication.runningApplications(withBundleIdentifier: appItem.bundleIdentifier) {
            app.terminate()
        }
    }

    static func forceQuitApp(_ appItem: AppItem) {
        for app in NSRunningApplication.runningApplications(withBundleIdentifier: appItem.bundleIdentifier) {
            app.forceTerminate()
        }
    }

    static func pickCustomIcon(completion: @escaping @MainActor (URL) -> Void) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .icns, .jpeg, .tiff, .heic]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if panel.runModal() == .OK, let url = panel.url {
            completion(url)
        }
    }

    static func extractDroppedURLs(from providers: [NSItemProvider], completion: @escaping @MainActor ([URL]) -> Void) {
        let group = DispatchGroup()
        let collector = DroppedURLCollector()
        for provider in providers {
            group.enter()
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                if let url {
                    collector.append(url)
                }
                group.leave()
            }
        }
        group.notify(queue: .main) {
            MainActor.assumeIsolated {
                let collected = collector.allURLs()
                if !collected.isEmpty { completion(collected) }
            }
        }
    }
}
