import SwiftUI
import AppKit
import SideDockCore
import MacStashCore

public struct FolderEntry: Identifiable, Equatable {
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
    @State private var currentURL: URL
    @State private var entries: [FolderEntry] = []
    @State private var selectedSort: FolderSortOrder
    @State private var searchText: String = ""

    private func localized(_ key: String) -> String {
        LocalizationService.shared.localized(key)
    }

    public init(folderItem: FolderItem) {
        self.folderItem = folderItem
        let initialURL = URL(fileURLWithPath: (folderItem.folderPath as NSString).expandingTildeInPath)
        _currentURL = State(initialValue: initialURL)
        _selectedSort = State(initialValue: folderItem.sortOrder)
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
                    .font(.system(size: 12, weight: .bold))
                    .lineLimit(1)

                Spacer()

                Picker("", selection: $selectedSort) {
                    Text(localized("folder.name")).tag(FolderSortOrder.name)
                    Text(localized("folder.kind")).tag(FolderSortOrder.kind)
                    Text(localized("folder.size")).tag(FolderSortOrder.size)
                    Text(localized("folder.date")).tag(FolderSortOrder.dateModified)
                }
                .pickerStyle(.menu)
                .frame(width: 86)

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

            Divider()

            if sortedEntries.isEmpty {
                Text(localized("folder.empty"))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 80)
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(sortedEntries) { entry in
                            Button {
                                if entry.isDirectory {
                                    currentURL = entry.url
                                    loadEntries()
                                } else {
                                    NSWorkspace.shared.open(entry.url)
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(nsImage: NSWorkspace.shared.icon(forFile: entry.url.path))
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
                                    }
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 6)
                }
                .frame(maxHeight: 280)
            }
        }
        .frame(width: 290)
        .padding(.bottom, 8)
        .onAppear {
            loadEntries()
        }
    }

    private func loadEntries() {
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: currentURL,
            includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            self.entries = []
            return
        }

        self.entries = contents.map { FolderEntry(url: $0) }
    }
}
