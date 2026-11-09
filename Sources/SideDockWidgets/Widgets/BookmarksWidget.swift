import SwiftUI
import AppKit
import SideDockCore

public struct BookmarkItem: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var title: String
    public var urlString: String
    public var systemIcon: String

    public init(id: UUID = UUID(), title: String, urlString: String, systemIcon: String = "link") {
        self.id = id
        self.title = title
        self.urlString = urlString
        self.systemIcon = systemIcon
    }
}

public struct BookmarksConfig: Codable, Equatable, Sendable {
    public var bookmarks: [BookmarkItem]

    public init(bookmarks: [BookmarkItem] = [
        BookmarkItem(title: "GitHub", urlString: "https://github.com", systemIcon: "chevron.left.forwardslash.chevron.right"),
        BookmarkItem(title: "Google", urlString: "https://google.com", systemIcon: "globe"),
        BookmarkItem(title: "YouTube", urlString: "https://youtube.com", systemIcon: "play.rectangle.fill")
    ]) {
        self.bookmarks = bookmarks
    }
}

public struct BookmarksWidgetView: View {
    public let config: BookmarksConfig
    public let size: WidgetSize

    public init(config: BookmarksConfig = BookmarksConfig(), size: WidgetSize = .medium) {
        self.config = config
        self.size = size
    }

    public var body: some View {
        Group {
            switch size {
            case .small:
                smallView
            case .medium, .large:
                mediumView
            }
        }
    }

    private var smallView: some View {
        Menu {
            ForEach(config.bookmarks) { b in
                Button {
                    openBookmark(b)
                } label: {
                    Label(b.title, systemImage: b.systemIcon)
                }
            }
        } label: {
            VStack(spacing: 2) {
                Image(systemName: "bookmark.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.accentColor)
                Text("\(config.bookmarks.count) links")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
            }
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
        }
        .menuStyle(.borderlessButton)
        .help("Quick Bookmarks")
    }

    private var mediumView: some View {
        HStack(spacing: 4) {
            ForEach(config.bookmarks.prefix(3)) { b in
                Button {
                    openBookmark(b)
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: b.systemIcon)
                            .font(.system(size: 12))
                        Text(b.title)
                            .font(.system(size: 8))
                            .lineLimit(1)
                    }
                    .frame(width: 38, height: 38)
                    .background(RoundedRectangle(cornerRadius: 4).fill(Color.primary.opacity(0.06)))
                }
                .buttonStyle(.plain)
                .help(b.urlString)
            }
        }
        .padding(.horizontal, 4)
        .frame(height: 44)
    }

    private func openBookmark(_ bookmark: BookmarkItem) {
        if let url = URL(string: bookmark.urlString) {
            NSWorkspace.shared.open(url)
        }
    }
}
