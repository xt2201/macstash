import AppKit
import Foundation

/// Thread-safe, in-memory icon cache for Stash Shelf items.
/// Prevents synchronous LaunchServices disk I/O and repeated icon decodes during SwiftUI view passes.
@MainActor
public final class StashIconCache {
    public static let shared = StashIconCache()

    private let cache = NSCache<NSURL, NSImage>()

    private init() {
        cache.countLimit = 120
    }

    public func icon(for url: URL) -> NSImage {
        let nsURL = url as NSURL
        if let cached = cache.object(forKey: nsURL) {
            return cached
        }

        let rawIcon = NSWorkspace.shared.icon(forFile: url.path)
        let targetSize = NSSize(width: 32, height: 32)
        let scaledImage = NSImage(size: targetSize)

        scaledImage.lockFocus()
        rawIcon.draw(in: NSRect(origin: .zero, size: targetSize),
                     from: NSRect(origin: .zero, size: rawIcon.size),
                     operation: .copy,
                     fraction: 1.0)
        scaledImage.unlockFocus()

        cache.setObject(scaledImage, forKey: nsURL)
        return scaledImage
    }

    public func clear() {
        cache.removeAllObjects()
    }
}
