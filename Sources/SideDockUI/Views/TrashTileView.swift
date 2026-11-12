import SwiftUI
import AppKit
import SideDockCore
import MacStashCore

public struct TrashTileView: View {
    public let itemCount: Int
    public let tileSize: CGFloat
    public let onOpenTrash: () -> Void
    public let onEmptyTrash: () -> Void
    public let onDropFiles: ([URL]) -> Void
    public let onRemove: () -> Void

    @State private var isDropTargeted: Bool = false

    public init(
        itemCount: Int,
        tileSize: CGFloat,
        onOpenTrash: @escaping () -> Void,
        onEmptyTrash: @escaping () -> Void,
        onDropFiles: @escaping ([URL]) -> Void,
        onRemove: @escaping () -> Void
    ) {
        self.itemCount = itemCount
        self.tileSize = tileSize
        self.onOpenTrash = onOpenTrash
        self.onEmptyTrash = onEmptyTrash
        self.onDropFiles = onDropFiles
        self.onRemove = onRemove
    }

    private func localized(_ key: String) -> String {
        LocalizationService.shared.localized(key)
    }

    public var body: some View {
        Button {
            onOpenTrash()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(isDropTargeted ? Color.accentColor.opacity(0.22) : Color.primary.opacity(0.06))

                Image(systemName: itemCount > 0 ? "trash.fill" : "trash")
                    .font(.system(size: tileSize * 0.44, weight: .medium))
                    .foregroundStyle(itemCount > 0 ? Color.primary : Color.secondary)
            }
            .frame(width: tileSize, height: tileSize)
            .overlay(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .strokeBorder(isDropTargeted ? Color.accentColor : Color.primary.opacity(0.1), lineWidth: isDropTargeted ? 1.5 : 0.7)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
            DockTileActions.extractDroppedURLs(from: providers) { urls in
                onDropFiles(urls)
            }
            return true
        }
        .contextMenu {
            Button(localized("dock.openTrash")) {
                onOpenTrash()
            }
            if itemCount > 0 {
                Button(localized("dock.emptyTrash"), role: .destructive) {
                    onEmptyTrash()
                }
            }
            Divider()
            Button(localized("dock.remove")) {
                onRemove()
            }
        }
    }
}
