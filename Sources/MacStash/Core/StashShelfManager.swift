import Foundation
import AppKit
import Combine
import MacStashCore

/// Holds files, images, links and snippets temporarily on the Stash Shelf.
@MainActor
public final class StashShelfManager: ObservableObject {
    public static let shared = StashShelfManager()

    @Published public private(set) var items: [StashItem] = []
    @Published public var isShelfOpen: Bool = false
    @Published public var isDropTargetActive: Bool = false

    private init() {}

    public func addFileURLs(_ urls: [URL]) {
        var added = 0
        for url in urls where !items.contains(where: { $0.sourceURL == url }) {
            let size = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64) ?? 0
            let ext = url.pathExtension.lowercased()
            let isImage = ["png", "jpg", "jpeg", "webp", "gif", "heic", "tiff", "svg"].contains(ext)
            items.insert(
                StashItem(
                    title: url.lastPathComponent,
                    detailText: url.deletingLastPathComponent().path,
                    itemType: isImage ? .image : .file,
                    sourceURL: url,
                    fileSizeBytes: size
                ),
                at: 0
            )
            added += 1
        }
        if added > 0 {
            enforceCapacity()
            HapticManager.shared.performBoundaryClick()
            AppLogger.lifecycle.info("Stashed \(added) files on shelf")
        }
    }

    public func addTextSnippet(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let isURL = (trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://")) && URL(string: trimmed) != nil
        let title = isURL ? trimmed : String((trimmed.components(separatedBy: .newlines).first ?? trimmed).prefix(40))
        items.insert(
            StashItem(
                title: title,
                detailText: isURL ? "Web Link" : "Text Snippet",
                itemType: isURL ? .url : .text,
                sourceURL: isURL ? URL(string: trimmed) : nil,
                stringContent: trimmed
            ),
            at: 0
        )
        enforceCapacity()
        HapticManager.shared.performBoundaryClick()
    }

    public var totalSizeBytes: Int64 {
        items.reduce(0) { $0 + $1.fileSizeBytes }
    }

    public var totalFormattedSize: String {
        let bytes = totalSizeBytes
        guard bytes > 0 else { return "" }
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    public func openShelf() {
        isShelfOpen = true
        isDropTargetActive = true
        HapticManager.shared.performDetentTick()
    }

    public func closeShelf() {
        isShelfOpen = false
        isDropTargetActive = false
    }

    public func copyAllFilesToClipboard() {
        let urls = items.compactMap { $0.sourceURL }
        guard !urls.isEmpty else {
            // Fallback to text snippets if only snippets exist
            let texts = items.compactMap { $0.stringContent ?? $0.title }
            if !texts.isEmpty {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(texts.joined(separator: "\n"), forType: .string)
                HapticManager.shared.performDetentTick()
            }
            return
        }

        NSPasteboard.general.clearContents()
        NSPasteboard.general.writeObjects(urls as [NSURL])
        HapticManager.shared.performDetentTick()
    }

    public func removeItem(id: UUID) {
        items.removeAll { $0.id == id }
        HapticManager.shared.performDetentTick()
    }

    public func clearAll() {
        items.removeAll()
        HapticManager.shared.performBoundaryClick()
    }

    public func copyPathToClipboard(id: UUID) {
        guard let url = items.first(where: { $0.id == id })?.sourceURL else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(url.path, forType: .string)
        HapticManager.shared.performDetentTick()
    }

    public func revealInFinder(id: UUID) {
        guard let url = items.first(where: { $0.id == id })?.sourceURL else { return }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    public func openItem(id: UUID) {
        guard let item = items.first(where: { $0.id == id }) else { return }
        if let url = item.sourceURL, item.isExistingFile {
            NSWorkspace.shared.open(url)
            HapticManager.shared.performDetentTick()
        } else if item.itemType == .url, let url = item.sourceURL {
            NSWorkspace.shared.open(url)
            HapticManager.shared.performDetentTick()
        } else if let text = item.stringContent {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)
            HapticManager.shared.performDetentTick()
        }
    }

    public func createItemProvider(for item: StashItem) -> NSItemProvider {
        if let url = item.sourceURL, item.itemType == .file || item.itemType == .image {
            return NSItemProvider(contentsOf: url) ?? NSItemProvider(object: url as NSURL)
        }
        if let text = item.stringContent {
            return NSItemProvider(object: text as NSString)
        }
        return NSItemProvider(object: item.title as NSString)
    }

    private func enforceCapacity() {
        if items.count > Defaults.StashShelf.maxItems {
            items = Array(items.prefix(Defaults.StashShelf.maxItems))
        }
    }
}
