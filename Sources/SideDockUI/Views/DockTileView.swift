import SwiftUI
import AppKit
import SideDockCore
import SideDockWidgets

public struct DockTileView: View {
    public let item: DockItem
    public let onRemove: () -> Void
    public let onResize: ((WidgetSize) -> Void)?
    @State private var isHovered: Bool = false
    @State private var showFolderPopover: Bool = false

    public init(
        item: DockItem,
        onRemove: @escaping () -> Void,
        onResize: ((WidgetSize) -> Void)? = nil
    ) {
        self.item = item
        self.onRemove = onRemove
        self.onResize = onResize
    }

    public var body: some View {
        Group {
            switch item {
            case .app(let appItem):
                appTileView(appItem)
            case .folder(let folderItem):
                folderTileView(folderItem)
            case .widget(let widgetItem):
                widgetTileView(widgetItem)
            case .separator:
                Rectangle()
                    .fill(Color.primary.opacity(0.18))
                    .frame(width: 1, height: 26)
                    .padding(.horizontal, 2)
            case .spacer(_, let width):
                Spacer()
                    .frame(width: max(4, width))
            }
        }
        .scaleEffect(isHovered ? 1.06 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isHovered)
        .onHover { hovered in
            isHovered = hovered
        }
    }

    // MARK: - App Tile

    private func appTileView(_ appItem: AppItem) -> some View {
        Button {
            launchApp(appItem)
        } label: {
            ZStack {
                if let icon = getAppIcon(appItem) {
                    Image(nsImage: icon)
                        .resizable()
                        .interpolation(.high)
                        .antialiased(true)
                        .frame(width: 38, height: 38)
                } else {
                    Image(systemName: "app.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.accentColor)
                }
            }
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(appItem.displayName)
        .contextMenu {
            Button("Open") {
                launchApp(appItem)
            }
            Button("Show in Finder") {
                showInFinder(appItem)
            }
            Divider()
            if isAppRunning(appItem) {
                Button("Hide") {
                    hideApp(appItem)
                }
                if NSEvent.modifierFlags.contains(.option) {
                    Button("Force Quit") {
                        forceQuitApp(appItem)
                    }
                } else {
                    Button("Quit") {
                        quitApp(appItem)
                    }
                }
                Divider()
            }
            Button("Remove from Dock") {
                onRemove()
            }
        }
    }

    // MARK: - Folder Tile

    private func folderTileView(_ folderItem: FolderItem) -> some View {
        Button {
            if folderItem.clickAction == .openInFinder {
                let expanded = (folderItem.folderPath as NSString).expandingTildeInPath
                NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: expanded)
            } else {
                showFolderPopover.toggle()
            }
        } label: {
            ZStack {
                let expanded = (folderItem.folderPath as NSString).expandingTildeInPath
                let icon = NSWorkspace.shared.icon(forFile: expanded)
                Image(nsImage: icon)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: 38, height: 38)
            }
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(folderItem.displayName)
        .popover(isPresented: $showFolderPopover, arrowEdge: .top) {
            FolderPopoverView(folderItem: folderItem)
        }
        .contextMenu {
            Button("Open in Finder") {
                let expanded = (folderItem.folderPath as NSString).expandingTildeInPath
                NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: expanded)
            }
            Divider()
            Button("Remove from Dock") {
                onRemove()
            }
        }
    }

    // MARK: - Widget Tile

    private func widgetTileView(_ widgetItem: WidgetItem) -> some View {
        WidgetRegistry.shared.makeWidgetView(for: widgetItem)
            .contentShape(Rectangle())
            .contextMenu {
                Menu("Widget Size") {
                    Button("Small") { onResize?(.small) }
                    Button("Medium") { onResize?(.medium) }
                    Button("Large") { onResize?(.large) }
                }
                Divider()
                Button("Remove Widget") {
                    onRemove()
                }
            }
    }

    // MARK: - Actions

    private func getAppIcon(_ appItem: AppItem) -> NSImage? {
        if let custom = appItem.customIconPath, FileManager.default.fileExists(atPath: custom) {
            return NSImage(contentsOfFile: custom)
        }
        if FileManager.default.fileExists(atPath: appItem.appPath) {
            return NSWorkspace.shared.icon(forFile: appItem.appPath)
        }
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: appItem.bundleIdentifier) {
            return NSWorkspace.shared.icon(forFile: url.path)
        }
        return nil
    }

    private func isAppRunning(_ appItem: AppItem) -> Bool {
        !NSRunningApplication.runningApplications(withBundleIdentifier: appItem.bundleIdentifier).isEmpty
    }

    private func launchApp(_ appItem: AppItem) {
        if FileManager.default.fileExists(atPath: appItem.appPath) {
            NSWorkspace.shared.open(URL(fileURLWithPath: appItem.appPath))
        } else if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: appItem.bundleIdentifier) {
            NSWorkspace.shared.open(url)
        }
    }

    private func showInFinder(_ appItem: AppItem) {
        if FileManager.default.fileExists(atPath: appItem.appPath) {
            NSWorkspace.shared.selectFile(appItem.appPath, inFileViewerRootedAtPath: "")
        }
    }

    private func hideApp(_ appItem: AppItem) {
        let apps = NSRunningApplication.runningApplications(withBundleIdentifier: appItem.bundleIdentifier)
        for app in apps {
            app.hide()
        }
    }

    private func quitApp(_ appItem: AppItem) {
        let apps = NSRunningApplication.runningApplications(withBundleIdentifier: appItem.bundleIdentifier)
        for app in apps {
            app.terminate()
        }
    }

    private func forceQuitApp(_ appItem: AppItem) {
        let apps = NSRunningApplication.runningApplications(withBundleIdentifier: appItem.bundleIdentifier)
        for app in apps {
            app.forceTerminate()
        }
    }
}
