import AppKit
import ApplicationServices
import os.log

/// Reads live notification badge labels from macOS Dock items via Accessibility (no private APIs).
@MainActor
public final class DockBadgeMonitor {
    private static let logger = Logger(subsystem: "com.macstash.app", category: "dockbadges")
    private var timer: Timer?
    private var onUpdate: (([String: String]) -> Void)?
    private var isPaused: Bool = true

    public init() {}

    public func start(onUpdate: @escaping ([String: String]) -> Void) {
        self.onUpdate = onUpdate
        isPaused = false
        timer?.invalidate()
        refreshNow()
        timer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshNow()
            }
        }
    }

    public func stop() {
        isPaused = true
        timer?.invalidate()
        timer = nil
    }

    public func refreshNow() {
        guard !isPaused, AXIsProcessTrusted() else { return }
        Task.detached(priority: .utility) {
            let result = Self.readDockBadgesOffMain()
            await MainActor.run {
                self.onUpdate?(result)
            }
        }
    }

    private nonisolated static func readDockBadgesOffMain() -> [String: String] {
        guard let dockApp = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.dock").first else {
            return [:]
        }
        let dockAX = AXUIElementCreateApplication(dockApp.processIdentifier)
        var childrenVal: CFTypeRef?
        guard AXUIElementCopyAttributeValue(dockAX, kAXChildrenAttribute as CFString, &childrenVal) == .success,
              let lists = childrenVal as? [AXUIElement] else {
            return [:]
        }

        // Build fast lookup from running/known app display names -> bundleID
        var nameToBundleID: [String: String] = [:]
        for app in NSWorkspace.shared.runningApplications {
            if let name = app.localizedName, let bid = app.bundleIdentifier {
                nameToBundleID[name] = bid
            }
        }

        var badges: [String: String] = [:]
        for listElement in lists {
            var listChildren: CFTypeRef?
            guard AXUIElementCopyAttributeValue(listElement, kAXChildrenAttribute as CFString, &listChildren) == .success,
                  let items = listChildren as? [AXUIElement] else {
                continue
            }

            for item in items {
                var statusVal: CFTypeRef?
                guard AXUIElementCopyAttributeValue(item, "AXStatusLabel" as CFString, &statusVal) == .success,
                      let statusStr = statusVal as? String,
                      !statusStr.isEmpty else {
                    continue
                }

                var urlVal: CFTypeRef?
                if AXUIElementCopyAttributeValue(item, kAXURLAttribute as CFString, &urlVal) == .success,
                   let appURL = urlVal as? URL,
                   let bundle = Bundle(url: appURL),
                   let bid = bundle.bundleIdentifier {
                    badges[bid] = statusStr
                    continue
                }

                var titleVal: CFTypeRef?
                if AXUIElementCopyAttributeValue(item, kAXTitleAttribute as CFString, &titleVal) == .success,
                   let title = titleVal as? String,
                   let bid = nameToBundleID[title] {
                    badges[bid] = statusStr
                }
            }
        }
        return badges
    }
}
