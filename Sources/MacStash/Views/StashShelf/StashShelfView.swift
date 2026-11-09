import SwiftUI
import AppKit
import MacStashCore

/// Tactile Drop Shelf view elevated with Apple Liquid Glass optical shading.
/// Slides out from the screen edge to temporarily hold files, images, URLs, and text snippets
/// with dynamic refraction, liquid drop ripples, and glass tile elevation.
public struct StashShelfView: View {
    @ObservedObject var appState: AppState
    @ObservedObject private var shelf = StashShelfManager.shared

    @State private var selectedItemID: UUID? = nil
    @State private var copyFeedback: Bool = false

    private let shelfWidth: CGFloat = Defaults.StashShelf.defaultWidthPoints

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        let isDropActive = shelf.isDropTargetActive

        VStack(spacing: 0) {
            // 1. Liquid Glass Header Bar
            headerBar

            Divider()
                .background(
                    LinearGradient(
                        colors: [Color.cyan.opacity(0.35), Color.white.opacity(0.06)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            // 2. Drop banner when dragging over existing items
            if isDropActive && !shelf.items.isEmpty {
                dropBanner
            }

            // 3. Body List / Drop Zone
            if shelf.items.isEmpty {
                emptyDropZone
            } else {
                itemsListView
            }
        }
        .frame(width: shelfWidth, height: 470)
        .liquidGlass(
            cornerRadius: 20,
            tint: isDropActive ? .cyan : .clear,
            specularIntensity: 1.15,
            causticOpacity: isDropActive ? 0.28 : 0.12,
            shadowRadius: 22,
            isHighlighted: isDropActive
        )
        .animation(.spring(response: 0.28, dampingFraction: 0.78), value: isDropActive)
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "tray.2.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.cyan)
                .shadow(color: Color.cyan.opacity(0.4), radius: 3, x: 0, y: 0)

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
                        .shadow(color: Color.cyan.opacity(0.4), radius: 4, x: 0, y: 1)

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
                        .frame(width: 26, height: 26)
                        .circularLiquidGlass(
                            tint: copyFeedback ? .green : .clear,
                            specularIntensity: 0.8,
                            causticOpacity: 0.2,
                            isHighlighted: copyFeedback
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
                        .frame(width: 26, height: 26)
                        .circularLiquidGlass(
                            tint: .clear,
                            specularIntensity: 0.8,
                            causticOpacity: 0.15
                        )
                }
                .buttonStyle(.plain)
                .help("Clear Shelf")
            } else if shelf.canUndoClear {
                // Undo Clear Button
                Button(action: {
                    shelf.undoClear()
                }) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.cyan)
                        .frame(width: 26, height: 26)
                        .circularLiquidGlass(
                            tint: .cyan,
                            specularIntensity: 0.8,
                            causticOpacity: 0.2,
                            isHighlighted: true
                        )
                }
                .buttonStyle(.plain)
                .help("Restore Cleared Items")
            }

            // Pin / Keep Open Toggle Button
            Button(action: {
                shelf.togglePin()
            }) {
                Image(systemName: shelf.isPinned ? "pin.fill" : "pin")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(shelf.isPinned ? .cyan : .secondary)
                    .frame(width: 26, height: 26)
                    .circularLiquidGlass(
                        tint: shelf.isPinned ? .cyan : .clear,
                        specularIntensity: 0.8,
                        causticOpacity: shelf.isPinned ? 0.25 : 0.15,
                        isHighlighted: shelf.isPinned
                    )
            }
            .buttonStyle(.plain)
            .help(shelf.isPinned ? "Unpin Shelf" : "Pin Shelf (Keep Open)")

            // Close Shelf Button
            Button(action: {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                    shelf.closeShelf()
                }
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
                    .frame(width: 26, height: 26)
                    .circularLiquidGlass(
                        tint: .clear,
                        specularIntensity: 0.8,
                        causticOpacity: 0.15
                    )
            }
            .buttonStyle(.plain)
            .help("Close Shelf (Esc)")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    // MARK: - Drop Target Banner (Visible when dragging over populated list)

    private var dropBanner: some View {
        HStack(spacing: 6) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.cyan)

