import AppKit
import ApplicationServices
import ScreenCaptureKit
import os.log
import SideDockUI

public struct DockWindowInfo: Identifiable, Sendable {
    public var id: CGWindowID { windowID }
    public let windowID: CGWindowID
    public let pid: pid_t
    public let bundleIdentifier: String?
    public let appName: String
    public let title: String
    public let frame: CGRect
    public let isMinimized: Bool
    public let appPath: String?

    public init(
        windowID: CGWindowID,
        pid: pid_t,
        bundleIdentifier: String?,
        appName: String,
        title: String,
        frame: CGRect,
        isMinimized: Bool,
        appPath: String?
    ) {
        self.windowID = windowID
        self.pid = pid
        self.bundleIdentifier = bundleIdentifier
        self.appName = appName
        self.title = title
        self.frame = frame
        self.isMinimized = isMinimized
        self.appPath = appPath
    }
}

@MainActor
public final class WindowRegistryService {
    public static let shared = WindowRegistryService()
    private static let logger = Logger(subsystem: "com.macstash.app", category: "windows")

    private let thumbnailCache = NSCache<NSNumber, CachedThumbnail>()

    private final class CachedThumbnail: @unchecked Sendable {
        let image: NSImage
        let timestamp: TimeInterval
        init(image: NSImage, timestamp: TimeInterval) {
            self.image = image
            self.timestamp = timestamp
        }
    }

    public init() {
        thumbnailCache.countLimit = 48
    }

    public func windows(forBundleID bundleID: String? = nil) -> [DockWindowInfo] {
        let running = NSWorkspace.shared.runningApplications
        var appByPID: [pid_t: NSRunningApplication] = [:]
        for app in running where app.activationPolicy == .regular {
            appByPID[app.processIdentifier] = app
        }

        let options: CGWindowListOption = [.excludeDesktopElements]
        guard let rawList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return []
        }

        var results: [DockWindowInfo] = []
        let myPID = ProcessInfo.processInfo.processIdentifier

        for entry in rawList {
            guard let pid = entry[kCGWindowOwnerPID as String] as? pid_t,
                  pid != myPID,
                  let app = appByPID[pid],
                  let layer = entry[kCGWindowLayer as String] as? Int,
                  layer == 0,
                  let windowID = entry[kCGWindowNumber as String] as? CGWindowID else {
                continue
            }

            if let targetBID = bundleID, app.bundleIdentifier != targetBID {
                continue
            }

            var bounds = CGRect.zero
            if let boundsDict = entry[kCGWindowBounds as String] as? [String: Any],
               let parsed = CGRect(dictionaryRepresentation: boundsDict as CFDictionary) {
                bounds = parsed
            }
            guard bounds.width >= 60 && bounds.height >= 40 else { continue }

            let title = (entry[kCGWindowName as String] as? String) ?? ""
            let isOnScreen = (entry[kCGWindowIsOnscreen as String] as? Bool) ?? false

            results.append(DockWindowInfo(
                windowID: windowID,
                pid: pid,
                bundleIdentifier: app.bundleIdentifier,
                appName: app.localizedName ?? "App",
                title: title.isEmpty ? (app.localizedName ?? "Window") : title,
                frame: bounds,
                isMinimized: !isOnScreen,
                appPath: app.bundleURL?.path
            ))
        }

