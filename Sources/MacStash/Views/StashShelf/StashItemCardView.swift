import SwiftUI
import AppKit
import MacStashCore
import MacStashDesignSystem

/// Isolated Stash Item Card View with fast diffing at 120fps and rich drag/drop export.
public struct StashItemCardView: View {
    @ObservedObject var appState: AppState
    public let item: StashItem
    public let isSelected: Bool
    public let onSelect: () -> Void
    public let onOpen: () -> Void
    public let onReveal: () -> Void
    public let onCopyFile: () -> Void
    public let onCopyPath: () -> Void
    public let onRemove: () -> Void
    public let itemProvider: () -> NSItemProvider

    @State private var isHovered: Bool = false
    @State private var copiedRow: Bool = false

    public init(
        appState: AppState,
        item: StashItem,
        isSelected: Bool,
        onSelect: @escaping () -> Void,
        onOpen: @escaping () -> Void,
        onReveal: @escaping () -> Void,
        onCopyFile: @escaping () -> Void,
        onCopyPath: @escaping () -> Void,
        onRemove: @escaping () -> Void,
        itemProvider: @escaping () -> NSItemProvider
    ) {
        self.appState = appState
        self.item = item
        self.isSelected = isSelected
        self.onSelect = onSelect
        self.onOpen = onOpen
        self.onReveal = onReveal
        self.onCopyFile = onCopyFile
        self.onCopyPath = onCopyPath
        self.onRemove = onRemove
        self.itemProvider = itemProvider
    }

    public var body: some View {
        HStack(spacing: 8) {
            // Main Content Area (Drag, Select, Double-Click to Open)
            HStack(spacing: 8) {
                itemIconView
                    .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundColor(item.sourceURL != nil && !item.isExistingFile ? .secondary : .primary)
                        .strikethrough(item.sourceURL != nil && !item.isExistingFile, color: .orange)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    HStack(spacing: 4) {
                        if item.sourceURL != nil && !item.isExistingFile {
                            Text(appState.localized("shelf.missing"))
                                .font(.system(size: 8.5, weight: .bold))
                                .foregroundColor(.orange)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 0.5)
                                .background(RoundedRectangle(cornerRadius: 3).fill(Color.orange.opacity(0.15)))
                        } else if !item.formattedSize.isEmpty {
                            Text(item.formattedSize)
                                .font(.system(size: 9, weight: .medium, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                        if item.itemType == .url {
                            Text(appState.localized("shelf.link"))
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(.cyan)
                        } else if item.itemType == .text {
                            Text(appState.localized("shelf.snippet"))
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(.green)
                        } else if let ext = item.sourceURL?.pathExtension.uppercased(), !ext.isEmpty {
                            Text(ext)
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 0.5)
                                .background(RoundedRectangle(cornerRadius: 3).fill(Color.primary.opacity(0.08)))
                        }
                    }
                }
            }
            .contentShape(Rectangle())
            .onDrag({
                itemProvider()
            }, preview: {
                HStack(spacing: 8) {
                    itemIconView
                        .frame(width: 22, height: 22)
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
            .onTapGesture(count: 2) {
                onOpen()
            }
            .onTapGesture {
                onSelect()
            }

            Spacer(minLength: 4)

            // Compact Action Micro-Buttons (revealed cleanly on hover / selection)
            HStack(spacing: 4) {
                if isHovered || isSelected {
                    rowActionButton(
                        icon: copiedRow ? "checkmark" : "doc.on.doc",
                        tint: copiedRow ? .green : .secondary,
                        help: appState.localized("shelf.copyFile")
                    ) {
                        onCopyFile()
                        copiedRow = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { copiedRow = false }
                    }

                    if item.isExistingFile {
                        rowActionButton(
                            icon: "magnifyingglass",
                            tint: .secondary,
                            help: appState.localized("shelf.revealFinder"),
                            action: onReveal
                        )
                    }

                    rowActionButton(
                        icon: "arrow.up.forward.app",
                        tint: .cyan,
                        help: appState.localized("shelf.open"),
                        action: onOpen
                    )
                }

                rowActionButton(
                    icon: "xmark",
                    tint: .secondary,
                    help: appState.localized("shelf.remove"),
                    action: onRemove
                )
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .contextMenu {
            Button(appState.localized("shelf.copyFile")) { onCopyFile() }
            if item.sourceURL != nil {
                Button(appState.localized("shelf.copyPath")) { onCopyPath() }
            }
            Divider()
            Button(appState.localized("shelf.open")) { onOpen() }
            if item.isExistingFile {
                Button(appState.localized("shelf.revealFinder")) { onReveal() }
            }
            Divider()
            Button(appState.localized("shelf.remove")) { onRemove() }
        }
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isSelected ? Color.cyan.opacity(0.18) : (isHovered ? Color.primary.opacity(0.09) : Color.primary.opacity(0.04)))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(
                    isSelected
                        ? Color.cyan.opacity(0.7)
                        : (isHovered ? Color.primary.opacity(0.16) : Color.clear),
                    lineWidth: 1.0
                )
        )
        .animation(.easeOut(duration: 0.14), value: isHovered)
        .onHover { isHovered = $0 }
    }

    private func rowActionButton(icon: String, tint: Color, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 9.5, weight: .bold))
                .foregroundColor(tint)
                .frame(width: 22, height: 22)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.primary.opacity(0.07))
                )
        }
        .buttonStyle(.plain)
        .help(help)
    }

    @ViewBuilder
    private var itemIconView: some View {
        if let url = item.sourceURL, item.isExistingFile {
            let icon = AppIconCache.shared.icon(forPath: url.path, targetSize: NSSize(width: 28, height: 28))
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
