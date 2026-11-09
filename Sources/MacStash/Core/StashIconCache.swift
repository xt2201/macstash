import AppKit
import Foundation

/// Thread-safe, in-memory icon cache for Stash Shelf items with high-DPI Retina support.
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

        // Render with 2x Retina backing store (64x64 pixels at 32x32 points)
        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: 64,
            pixelsHigh: 64,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .calibratedRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else {
            cache.setObject(rawIcon, forKey: nsURL)
            return rawIcon
        }
        rep.size = targetSize

        NSGraphicsContext.saveGraphicsState()
        let context = NSGraphicsContext(bitmapImageRep: rep)
        NSGraphicsContext.current = context
        context?.imageInterpolation = .high
        rawIcon.draw(
            in: NSRect(origin: .zero, size: targetSize),
            from: NSRect(origin: .zero, size: rawIcon.size),
            operation: .copy,
            fraction: 1.0
        )
        NSGraphicsContext.restoreGraphicsState()

        let scaledImage = NSImage(size: targetSize)
        scaledImage.addRepresentation(rep)
        cache.setObject(scaledImage, forKey: nsURL)
        return scaledImage
    }

    public func clear() {
        cache.removeAllObjects()
    }
}
