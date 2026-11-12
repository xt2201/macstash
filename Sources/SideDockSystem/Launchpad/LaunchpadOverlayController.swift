import AppKit
import SwiftUI
import SideDockCore
import MacStashDesignSystem

@MainActor
public final class LaunchpadOverlayController: ObservableObject {
    public static let shared = LaunchpadOverlayController()

    private var panel: LaunchpadKeyPanel?
    @Published public var apps: [LaunchpadAppEntry] = []
    @Published public var searchText: String = ""
    @Published public var selectedCategory: LaunchpadAppCategory = .all
    @Published public var selectedIndex: Int = 0
    @Published public var isOpen: Bool = false
    @Published public var layoutConfig: LaunchpadLayoutConfig = LaunchpadLayoutConfig()
    @Published public var activeFolder: LaunchpadFolderGroup? = nil
    @Published public var showInspector: Bool = false

    public var onLayoutUpdated: ((LaunchpadLayoutConfig) -> Void)?

    public init() {}

    public func toggle(layoutConfig: LaunchpadLayoutConfig) {
        if isOpen {
            dismiss()
        } else {
            open(layoutConfig: layoutConfig)
        }
    }

    public func open(layoutConfig: LaunchpadLayoutConfig) {
        self.layoutConfig = layoutConfig
        self.searchText = ""
        self.selectedCategory = .all
        self.selectedIndex = 0
        self.activeFolder = nil
        self.showInspector = false
        self.isOpen = true

        Task {
            let indexed = await LaunchpadService.shared.installedApps(forceRefresh: self.apps.isEmpty)
            let hidden = Set(layoutConfig.hiddenBundleIDs)
            self.apps = indexed.filter { !hidden.contains($0.bundleIdentifier) }
        }

        presentPanel()
    }

    public func dismiss() {
        isOpen = false
        activeFolder = nil
        showInspector = false
        panel?.orderOut(nil)
    }

    public var filteredApps: [LaunchpadAppEntry] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return apps.filter { entry in
            let matchesCat = selectedCategory == .all || entry.category == selectedCategory
            if !matchesCat { return false }
            if trimmed.isEmpty { return true }
            return entry.name.localizedCaseInsensitiveContains(trimmed)
        }
    }

    public func launchSelectedOrFirst() {
        let list = filteredApps
        guard !list.isEmpty else { return }
        let idx = min(max(0, selectedIndex), list.count - 1)
        launch(list[idx])
    }

    public func launch(_ entry: LaunchpadAppEntry) {
        dismiss()
        NSWorkspace.shared.open(URL(fileURLWithPath: entry.path))
    }

    public func createQuickFolder(title: String, bundleIDs: [String]) {
        guard !bundleIDs.isEmpty else { return }
        let group = LaunchpadFolderGroup(title: title, appBundleIDs: bundleIDs)
        layoutConfig.folders.append(group)
        onLayoutUpdated?(layoutConfig)
    }

    public func removeFolder(_ id: UUID) {
        layoutConfig.folders.removeAll { $0.id == id }
        if activeFolder?.id == id { activeFolder = nil }
        onLayoutUpdated?(layoutConfig)
    }

    public func persistLayout() {
        onLayoutUpdated?(layoutConfig)
    }

    private func presentPanel() {
        let screen = NSScreen.main ?? NSScreen.screens.first
        let frame = screen?.frame ?? CGRect(x: 0, y: 0, width: 1440, height: 900)

        let view = LaunchpadOverlayView(controller: self)
        let host = NSHostingView(rootView: view)

        if panel == nil {
            let p = LaunchpadKeyPanel(
                contentRect: frame,
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            p.isOpaque = false
            p.backgroundColor = .clear
            p.hasShadow = false
            p.level = .screenSaver
            p.collectionBehavior = [.canJoinAllSpaces, .transient, .fullScreenAuxiliary]
            p.onEscape = { [weak self] in
                if self?.activeFolder != nil {
                    self?.activeFolder = nil
                } else {
                    self?.dismiss()
                }
            }
            p.onKeyAction = { [weak self] event in self?.handleKey(event) ?? false }
            panel = p
        }

        panel?.contentView = host
        panel?.setFrame(frame, display: true)
        panel?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: false)
    }

    private func handleKey(_ event: NSEvent) -> Bool {
        if event.keyCode == 53 {
            if activeFolder != nil { activeFolder = nil } else { dismiss() }
            return true
        }
        let count = filteredApps.count
        guard count > 0 else { return false }

        switch event.keyCode {
        case 36: launchSelectedOrFirst(); return true
        case 123: selectedIndex = max(0, selectedIndex - 1); return true
        case 124: selectedIndex = min(count - 1, selectedIndex + 1); return true
        case 125: selectedIndex = min(count - 1, selectedIndex + layoutConfig.columns); return true
        case 126: selectedIndex = max(0, selectedIndex - layoutConfig.columns); return true
        default: return false
        }
    }
}

private final class LaunchpadKeyPanel: NSPanel {
    var onEscape: (() -> Void)?
    var onKeyAction: ((NSEvent) -> Bool)?

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    override func cancelOperation(_ sender: Any?) {
        onEscape?()
    }

    override func keyDown(with event: NSEvent) {
        if onKeyAction?(event) == true { return }
        super.keyDown(with: event)
    }
}

private struct LaunchpadOverlayView: View {
    @ObservedObject var controller: LaunchpadOverlayController
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(Color.black.opacity(0.32))
                .ignoresSafeArea()
                .onTapGesture {
                    if controller.activeFolder != nil {
                        controller.activeFolder = nil
                    } else {
                        controller.dismiss()
                    }
                }

