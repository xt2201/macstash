import SwiftUI
import AppKit
import UniformTypeIdentifiers
import SideDockCore
import SideDockWidgets
import MacStashCore

public struct DockItemsEditorSection: View {
    @Binding public var config: SideDockFileConfig
    public let activeProfileIndex: Int
    public let onSave: (Bool) -> Void
    public let onOpenWidgetGallery: () -> Void
    public let onEditWidget: (WidgetItem) -> Void

    @State private var showActionEditor: Bool = false
    @State private var showAppFolderEditor: Bool = false
    @State private var editingAppFolder: AppFolderItem? = nil
    @State private var showSmartStackEditor: Bool = false
    @State private var editingSmartStack: SmartStackItem? = nil

    public init(
        config: Binding<SideDockFileConfig>,
        activeProfileIndex: Int,
        onSave: @escaping (Bool) -> Void,
        onOpenWidgetGallery: @escaping () -> Void,
        onEditWidget: @escaping (WidgetItem) -> Void
    ) {
        self._config = config
        self.activeProfileIndex = activeProfileIndex
        self.onSave = onSave
        self.onOpenWidgetGallery = onOpenWidgetGallery
        self.onEditWidget = onEditWidget
    }

    private func localized(_ key: String) -> String {
        LocalizationService.shared.localized(key)
    }

    private var items: Binding<[DockItem]> {
        $config.profiles[activeProfileIndex].items
    }

