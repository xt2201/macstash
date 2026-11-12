import SwiftUI
import AppKit
import QuickLookUI
import SideDockCore
import MacStashCore
import MacStashDesignSystem

public struct FolderEntry: Identifiable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let url: URL
    public let isDirectory: Bool
    public let fileSize: Int64
    public let dateModified: Date
    public let kindDescription: String

    public init(url: URL) {
        self.id = url.path
        self.name = url.lastPathComponent
        self.url = url

        var isDir: ObjCBool = false
        FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
        self.isDirectory = isDir.boolValue

        let attrs = (try? FileManager.default.attributesOfItem(atPath: url.path)) ?? [:]
        self.fileSize = (attrs[.size] as? NSNumber)?.int64Value ?? 0
        self.dateModified = (attrs[.modificationDate] as? Date) ?? Date.distantPast
        self.kindDescription = url.pathExtension.uppercased().isEmpty ? (isDir.boolValue ? "Folder" : "File") : url.pathExtension.uppercased()
    }
}

public struct FolderPopoverView: View {
    public let folderItem: FolderItem
    public let onUpdatePreferences: ((FolderPresentationStyle, FolderSortOrder) -> Void)?
    @State private var currentURL: URL
    @State private var entries: [FolderEntry] = []
    @State private var selectedSort: FolderSortOrder
    @State private var viewStyle: FolderPresentationStyle
    @State private var searchText: String = ""

    private func localized(_ key: String) -> String {
        LocalizationService.shared.localized(key)
    }

    public init(
        folderItem: FolderItem,
        onUpdatePreferences: ((FolderPresentationStyle, FolderSortOrder) -> Void)? = nil
    ) {
        self.folderItem = folderItem
        self.onUpdatePreferences = onUpdatePreferences
        let initialURL = URL(fileURLWithPath: (folderItem.folderPath as NSString).expandingTildeInPath)
        _currentURL = State(initialValue: initialURL)
        _selectedSort = State(initialValue: folderItem.sortOrder)
        _viewStyle = State(initialValue: folderItem.presentationStyle)
    }