            VStack(spacing: 18) {
                topBar
                categoryChips
                if !controller.layoutConfig.folders.isEmpty && controller.searchText.isEmpty && controller.selectedCategory == .all {
                    foldersRow
                }
                appsGrid
            }

            if let folder = controller.activeFolder {
                folderModal(folder)
            }
        }
        .onAppear {
            isSearchFocused = true
        }
    }

    private var topBar: some View {
        HStack(spacing: 14) {
            Spacer()
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)

                TextField("Search applications...", text: $controller.searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 16, weight: .medium))
                    .focused($isSearchFocused)
                    .onSubmit { controller.launchSelectedOrFirst() }

                if !controller.searchText.isEmpty {
                    Button { controller.searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(width: 340)
            .background(Capsule(style: .continuous).fill(.regularMaterial))
            .overlay(Capsule(style: .continuous).strokeBorder(Color.white.opacity(0.22), lineWidth: 0.9))

            Button {
                controller.showInspector.toggle()
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Circle().fill(.regularMaterial))
            }
            .buttonStyle(.plain)
            .popover(isPresented: $controller.showInspector, arrowEdge: .bottom) {
                inspectorPopover
            }

            Spacer()
        }
        .padding(.top, 46)
    }

    private var categoryChips: some View {
        HStack(spacing: 8) {
            ForEach(LaunchpadAppCategory.allCases, id: \.self) { cat in
                let isSelected = controller.selectedCategory == cat
                Button {
                    controller.selectedCategory = cat
                    controller.selectedIndex = 0
                } label: {
                    Text(cat.rawValue)
                        .font(.system(size: 11.5, weight: isSelected ? .bold : .medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(isSelected ? Color.accentColor : Color.white.opacity(0.12)))
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var foldersRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(controller.layoutConfig.folders) { folder in
                    Button {
                        controller.activeFolder = folder
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "folder.fill")
                                .foregroundColor(.white)
                            Text(folder.title)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.white.opacity(0.14)))
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button("Delete Folder", role: .destructive) {
                            controller.removeFolder(folder.id)
                        }
                    }
                }
            }
            .padding(.horizontal, 72)
        }
    }

    private var appsGrid: some View {
        ScrollView {
            let cols = Array(
                repeating: GridItem(.flexible(minimum: 90, maximum: 140), spacing: 22),
                count: max(4, controller.layoutConfig.columns)
            )
            LazyVGrid(columns: cols, spacing: 24) {
                ForEach(Array(controller.filteredApps.enumerated()), id: \.element.id) { idx, entry in
                    let isSelected = idx == controller.selectedIndex
                    Button {
                        controller.launch(entry)
                    } label: {
                        VStack(spacing: 8) {
                            let iconDim = CGFloat(controller.layoutConfig.iconSize)
                            Image(nsImage: AppIconCache.shared.icon(forPath: entry.path, targetSize: NSSize(width: iconDim, height: iconDim)))
                                .resizable()
                                .interpolation(.high)
                                .frame(width: iconDim, height: iconDim)
                                .shadow(color: Color.black.opacity(0.25), radius: 6, y: 3)

                            Text(entry.name)
                                .font(.system(size: 12.5, weight: .medium))
                                .foregroundColor(.white)
                                .lineLimit(1)
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(isSelected ? Color.white.opacity(0.18) : Color.clear)
                        )
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button("Create Folder with \(entry.name)") {
                            controller.createQuickFolder(title: entry.category.rawValue, bundleIDs: [entry.bundleIdentifier])
                        }
                    }
                }
            }
            .padding(.horizontal, 72)
            .padding(.bottom, 56)
        }
    }

    private var inspectorPopover: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Launchpad Layout")
                .font(.system(size: 13, weight: .bold))
            Stepper("Columns: \(controller.layoutConfig.columns)", value: $controller.layoutConfig.columns, in: 4...10)
            VStack(alignment: .leading, spacing: 4) {
                Text("Icon Size: \(Int(controller.layoutConfig.iconSize)) px")
                    .font(.system(size: 11.5))
                    .monospacedDigit()
                Slider(value: $controller.layoutConfig.iconSize, in: 48...104, step: 4)
            }
        }
        .padding(14)
        .frame(width: 220)
        .onChange(of: controller.layoutConfig) { _, _ in
            controller.persistLayout()
        }
    }

    private func folderModal(_ folder: LaunchpadFolderGroup) -> some View {
        let folderApps = controller.apps.filter { folder.appBundleIDs.contains($0.bundleIdentifier) }
        return VStack(spacing: 14) {
            HStack {
                Text(folder.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Button { controller.activeFolder = nil } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.8))
                }
                .buttonStyle(.plain)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 84), spacing: 14)], spacing: 14) {
                ForEach(folderApps) { entry in
                    Button {
                        controller.launch(entry)
                    } label: {
                        VStack(spacing: 6) {
                            Image(nsImage: AppIconCache.shared.icon(forPath: entry.path, targetSize: NSSize(width: 56, height: 56)))
                                .resizable()
                                .frame(width: 56, height: 56)
                            Text(entry.name)
                                .font(.system(size: 11.5, weight: .medium))
                                .foregroundColor(.white)
                                .lineLimit(1)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(22)
        .frame(width: 420)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(.ultraThickMaterial))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(Color.white.opacity(0.22), lineWidth: 1))
    }
}