    public var body: some View {
        DockSettingsCard(title: localized("dock.itemsTitle"), systemImage: "app.badge", accent: .cyan) {
            Text(localized("dock.itemsDesc"))
                .font(.system(size: 11))
                .foregroundColor(.secondary)

            if items.wrappedValue.isEmpty {
                Text(localized("dock.noItems"))
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 5) {
                    ForEach(Array(items.wrappedValue.enumerated()), id: \.element.id) { idx, item in
                        itemRow(idx: idx, item: item)
                    }
                }
            }

            Divider()

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Button { addApplication() } label: {
                        Label(localized("dock.addApp"), systemImage: "plus.app")
                    }

                    Button { addDirectoryFolder() } label: {
                        Label(localized("dock.addFolder"), systemImage: "folder.badge.plus")
                    }

                    Button {
                        editingAppFolder = nil
                        showAppFolderEditor = true
                    } label: {
                        Label(localized("dock.addAppFolder"), systemImage: "square.grid.2x2")
                    }

                    Button {
                        editingSmartStack = nil
                        showSmartStackEditor = true
                    } label: {
                        Label(localized("dock.addSmartStack"), systemImage: "square.stack.3d.up")
                    }

                    Button { showActionEditor = true } label: {
                        Label(localized("dock.addAction"), systemImage: "bolt.fill")
                    }

                    Button {
                        items.wrappedValue.append(.launchpad(UUID()))
                        onSave(true)
                    } label: {
                        Label("Launchpad", systemImage: "square.grid.3x3.fill")
                    }

                    Button {
                        items.wrappedValue.append(.trash(UUID()))
                        onSave(true)
                    } label: {
                        Label("Trash", systemImage: "trash")
                    }

                    Button {
                        items.wrappedValue.append(.separator(UUID()))
                        onSave(true)
                    } label: {
                        Label(localized("dock.addSeparator"), systemImage: "line.diagonal")
                    }

                    Button { onOpenWidgetGallery() } label: {
                        Label(localized("dock.addWidget"), systemImage: "plus.rectangle.on.rectangle")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .sheet(isPresented: $showActionEditor) {
            ActionEditorSheet { newAction in
                items.wrappedValue.append(.action(newAction))
                onSave(true)
            }
        }
        .sheet(isPresented: $showAppFolderEditor) {
            AppFolderEditorSheet(existing: editingAppFolder) { folder in
                if let idx = items.wrappedValue.firstIndex(where: { $0.id == folder.id }) {
                    items.wrappedValue[idx] = .appFolder(folder)
                } else {
                    items.wrappedValue.append(.appFolder(folder))
                }
                onSave(true)
            }
        }
        .sheet(isPresented: $showSmartStackEditor) {
            SmartStackEditorSheet(existing: editingSmartStack) { stack in
                if let idx = items.wrappedValue.firstIndex(where: { $0.id == stack.id }) {
                    items.wrappedValue[idx] = .smartStack(stack)
                } else {
                    items.wrappedValue.append(.smartStack(stack))
                }
                onSave(true)
            }
        }
    }

    private func itemRow(idx: Int, item: DockItem) -> some View {
        HStack(spacing: 8) {
            Image(systemName: item.systemIconName)
                .foregroundColor(.accentColor)
                .frame(width: 20)

            Text(item.displayName)
                .font(.system(size: 12, weight: .medium))

            if case .widget(let w) = item {
                badgeTag(w.size.rawValue.uppercased())
            } else if case .smartStack(let s) = item {
                badgeTag("STACK (\(s.widgets.count))")
            }

            Spacer()

            if case .widget(let w) = item {
                Button {
                    onEditWidget(w)
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
                .help(localized("dock.configureWidget"))
            } else if case .appFolder(let folder) = item {
                Button {
                    editingAppFolder = folder
                    showAppFolderEditor = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
            } else if case .smartStack(let stack) = item {
                Button {
                    editingSmartStack = stack
                    showSmartStackEditor = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
            }

            if idx > 0 {
                Button { moveItem(from: idx, to: idx - 1) } label: {
                    Image(systemName: "chevron.up").font(.system(size: 10, weight: .bold))
                }
                .buttonStyle(.plain)
                .help(localized("dock.moveUp"))
            }

            if idx < items.wrappedValue.count - 1 {
                Button { moveItem(from: idx, to: idx + 1) } label: {
                    Image(systemName: "chevron.down").font(.system(size: 10, weight: .bold))
                }
                .buttonStyle(.plain)
                .help(localized("dock.moveDown"))
            }

            Button(role: .destructive) {
                items.wrappedValue.remove(at: idx)
                onSave(true)
            } label: {
                Image(systemName: "trash").font(.system(size: 11)).foregroundColor(.red)
            }
            .buttonStyle(.plain)
            .help(localized("dock.remove"))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color.primary.opacity(0.045)))
    }

    private func badgeTag(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .bold, design: .rounded))
            .foregroundColor(.secondary)
            .padding(.horizontal, 5)
            .padding(.vertical, 1.5)
            .background(Capsule().fill(Color.primary.opacity(0.06)))
    }

    private func moveItem(from: Int, to: Int) {
        guard from >= 0 && from < items.wrappedValue.count,
              to >= 0 && to < items.wrappedValue.count else { return }
        let item = items.wrappedValue.remove(at: from)
        items.wrappedValue.insert(item, at: to)
        onSave(true)
    }

    private func addApplication() {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [UTType.application]
        openPanel.directoryURL = URL(fileURLWithPath: "/Applications")
        openPanel.allowsMultipleSelection = true
        openPanel.canChooseDirectories = false
        openPanel.prompt = "Add to Dock"
        if openPanel.runModal() == .OK {
            for url in openPanel.urls {
                let bundle = Bundle(url: url)
                let bundleID = bundle?.bundleIdentifier ?? url.deletingPathExtension().lastPathComponent
                let name = FileManager.default.displayName(atPath: url.path)
                let face = AppWidgetFaceRegistry.defaultWidgetKind(forBundleID: bundleID)
                let appItem = AppItem(bundleIdentifier: bundleID, displayName: name, appPath: url.path, widgetFaceKind: face)
                items.wrappedValue.append(.app(appItem))
            }
            onSave(true)
        }
    }

    private func addDirectoryFolder() {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.prompt = "Add Folder"
        if openPanel.runModal() == .OK, let url = openPanel.url {
            let folder = FolderItem(folderPath: url.path, displayName: url.lastPathComponent)
            items.wrappedValue.append(.folder(folder))
            onSave(true)
        }
    }
}
