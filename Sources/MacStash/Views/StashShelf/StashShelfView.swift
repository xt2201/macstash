import SwiftUI
import AppKit
import MacStashCore

/// Tactile Drop Shelf view elevated with Apple Liquid Glass optical shading.
/// Slides out from the screen edge to temporarily hold files, images, URLs, and text snippets
/// with bilingual localization, inline filter, clipboard paste, and drag-and-drop export.
public struct StashShelfView: View {
    @ObservedObject var appState: AppState
    @ObservedObject private var shelf = StashShelfManager.shared

    @State private var selectedItemID: UUID? = nil
    @State private var copyFeedback: Bool = false
    @State private var searchQuery: String = ""

    private let shelfWidth: CGFloat = Defaults.StashShelf.defaultWidthPoints

    public init(appState: AppState) {
        self.appState = appState
    }

    private var filteredItems: [StashItem] {
        let q = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return shelf.items }
        return shelf.items.filter {
            $0.title.lowercased().contains(q)
                || $0.detailText.lowercased().contains(q)
                || ($0.stringContent?.lowercased().contains(q) ?? false)
        }
    }

    public var body: some View {
        let isDropActive = shelf.isDropTargetActive

        let screenHeight = NSScreen.main?.visibleFrame.height ?? 800
        let targetHeight = max(340, min(470, screenHeight * 0.72))

        return VStack(spacing: 0) {
            // 1. Liquid Glass Header Bar
            headerBar

            Divider()
                .background(
                    LinearGradient(
                        colors: [Color.cyan.opacity(0.35), Color.primary.opacity(0.06)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            // 2. Search bar when shelf has >= 4 items
            if shelf.items.count >= 4 {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    TextField(appState.localized("shelf.searchPlaceholder"), text: $searchQuery)
                        .textFieldStyle(.plain)
                        .font(.system(size: 11))
                    if !searchQuery.isEmpty {
                        Button(action: { searchQuery = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color.primary.opacity(0.06)))
                .padding(.horizontal, 10)
                .padding(.top, 8)
            }

            // 3. Drop banner when dragging over existing items
            if isDropActive && !shelf.items.isEmpty {
                dropBanner
            }

            // 4. Body List / Drop Zone
            if shelf.items.isEmpty {
                emptyDropZone
            } else {
                itemsListView
            }
        }
        .frame(width: shelfWidth, height: targetHeight)
        .liquidGlass(
            cornerRadius: 20,
            tint: isDropActive ? .cyan : .clear,
            specularIntensity: 1.15,
            causticOpacity: isDropActive ? 0.28 : 0.14,
            shadowRadius: 22,
            isHighlighted: isDropActive,
            backdropOpacity: appState.settings.dialOpacity
        )
        .animation(.spring(response: 0.28, dampingFraction: 0.78), value: isDropActive)
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack(spacing: 6) {
            Image(systemName: "tray.2.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.cyan)
                .shadow(color: Color.cyan.opacity(0.35), radius: 3, x: 0, y: 0)

            Text(appState.localized("shelf.title"))
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .lineLimit(1)

            if !shelf.items.isEmpty {
                HStack(spacing: 4) {
                    Text("\(shelf.items.count)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .monospacedDigit()
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

            // Paste from clipboard quick button
            HoverActionButton(
                systemImage: "doc.on.clipboard",
                tint: .cyan,
                size: 24,
                helpText: appState.localized("shelf.pasteClipboard")
            ) {
                pasteFromClipboard()
            }

            if !shelf.items.isEmpty {
                HoverActionButton(
                    systemImage: copyFeedback ? "checkmark" : "doc.on.doc",
                    tint: copyFeedback ? .green : .secondary,
                    size: 24,
                    helpText: appState.localized("shelf.copyAll")
                ) {
                    shelf.copyAllFilesToClipboard()
                    withAnimation(.easeInOut(duration: 0.15)) { copyFeedback = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        withAnimation(.easeInOut(duration: 0.15)) { copyFeedback = false }
                    }
                }

                HoverActionButton(
                    systemImage: "trash",
                    tint: .red,
                    size: 24,
                    helpText: appState.localized("shelf.clearAll")
                ) {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        shelf.clearAll()
                        searchQuery = ""
                    }
                }
            } else if shelf.canUndoClear {
                HoverActionButton(
                    systemImage: "arrow.uturn.backward",
                    tint: .cyan,
                    size: 24,
                    helpText: appState.localized("shelf.undoClear")
                ) {
                    shelf.undoClear()
                }
            }

            HoverActionButton(
                systemImage: shelf.isPinned ? "pin.fill" : "pin",
                tint: shelf.isPinned ? .cyan : .secondary,
                size: 24,
                helpText: shelf.isPinned ? appState.localized("shelf.unpin") : appState.localized("shelf.pin")
            ) {
                shelf.togglePin()
            }

            HoverActionButton(
                systemImage: "xmark",
                tint: .secondary,
                size: 24,
                helpText: appState.localized("shelf.close")
            ) {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                    shelf.closeShelf()
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    // MARK: - Drop Target Banner

    private var dropBanner: some View {
        HStack(spacing: 6) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.cyan)

            Text(appState.localized("shelf.dropToStash"))
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

    // MARK: - Empty Drop Zone

    private var emptyDropZone: some View {
        let isDropActive = shelf.isDropTargetActive

        return VStack(spacing: 14) {
            Spacer()

            ZStack {
                if isDropActive {
                    Circle()
                        .stroke(Color.cyan.opacity(0.35), lineWidth: 2)
                        .frame(width: 86, height: 86)
                        .scaleEffect(1.08)
                }

                Circle()
                    .stroke(
                        LinearGradient(
                            colors: isDropActive
                                ? [Color.cyan, Color.blue]
                                : [Color.primary.opacity(0.25), Color.primary.opacity(0.06)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: isDropActive ? 2.0 : 1.5, dash: isDropActive ? [] : [4, 4])
                    )
                    .frame(width: 68, height: 68)
                    .background(
                        Circle()
                            .fill(isDropActive ? Color.cyan.opacity(0.15) : Color.primary.opacity(0.04))
                    )
                    .shadow(color: isDropActive ? Color.cyan.opacity(0.45) : Color.clear, radius: 10, x: 0, y: 0)

                Image(systemName: isDropActive ? "arrow.down.circle.fill" : "arrow.down.doc")
                    .font(.system(size: 26, weight: .light))
                    .foregroundColor(isDropActive ? .cyan : .secondary.opacity(0.75))
                    .scaleEffect(isDropActive ? 1.15 : 1.0)
                    .animation(.spring(response: 0.25, dampingFraction: 0.65), value: isDropActive)
            }

            VStack(spacing: 5) {
                Text(isDropActive ? appState.localized("shelf.dropToStash") : appState.localized("shelf.dropEmptyTitle"))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)

                Text(appState.localized("shelf.dropEmptyHint"))
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 14)
            }

            Button(action: pasteFromClipboard) {
                Label(appState.localized("shelf.pasteClipboard"), systemImage: "doc.on.clipboard")
                    .font(.system(size: 11, weight: .semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.cyan.opacity(0.16)))
                    .overlay(Capsule().strokeBorder(Color.cyan.opacity(0.35), lineWidth: 0.8))
                    .foregroundColor(.cyan)
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(16)
    }

    // MARK: - Items List View

    private var itemsListView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 6) {
                ForEach(filteredItems) { item in
                    StashItemCardView(
                        appState: appState,
                        item: item,
                        isSelected: selectedItemID == item.id,
                        onSelect: { selectedItemID = item.id },
                        onOpen: { shelf.openItem(id: item.id) },
                        onReveal: { shelf.revealInFinder(id: item.id) },
                        onCopyFile: { shelf.copyItemToClipboard(id: item.id) },
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

    private func pasteFromClipboard() {
        let pb = NSPasteboard.general
        if let urls = pb.readObjects(forClasses: [NSURL.self], options: nil) as? [URL], !urls.isEmpty {
            let fileURLs = urls.filter { $0.isFileURL }
            let webURLs = urls.filter { !$0.isFileURL }
            if !fileURLs.isEmpty { shelf.addFileURLs(fileURLs) }
            for u in webURLs { shelf.addTextSnippet(u.absoluteString) }
            return
        }
        if let str = pb.string(forType: .string) {
            let trimmed = str.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.hasPrefix("/") && FileManager.default.fileExists(atPath: trimmed) {
                shelf.addFileURLs([URL(fileURLWithPath: trimmed)])
            } else if !trimmed.isEmpty {
                shelf.addTextSnippet(trimmed)
            }
        }
    }
}
