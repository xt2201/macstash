import AppKit
import Foundation

/// Fast in-memory icon cache for application bundles and file system paths.
/// Eliminates blocking synchronous LaunchServices lookups inside SwiftUI View.body.
@MainActor
public final class AppIconCache {
    public static let shared = AppIconCache()

    private let pathCache = NSCache<NSString, NSImage>()
    private let bundleCache = NSCache<NSString, NSImage>()

    private init() {
        pathCache.countLimit = 160
        bundleCache.countLimit = 160
    }

    public func icon(forPath path: String, targetSize: NSSize = NSSize(width: 36, height: 36)) -> NSImage {
        let key = NSString(string: "\(path)#\(Int(targetSize.width))")
        if let cached = pathCache.object(forKey: key) {
            return cached
        }

        let icon = NSWorkspace.shared.icon(forFile: path)
        icon.size = targetSize
        pathCache.setObject(icon, forKey: key)
        return icon
    }

    public func icon(forBundleID bundleID: String, targetSize: NSSize = NSSize(width: 36, height: 36)) -> NSImage? {
        let key = NSString(string: "\(bundleID)#\(Int(targetSize.width))")
        if let cached = bundleCache.object(forKey: key) {
            return cached
        }

        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            return nil
        }
        let icon = NSWorkspace.shared.icon(forFile: appURL.path)
        icon.size = targetSize
        bundleCache.setObject(icon, forKey: key)
        return icon
    }

    public func clear() {
        pathCache.removeAllObjects()
        bundleCache.removeAllObjects()
    }
}
