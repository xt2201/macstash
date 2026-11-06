import Foundation

public enum StashItemType: String, Codable, Sendable {
    case file
    case image
    case text
    case url
}

/// Represents an item temporarily stashed on the screen edge drop shelf.
/// Supports files, images, links, and snippets dragged between apps or spaces.
public struct StashItem: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var title: String
    public var detailText: String
    public var itemType: StashItemType
    public var sourceURL: URL?
    public var stringContent: String?
    public var fileSizeBytes: Int64
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        title: String,
        detailText: String = "",
        itemType: StashItemType = .file,
        sourceURL: URL? = nil,
        stringContent: String? = nil,
        fileSizeBytes: Int64 = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.detailText = detailText
        self.itemType = itemType
        self.sourceURL = sourceURL
        self.stringContent = stringContent
        self.fileSizeBytes = fileSizeBytes
        self.createdAt = createdAt
    }

    public var formattedSize: String {
        guard fileSizeBytes > 0 else {
            if let str = stringContent, !str.isEmpty {
                return "\(str.count) chars"
            }
            return ""
        }
        let bcf = ByteCountFormatter()
        bcf.allowedUnits = [.useAll]
        bcf.countStyle = .file
        return bcf.string(fromByteCount: fileSizeBytes)
    }

    public var isExistingFile: Bool {
        guard let url = sourceURL else { return false }
        return FileManager.default.fileExists(atPath: url.path)
    }
}