            Text("Drop here to stash")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.cyan)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.cyan.opacity(0.18))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.cyan.opacity(0.55), lineWidth: 1.0)
        )
        .padding(.horizontal, 10)
        .padding(.top, 8)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - Empty Drop Zone (Liquid Ripple Aura)

    private var emptyDropZone: some View {
        let isDropActive = shelf.isDropTargetActive

        return VStack(spacing: 12) {
            Spacer()

            ZStack {
                // Expanding liquid ripple rings when drop is active
                if isDropActive {
                    Circle()
                        .stroke(Color.cyan.opacity(0.35), lineWidth: 2)
                        .frame(width: 84, height: 84)
                        .scaleEffect(1.1)
                }

                Circle()
                    .stroke(
                        LinearGradient(
                            colors: isDropActive
                                ? [Color.cyan, Color.blue]
                                : [Color.white.opacity(0.3), Color.white.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: isDropActive ? 2.0 : 1.5, dash: isDropActive ? [] : [4, 4])
                    )
                    .frame(width: 66, height: 66)
                    .background(
                        Circle()
                            .fill(isDropActive ? Color.cyan.opacity(0.15) : Color.white.opacity(0.03))
                    )
                    .shadow(color: isDropActive ? Color.cyan.opacity(0.5) : Color.clear, radius: 10, x: 0, y: 0)

                Image(systemName: isDropActive ? "arrow.down.circle.fill" : "arrow.down.doc")
                    .font(.system(size: 26, weight: .light))
                    .foregroundColor(isDropActive ? .cyan : .secondary.opacity(0.7))
                    .scaleEffect(isDropActive ? 1.15 : 1.0)
                    .animation(.spring(response: 0.25, dampingFraction: 0.65), value: isDropActive)
            }

            VStack(spacing: 4) {
                Text(isDropActive ? "Release to Stash" : "Drop Files or Text Here")
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
            VStack(spacing: 6) {
                ForEach(shelf.items) { item in
                    StashItemCardView(
                        item: item,
                        isSelected: selectedItemID == item.id,
                        onSelect: { selectedItemID = item.id },
                        onOpen: { shelf.openItem(id: item.id) },
                        onReveal: { shelf.revealInFinder(id: item.id) },
                        onCopyPath: { shelf.copyPathToClipboard(id: item.id) },
                        onRemove: {
                            withAnimation(.spring(response: 0.22, dampingFraction: 0.8)) {
                                shelf.removeItem(id: item.id)
                            }
                        },
                        itemProvider: { shelf.createItemProvider(for: item) }
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .scale(scale: 0.95).combined(with: .opacity)
                    ))
                }
            }
            .padding(10)
        }
    }
}

// MARK: - Isolated Stash Item Card View (High Performance, Zero Cross-Row Re-render)

private struct StashItemCardView: View {
    let item: StashItem
    let isSelected: Bool
    let onSelect: () -> Void
    let onOpen: () -> Void
    let onReveal: () -> Void
    let onCopyPath: () -> Void
    let onRemove: () -> Void
    let itemProvider: () -> NSItemProvider

    @State private var isHovered: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            // Left Drag Handle + Icon (Instant Drag Activation)
            HStack(spacing: 8) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isHovered ? .secondary : .secondary.opacity(0.4))
                    .frame(width: 12)

                itemIconView
                    .frame(width: 28, height: 28)
            }
            .contentShape(Rectangle())
            .onDrag({
                itemProvider()
            }, preview: {
                HStack(spacing: 8) {
                    itemIconView
                        .frame(width: 24, height: 24)
                    Text(item.title)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .shadow(color: Color.black.opacity(0.3), radius: 8, x: 2, y: 2)
                )
                .overlay(
                    Capsule()
                        .stroke(Color.cyan.opacity(0.4), lineWidth: 1)
                )
            })

            // Text Metadata (Tap to select)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(item.sourceURL != nil && !item.isExistingFile ? .secondary : .primary)
                    .strikethrough(item.sourceURL != nil && !item.isExistingFile, color: .orange)
                    .lineLimit(1)
                    .truncationMode(.middle)

                HStack(spacing: 4) {
                    if item.sourceURL != nil && !item.isExistingFile {
                        Text("Missing")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.orange)
                            .padding(.horizontal, 3)
                            .padding(.vertical, 0.5)
                            .background(RoundedRectangle(cornerRadius: 3).fill(Color.orange.opacity(0.15)))
                    } else if !item.formattedSize.isEmpty {
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
            .contentShape(Rectangle())
            .onTapGesture {
                onSelect()
            }

            Spacer()

            // Isolated Trailing Action Buttons
            HStack(spacing: 4) {
                Button(action: onOpen) {
                    Image(systemName: "arrow.up.forward.app")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(isSelected ? .cyan : .secondary)
                        .frame(width: 22, height: 22)
                        .background(
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(Color.white.opacity(0.08))
                        )
                }
                .buttonStyle(.plain)
                .help("Open File")

                if item.isExistingFile {
                    Button(action: onReveal) {
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

                    Button(action: onCopyPath) {
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

                Button(action: onRemove) {
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
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? Color.cyan.opacity(0.18) : (isHovered ? Color.white.opacity(0.12) : Color.white.opacity(0.05)))

                if isSelected {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(
                            RadialGradient(
                                colors: [Color.cyan.opacity(0.15), Color.clear],
                                center: .topLeading,
                                startRadius: 5,
                                endRadius: 100
                            )
                        )
                }
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(
                    isSelected
                        ? LinearGradient(colors: [Color.cyan, Color.blue.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        : (isHovered ? LinearGradient(colors: [Color.white.opacity(0.3), Color.white.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing) : LinearGradient(colors: [Color.clear], startPoint: .topLeading, endPoint: .bottomTrailing)),
                    lineWidth: 1.0
                )
        )
        .scaleEffect(isHovered ? 1.015 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.75), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }

    @ViewBuilder
    private var itemIconView: some View {
        if let url = item.sourceURL, item.isExistingFile {
            let icon = StashIconCache.shared.icon(for: url)
            Image(nsImage: icon)
                .resizable()
                .scaledToFit()
        } else if item.sourceURL != nil && !item.isExistingFile {
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.orange.opacity(0.18))

                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.orange)
            }
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
