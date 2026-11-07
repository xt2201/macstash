import SwiftUI
import AppKit
import MacStashCore

/// Tactile Drop Shelf view that slides out from the screen edge to temporarily hold
/// files, images, URLs, and text snippets when dragging across spaces, displays, or apps.
public struct StashShelfView: View {
    @ObservedObject var appState: AppState
    @ObservedObject private var shelf = StashShelfManager.shared

    @State private var isTargeted: Bool = false
    @State private var hoveredItemID: UUID? = nil
    @State private var copyFeedback: Bool = false

    private let shelfWidth: CGFloat = Defaults.StashShelf.defaultWidthPoints

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        VStack(spacing: 0) {
            // 1. Header Bar
            headerBar

            Divider()
                .background(Color.white.opacity(0.12))

            // 2. Body List / Drop Zone
            if shelf.items.isEmpty {
                emptyDropZone
            } else {
                itemsListView
            }
        }
        .frame(width: shelfWidth, height: 470)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.35), radius: 20, x: 4, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: (isTargeted || shelf.isDropTargetActive)
                            ? [Color.cyan, Color.blue]
                            : [Color.white.opacity(0.25), Color.white.opacity(0.06)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: (isTargeted || shelf.isDropTargetActive) ? 2.0 : 1.0
                )
        )
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "tray.2.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.cyan)

            Text("STASH SHELF")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            if !shelf.items.isEmpty {
                HStack(spacing: 4) {
                    Text("\(shelf.items.count)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1.5)
                        .background(Capsule().fill(Color.cyan))

                    if !shelf.totalFormattedSize.isEmpty {
                        Text(shelf.totalFormattedSize)
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            if !shelf.items.isEmpty {
                // Copy All Button
                Button(action: {
                    shelf.copyAllFilesToClipboard()
                    withAnimation(.easeInOut(duration: 0.15)) { copyFeedback = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        withAnimation(.easeInOut(duration: 0.15)) { copyFeedback = false }
                    }
                }) {
                    Image(systemName: copyFeedback ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(copyFeedback ? .green : .secondary)
                        .frame(width: 24, height: 24)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(Color.white.opacity(0.08))
                        )
                }
                .buttonStyle(.plain)
                .help("Copy All to Clipboard")

                // Clear All Button
                Button(action: {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        shelf.clearAll()
                    }
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(width: 24, height: 24)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(Color.white.opacity(0.08))
                        )
                }
                .buttonStyle(.plain)
                .help("Clear Shelf")
            }

            // Close Shelf Button
            Button(action: {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                    shelf.closeShelf()
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary.opacity(0.8))
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .help("Close Shelf (Esc)")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    // MARK: - Empty Drop Zone

    private var emptyDropZone: some View {
        VStack(spacing: 12) {
            Spacer()

            ZStack {
                Circle()
                    .stroke(
                        Color.cyan.opacity(shelf.isDropTargetActive ? 0.8 : 0.25),
                        style: StrokeStyle(lineWidth: 1.5, dash: [4, 4])
                    )
                    .frame(width: 64, height: 64)

                Image(systemName: shelf.isDropTargetActive ? "arrow.down.circle.fill" : "arrow.down.doc")
                    .font(.system(size: 26, weight: .light))
                    .foregroundColor(shelf.isDropTargetActive ? .cyan : .secondary.opacity(0.7))
                    .scaleEffect(shelf.isDropTargetActive ? 1.15 : 1.0)
                    .animation(.spring(response: 0.25, dampingFraction: 0.65), value: shelf.isDropTargetActive)
            }

            VStack(spacing: 4) {
                Text(shelf.isDropTargetActive ? "Release to Stash" : "Drop Files or Text Here")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.primary)

                Text("Wiggle mouse while dragging to summon\nPress Esc to dismiss")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(16)
    }

    // MARK: - Items List View

    private var itemsListView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 6) {
                ForEach(shelf.items) { item in
                    stashItemCard(item: item)
                }
            }
            .padding(10)
        }
    }

    // MARK: - Stash Item Card (Clean Separation of Drag vs Button Hit Areas)

    private func stashItemCard(item: StashItem) -> some View {
        let isHovered = hoveredItemID == item.id

        return HStack(spacing: 8) {
            // Draggable Section: Grip Handle + Icon + Metadata
            // Keeping .onDrag exclusively on this sub-view allows trailing action buttons to receive clicks freely!
            HStack(spacing: 8) {
                // Drag Grip
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary.opacity(0.6))
                    .frame(width: 12)

                // Item Icon
                itemIconView(for: item)
                    .frame(width: 28, height: 28)

                // Title & Details
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    HStack(spacing: 4) {
                        if !item.formattedSize.isEmpty {
                            Text(item.formattedSize)
                                .font(.system(size: 9, weight: .medium, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                        if item.itemType == .url {
                            Text("Link")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(.cyan)
                        } else if let ext = item.sourceURL?.pathExtension.uppercased(), !ext.isEmpty {
                            Text(ext)
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundColor(.secondary.opacity(0.8))
                                .padding(.horizontal, 3)
                                .padding(.vertical, 0.5)
                                .background(RoundedRectangle(cornerRadius: 3).fill(Color.white.opacity(0.1)))
                        }
                    }
                }
            }
            .contentShape(Rectangle())
            .onDrag {
                shelf.createItemProvider(for: item)
            }

            Spacer()

            // Isolated Trailing Action Buttons (NOT wrapped in .onDrag to ensure 100% reliable clicks)
            HStack(spacing: 4) {
                if item.isExistingFile {
                    Button(action: {
                        shelf.revealInFinder(id: item.id)
                    }) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                            .frame(width: 22, height: 22)
                            .background(
                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                    .fill(Color.white.opacity(0.08))
                            )
                    }
                    .buttonStyle(.plain)
                    .help("Reveal in Finder")

                    Button(action: {
                        shelf.copyPathToClipboard(id: item.id)
                    }) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                            .frame(width: 22, height: 22)
                            .background(
                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                    .fill(Color.white.opacity(0.08))
                            )
                    }
                    .buttonStyle(.plain)
                    .help("Copy Path")
                }

                Button(action: {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                        shelf.removeItem(id: item.id)
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.secondary)
                        .frame(width: 22, height: 22)
                        .background(
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(Color.white.opacity(0.08))
                        )
                }
                .buttonStyle(.plain)
                .help("Remove")
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isHovered ? Color.white.opacity(0.12) : Color.white.opacity(0.05))
        )
        .onHover { hovering in
            hoveredItemID = hovering ? item.id : nil
        }
    }

    @ViewBuilder
    private func itemIconView(for item: StashItem) -> some View {
        if let url = item.sourceURL, item.isExistingFile {
            let icon = NSWorkspace.shared.icon(forFile: url.path)
            Image(nsImage: icon)
                .resizable()
                .scaledToFit()
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.cyan.opacity(0.18))

                Image(systemName: item.itemType == .url ? "link" : (item.itemType == .image ? "photo" : "doc.text"))
                    .font(.system(size: 13))
                    .foregroundColor(.cyan)
            }
        }
    }
}
