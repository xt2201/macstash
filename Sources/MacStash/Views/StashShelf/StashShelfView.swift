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

    private let shelfWidth: CGFloat = Defaults.StashShelf.defaultWidthPoints

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        let isVisible = appState.isEnabled && appState.settings.isStashShelfEnabled
        let isOpen = shelf.isShelfOpen || isTargeted

        ZStack(alignment: .leading) {
            if isVisible {
                // Shelf Content Container
                shelfContent
                    .frame(width: shelfWidth)
                    .offset(x: isOpen ? 0 : -(shelfWidth + 20))
                    .opacity(isOpen ? 1.0 : 0.0)
                    .animation(.spring(response: 0.32, dampingFraction: 0.76), value: isOpen)

                // Invisible touch sensor strip along screen edge (14pt)
                Color.clear
                    .frame(width: 14)
                    .contentShape(Rectangle())
                    .onHover { hovering in
                        if hovering && !shelf.isShelfOpen {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                                shelf.isShelfOpen = true
                            }
                        }
                    }
            }
        }
        .frame(width: isOpen ? (shelfWidth + 10) : 14, alignment: .leading)
        .onDrop(of: [.fileURL, .utf8PlainText, .url], isTargeted: $isTargeted) { providers in
            handleDrop(providers: providers)
        }
    }

    @ViewBuilder
    private var shelfContent: some View {
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
        .frame(width: shelfWidth, height: 460)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.32), radius: 16, x: 4, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: isTargeted
                            ? [Color.cyan, Color.blue]
                            : [Color.white.opacity(0.25), Color.white.opacity(0.06)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: isTargeted ? 2.0 : 1.0
                )
        )
        .padding(.leading, 6)
    }

    private var headerBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "tray.2.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.cyan)

            Text("STASH SHELF")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            if !shelf.items.isEmpty {
                Text("\(shelf.items.count)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.cyan.opacity(0.7)))
            }

            Spacer()

            if !shelf.items.isEmpty {
                Button(action: { shelf.clearAll() }) {
                    Image(systemName: "trash")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .help("Clear All")
            }

            Button(action: {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                    shelf.isShelfOpen = false
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary.opacity(0.8))
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .help("Close Shelf")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private var emptyDropZone: some View {
        VStack(spacing: 12) {
            Spacer()

            Image(systemName: isTargeted ? "arrow.down.circle.fill" : "arrow.down.doc")
                .font(.system(size: 32, weight: .light))
                .foregroundColor(isTargeted ? .cyan : .secondary.opacity(0.6))
                .scaleEffect(isTargeted ? 1.15 : 1.0)
                .animation(.spring(response: 0.25, dampingFraction: 0.65), value: isTargeted)

            Text(isTargeted ? "Drop Here to Stash" : "Drop Files or Text Here")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)

            Text("Hold items while switching apps & spaces")
                .font(.system(size: 10))
                .foregroundColor(.secondary.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(16)
    }

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

    private func stashItemCard(item: StashItem) -> some View {
        let isHovered = hoveredItemID == item.id

        return HStack(spacing: 8) {
            // File or Item Icon
            itemIconView(for: item)
                .frame(width: 30, height: 30)

            // Titles
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
                            .font(.system(size: 9))
                            .foregroundColor(.cyan)
                    }
                }
            }

            Spacer()

            // Quick actions on hover
            if isHovered {
                HStack(spacing: 2) {
                    if item.isExistingFile {
                        Button(action: { shelf.revealInFinder(id: item.id) }) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.secondary)
                                .frame(width: 20, height: 20)
                        }
                        .buttonStyle(.plain)
                        .help("Reveal in Finder")

                        Button(action: { shelf.copyPathToClipboard(id: item.id) }) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.secondary)
                                .frame(width: 20, height: 20)
                        }
                        .buttonStyle(.plain)
                        .help("Copy Path")
                    }

                    Button(action: { shelf.removeItem(id: item.id) }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.secondary)
                            .frame(width: 20, height: 20)
                    }
                    .buttonStyle(.plain)
                    .help("Remove")
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isHovered ? Color.white.opacity(0.12) : Color.white.opacity(0.05))
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            hoveredItemID = hovering ? item.id : nil
        }
        .onDrag {
            shelf.createItemProvider(for: item)
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
                    .font(.system(size: 14))
                    .foregroundColor(.cyan)
            }
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        var didHandle = false
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier("public.file-url") {
                provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, _ in
                    if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                        Task { @MainActor in
                            shelf.addFileURLs([url])
                        }
                    } else if let url = item as? URL {
                        Task { @MainActor in
                            shelf.addFileURLs([url])
                        }
                    }
                }
                didHandle = true
            } else if provider.hasItemConformingToTypeIdentifier("public.utf8-plain-text") {
                provider.loadItem(forTypeIdentifier: "public.utf8-plain-text", options: nil) { item, _ in
                    if let str = item as? String {
                        Task { @MainActor in
                            shelf.addTextSnippet(str)
                        }
                    } else if let data = item as? Data, let str = String(data: data, encoding: .utf8) {
                        Task { @MainActor in
                            shelf.addTextSnippet(str)
                        }
                    }
                }
                didHandle = true
            }
        }
        return didHandle
    }
}
