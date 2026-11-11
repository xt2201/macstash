import SwiftUI
import AppKit
import SideDockCore
import SideDockWidgets
import MacStashCore

public struct DockTileView: View {
    public let item: DockItem
    public let isVertical: Bool
    public let isRunning: Bool
    public let reduceMotion: Bool
    public let onRemove: () -> Void
    public let onResize: ((WidgetSize) -> Void)?
    public let onConfigure: (() -> Void)?

    @State private var isHovered: Bool = false
    @State private var showFolderPopover: Bool = false

    private func localized(_ key: String) -> String {
        LocalizationService.shared.localized(key)
    }

    public init(
        item: DockItem,
        isVertical: Bool = false,
        isRunning: Bool = false,
        reduceMotion: Bool = false,
        onRemove: @escaping () -> Void,
        onResize: ((WidgetSize) -> Void)? = nil,
        onConfigure: (() -> Void)? = nil
    ) {
        self.item = item
        self.isVertical = isVertical
        self.isRunning = isRunning
        self.reduceMotion = reduceMotion
        self.onRemove = onRemove
        self.onResize = onResize
        self.onConfigure = onConfigure
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
                    .frame(width: isVertical ? 26 : 1, height: isVertical ? 1 : 26)
                    .padding(isVertical ? .vertical : .horizontal, 2)
            case .spacer(_, let width):
                Spacer()
                    .frame(width: isVertical ? 44 : max(4, width), height: isVertical ? max(4, width) : 44)
            }
        }
        .scaleEffect(reduceMotion ? 1.0 : (isHovered ? 1.06 : 1.0))
        .animation(reduceMotion ? nil : .spring(response: 0.2, dampingFraction: 0.7), value: isHovered)
        .onHover { hovered in
            isHovered = hovered
        }
    }

    // MARK: - App Tile

    private func appTileView(_ appItem: AppItem) -> some View {
        Button {
            launchApp(appItem)
        } label: {
            VStack(spacing: 2) {
                ZStack {
                    if let icon = getAppIcon(appItem) {
                        Image(nsImage: icon)
                            .resizable()
                            .interpolation(.high)
                            .antialiased(true)
                            .frame(width: 36, height: 36)
                    } else {
                        Image(systemName: "app.fill")
                            .font(.system(size: 26))
                            .foregroundColor(.accentColor)
                    }
                }
                .frame(width: 40, height: 38)

                Circle()
                    .fill(isRunning ? Color.primary.opacity(0.85) : Color.clear)
                    .frame(width: 4, height: 4)
            }
            .frame(width: 44, height: 46)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isHovered ? Color.primary.opacity(0.08) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(appItem.displayName)
        .contextMenu {
            Button(localized("dock.open")) {
                launchApp(appItem)
            }
            Button(localized("dock.openInFinder")) {
                showInFinder(appItem)
            }
            Divider()
            if isAppRunning(appItem) {
                Button(localized("dock.hide")) {
                    hideApp(appItem)
                }
                if NSEvent.modifierFlags.contains(.option) {
                    Button(localized("dock.forceQuit")) {
                        forceQuitApp(appItem)
                    }
                } else {
                    Button(localized("dock.quit")) {
                        quitApp(appItem)
                    }
                }
                Divider()
            }
            Button(localized("dock.remove")) {
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
                    .frame(width: 36, height: 36)
            }
            .frame(width: 44, height: 46)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isHovered ? Color.primary.opacity(0.08) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(folderItem.displayName)
        .popover(isPresented: $showFolderPopover, arrowEdge: .top) {
            FolderPopoverView(folderItem: folderItem)
        }
        .contextMenu {
            Button(localized("dock.openInFinder")) {
                let expanded = (folderItem.folderPath as NSString).expandingTildeInPath
                NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: expanded)
            }
            Divider()
            Button(localized("dock.remove")) {
                onRemove()
            }
        }
    }

    // MARK: - Widget Tile

    private func widgetTileView(_ widgetItem: WidgetItem) -> some View {
        WidgetRegistry.shared.makeWidgetView(for: widgetItem)
            .frame(minHeight: 44)
            .background(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(isHovered ? Color.primary.opacity(0.09) : Color.primary.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .strokeBorder(Color.primary.opacity(isHovered ? 0.16 : 0.08), lineWidth: 0.7)
            )
            .contentShape(Rectangle())
            .contextMenu {
                if let onConfigure {
                    Button(localized("dock.configureWidget")) {
                        onConfigure()
                    }
                    Divider()
                }
                Menu(localized("dock.widgetSize")) {
                    Button(localized("dock.sizeSmall")) { onResize?(.small) }
                    Button(localized("dock.sizeMedium")) { onResize?(.medium) }
                    Button(localized("dock.sizeLarge")) { onResize?(.large) }
                }
                Divider()
                Button(localized("dock.removeWidget")) {
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