    private var sortedEntries: [FolderEntry] {
        var list = entries
        if !searchText.isEmpty {
            list = list.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        switch selectedSort {
        case .name:
            return list.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        case .kind:
            return list.sorted {
                if $0.isDirectory != $1.isDirectory { return $0.isDirectory }
                return $0.kindDescription < $1.kindDescription
            }
        case .size:
            return list.sorted { $0.fileSize > $1.fileSize }
        case .dateModified:
            return list.sorted { $0.dateModified > $1.dateModified }
        }
    }

    public var body: some View {
        VStack(spacing: 8) {
            headerBar
            searchBar
            Divider()
            contentView
        }
        .frame(width: viewStyle == .popoverGrid ? 336 : 300)
        .padding(.bottom, 8)
        .onChange(of: viewStyle) { _, newStyle in
            onUpdatePreferences?(newStyle, selectedSort)
        }
        .onChange(of: selectedSort) { _, newSort in
            onUpdatePreferences?(viewStyle, newSort)
        }
        .onAppear {
            loadEntries()
        }
    }

    private var headerBar: some View {
        HStack(spacing: 6) {
            if currentURL.path != (folderItem.folderPath as NSString).expandingTildeInPath {
                Button {
                    currentURL = currentURL.deletingLastPathComponent()
                    loadEntries()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11, weight: .bold))
                }
                .buttonStyle(.plain)
            }

            Text(currentURL.lastPathComponent)
                .font(.system(size: 12.5, weight: .bold))
                .lineLimit(1)

            Spacer()

            Picker("", selection: $viewStyle) {
                Image(systemName: "square.grid.2x2").tag(FolderPresentationStyle.popoverGrid)
                Image(systemName: "list.bullet").tag(FolderPresentationStyle.popoverList)
                Image(systemName: "rectangle.stack").tag(FolderPresentationStyle.fan)
            }
            .pickerStyle(.segmented)
            .frame(width: 96)

            Picker("", selection: $selectedSort) {
                Text(localized("folder.name")).tag(FolderSortOrder.name)
                Text(localized("folder.kind")).tag(FolderSortOrder.kind)
                Text(localized("folder.size")).tag(FolderSortOrder.size)
                Text(localized("folder.date")).tag(FolderSortOrder.dateModified)
            }
            .pickerStyle(.menu)
            .frame(width: 74)

            Button {
                NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: currentURL.path)
            } label: {
                Image(systemName: "arrow.up.forward.app")
                    .font(.system(size: 11))
            }
            .buttonStyle(.plain)
            .help(localized("dock.openInFinder"))
        }
        .padding(.horizontal, 10)
        .padding(.top, 8)
    }

    private var searchBar: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            TextField(localized("folder.searchPlaceholder"), text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 11))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(RoundedRectangle(cornerRadius: 6).fill(Color.primary.opacity(0.06)))
        .padding(.horizontal, 10)
    }

    @ViewBuilder
    private var contentView: some View {
        if sortedEntries.isEmpty {
            Text(localized("folder.empty"))
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, minHeight: 90)
        } else {
            ScrollView {
                switch viewStyle {
                case .popoverGrid:
                    gridEntriesView
                case .popoverList:
                    listEntriesView
                case .fan:
                    fanEntriesView
                }
            }
            .frame(maxHeight: 300)
        }
    }

    private var gridEntriesView: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 68), spacing: 8)], spacing: 10) {
            ForEach(sortedEntries) { entry in
                Button {
                    openEntry(entry)
                } label: {
                    VStack(spacing: 4) {
                        Image(nsImage: AppIconCache.shared.icon(forPath: entry.url.path, targetSize: NSSize(width: 36, height: 36)))
                            .resizable()
                            .interpolation(.high)
                            .frame(width: 36, height: 36)
                        Text(entry.name)
                            .font(.system(size: 10, weight: .medium))
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                    }
                    .frame(width: 66, height: 64)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .onDrag { NSItemProvider(object: entry.url as NSURL) }
                .contextMenu { entryContextMenu(entry) }
            }
        }
        .padding(10)
    }

    private var listEntriesView: some View {
        LazyVStack(spacing: 2) {
            ForEach(sortedEntries) { entry in
                HStack(spacing: 8) {
                    Button {
                        openEntry(entry)
                    } label: {
                        HStack(spacing: 8) {
                            Image(nsImage: AppIconCache.shared.icon(forPath: entry.url.path, targetSize: NSSize(width: 18, height: 18)))
                                .resizable()
                                .frame(width: 18, height: 18)

                            Text(entry.name)
                                .font(.system(size: 11))
                                .lineLimit(1)

                            Spacer()

                            if !entry.isDirectory && entry.fileSize > 0 {
                                Text(ByteCountFormatter.string(fromByteCount: entry.fileSize, countStyle: .file))
                                    .font(.system(size: 9))
                                    .foregroundColor(.secondary)
                                    .monospacedDigit()
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if !entry.isDirectory {
                        Button {
                            FolderQuickLookCoordinator.shared.preview(url: entry.url)
                        } label: {
                            Image(systemName: "eye")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .onDrag { NSItemProvider(object: entry.url as NSURL) }
                .contextMenu { entryContextMenu(entry) }
            }
        }
        .padding(.horizontal, 6)
    }

    private var fanEntriesView: some View {
        let slice = Array(sortedEntries.prefix(12).enumerated())
        return VStack(alignment: .leading, spacing: 5) {
            ForEach(slice, id: \.element.id) { idx, entry in
                let fanOffset = CGFloat(sin(Double(idx) * 0.35)) * 10.0
                let fanAngle = Double(idx - slice.count / 2) * 0.8
                Button {
                    openEntry(entry)
                } label: {
                    HStack(spacing: 10) {
                        Image(nsImage: AppIconCache.shared.icon(forPath: entry.url.path, targetSize: NSSize(width: 26, height: 26)))
                            .resizable()
                            .frame(width: 26, height: 26)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(entry.name)
                                .font(.system(size: 11.5, weight: .semibold))
                                .lineLimit(1)
                            Text(entry.kindDescription)
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(.regularMaterial)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(Color.primary.opacity(0.12), lineWidth: 0.7)
                    )
                    .rotationEffect(.degrees(fanAngle), anchor: .leading)
                    .offset(x: max(0, fanOffset))
                }
                .buttonStyle(.plain)
                .onDrag { NSItemProvider(object: entry.url as NSURL) }
                .contextMenu { entryContextMenu(entry) }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private func entryContextMenu(_ entry: FolderEntry) -> some View {
        Button(localized("dock.open")) { openEntry(entry) }
        if !entry.isDirectory {
            Button("Quick Look") { FolderQuickLookCoordinator.shared.preview(url: entry.url) }
        }
        Button(localized("dock.openInFinder")) {
            NSWorkspace.shared.selectFile(entry.url.path, inFileViewerRootedAtPath: "")
        }
    }

    private func openEntry(_ entry: FolderEntry) {
        if entry.isDirectory {
            currentURL = entry.url
            loadEntries()
        } else {
            NSWorkspace.shared.open(entry.url)
        }
    }

    private func loadEntries() {
        let target = currentURL
        Task {
            let loaded = await Task.detached(priority: .userInitiated) {
                guard let contents = try? FileManager.default.contentsOfDirectory(
                    at: target,
                    includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey],
                    options: [.skipsHiddenFiles]
                ) else {
                    return [FolderEntry]()
                }
                return contents.map { FolderEntry(url: $0) }
            }.value
            await MainActor.run {
                self.entries = loaded
            }
        }
    }
}

private final class FolderQuickLookCoordinator: NSObject, QLPreviewPanelDataSource, @unchecked Sendable {
    static let shared = FolderQuickLookCoordinator()
    private let lock = NSLock()
    private var previewURL: URL?

    @MainActor
    func preview(url: URL) {
        lock.lock()
        previewURL = url
        lock.unlock()
        guard let panel = QLPreviewPanel.shared() else { return }
        panel.dataSource = self
        panel.reloadData()
        panel.makeKeyAndOrderFront(nil)
    }

    func numberOfPreviewItems(in panel: QLPreviewPanel?) -> Int {
        lock.lock()
        defer { lock.unlock() }
        return previewURL == nil ? 0 : 1
    }

    func previewPanel(_ panel: QLPreviewPanel?, previewItemAt index: Int) -> (any QLPreviewItem)? {
        lock.lock()
        defer { lock.unlock() }
        return previewURL as NSURL?
    }
}