        return results
    }

    public func minimizedWindowSummaries() -> [MinimizedWindowSummary] {
        guard AXIsProcessTrusted() else { return [] }
        var summaries: [MinimizedWindowSummary] = []

        for app in NSWorkspace.shared.runningApplications where app.activationPolicy == .regular {
            let pid = app.processIdentifier
            let appAX = AXUIElementCreateApplication(pid)
            var windowsVal: CFTypeRef?
            guard AXUIElementCopyAttributeValue(appAX, kAXWindowsAttribute as CFString, &windowsVal) == .success,
                  let axWindows = windowsVal as? [AXUIElement] else {
                continue
            }

            for (idx, axWin) in axWindows.enumerated() {
                var minVal: CFTypeRef?
                guard AXUIElementCopyAttributeValue(axWin, kAXMinimizedAttribute as CFString, &minVal) == .success,
                      let isMin = minVal as? Bool, isMin else {
                    continue
                }
                var titleVal: CFTypeRef?
                let title = (AXUIElementCopyAttributeValue(axWin, kAXTitleAttribute as CFString, &titleVal) == .success ? (titleVal as? String) : nil) ?? ""

                summaries.append(MinimizedWindowSummary(
                    windowID: CGWindowID(idx + 1),
                    pid: pid,
                    bundleIdentifier: app.bundleIdentifier,
                    appName: app.localizedName ?? "App",
                    windowTitle: title,
                    appPath: app.bundleURL?.path
                ))
            }
        }
        return summaries
    }

    public func captureThumbnail(for window: DockWindowInfo, maxSize: CGSize = CGSize(width: 240, height: 150)) async -> NSImage? {
        let key = NSNumber(value: window.windowID)
        let now = ProcessInfo.processInfo.systemUptime
        if let cached = thumbnailCache.object(forKey: key), (now - cached.timestamp) < 1.5 {
            return cached.image
        }

        guard CGPreflightScreenCaptureAccess() else {
            return nil
        }

        do {
            let content = try await SCShareableContent.excludingDesktopWindows(true, onScreenWindowsOnly: false)
            guard let scWindow = content.windows.first(where: { $0.windowID == window.windowID }) else {
                return nil
            }
            let filter = SCContentFilter(desktopIndependentWindow: scWindow)
            let cfg = SCStreamConfiguration()
            let scale = min(maxSize.width / max(1, window.frame.width), maxSize.height / max(1, window.frame.height), 1.0)
            cfg.width = max(40, Int(window.frame.width * scale * 2.0))
            cfg.height = max(30, Int(window.frame.height * scale * 2.0))
            cfg.showsCursor = false

            let cgImage = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: cfg)
            let img = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width / 2, height: cgImage.height / 2))
            thumbnailCache.setObject(CachedThumbnail(image: img, timestamp: ProcessInfo.processInfo.systemUptime), forKey: key)
            return img
        } catch {
            Self.logger.debug("Window thumbnail capture skipped for \(window.windowID): \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    public func focusWindow(_ window: DockWindowInfo) {
        if let app = NSRunningApplication(processIdentifier: window.pid) {
            app.unhide()
            app.activate()
        }
        guard AXIsProcessTrusted(), let axWin = matchingAXWindow(for: window) else { return }
        AXUIElementSetAttributeValue(axWin, kAXMinimizedAttribute as CFString, kCFBooleanFalse)
        AXUIElementPerformAction(axWin, kAXRaiseAction as CFString)
    }

    public func restoreMinimizedWindow(_ summary: MinimizedWindowSummary) {
        if let app = NSRunningApplication(processIdentifier: summary.pid) {
            app.unhide()
            app.activate()
        }
        guard AXIsProcessTrusted() else { return }
        let appAX = AXUIElementCreateApplication(summary.pid)
        var windowsVal: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appAX, kAXWindowsAttribute as CFString, &windowsVal) == .success,
              let axWindows = windowsVal as? [AXUIElement] else {
            return
        }
        for axWin in axWindows {
            var minVal: CFTypeRef?
            if AXUIElementCopyAttributeValue(axWin, kAXMinimizedAttribute as CFString, &minVal) == .success,
               let isMin = minVal as? Bool, isMin {
                var titleVal: CFTypeRef?
                let title = (AXUIElementCopyAttributeValue(axWin, kAXTitleAttribute as CFString, &titleVal) == .success ? (titleVal as? String) : nil) ?? ""
                if summary.windowTitle.isEmpty || title == summary.windowTitle {
                    AXUIElementSetAttributeValue(axWin, kAXMinimizedAttribute as CFString, kCFBooleanFalse)
                    AXUIElementPerformAction(axWin, kAXRaiseAction as CFString)
                    return
                }
            }
        }
    }

    public func minimizeWindow(_ window: DockWindowInfo) {
        guard AXIsProcessTrusted(), let axWin = matchingAXWindow(for: window) else { return }
        AXUIElementSetAttributeValue(axWin, kAXMinimizedAttribute as CFString, kCFBooleanTrue)
    }

    public func closeWindow(_ window: DockWindowInfo) {
        guard AXIsProcessTrusted(), let axWin = matchingAXWindow(for: window) else { return }
        var closeBtnVal: CFTypeRef?
        guard AXUIElementCopyAttributeValue(axWin, kAXCloseButtonAttribute as CFString, &closeBtnVal) == .success,
              let btn = closeBtnVal,
              CFGetTypeID(btn) == AXUIElementGetTypeID() else {
            return
        }
        let closeBtn = unsafeBitCast(btn, to: AXUIElement.self)
        AXUIElementPerformAction(closeBtn, kAXPressAction as CFString)
    }

    private func matchingAXWindow(for window: DockWindowInfo) -> AXUIElement? {
        let appAX = AXUIElementCreateApplication(window.pid)
        var windowsVal: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appAX, kAXWindowsAttribute as CFString, &windowsVal) == .success,
              let axWindows = windowsVal as? [AXUIElement] else {
            return nil
        }

        for axWin in axWindows {
            var titleVal: CFTypeRef?
            if AXUIElementCopyAttributeValue(axWin, kAXTitleAttribute as CFString, &titleVal) == .success,
               let t = titleVal as? String,
               t == window.title {
                return axWin
            }
        }
        return axWindows.first
    }
}
