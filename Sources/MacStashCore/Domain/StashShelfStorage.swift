import Foundation

/// Fast local JSON persistence for the floating Stash Shelf drawer.
public final class StashShelfStorage: @unchecked Sendable {
    private let fileURL: URL
    private let fileManager: FileManager

    public init(fileURL: URL? = nil, fileManager: FileManager = .default) {
        self.fileManager = fileManager
        if let customURL = fileURL {
            self.fileURL = customURL
        } else {
            let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
                ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
            let stashDir = appSupport.appendingPathComponent("MacStash", isDirectory: true)
            self.fileURL = stashDir.appendingPathComponent("stash_items.json")
        }
    }

    public func load() -> [StashItem] {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return []
        }
        do {
            let data = try Data(contentsOf: fileURL)
            let items = try JSONDecoder().decode([StashItem].self, from: data)
            return items
        } catch {
            return []
        }
    }

    public func save(_ items: [StashItem]) {
        do {
            let dir = fileURL.deletingLastPathComponent()
            if !fileManager.fileExists(atPath: dir.path) {
                try fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
            }
            let data = try JSONEncoder().encode(items)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            // Silently ignore or log error
        }
    }

    public func clear() {
        try? fileManager.removeItem(at: fileURL)
    }
}
