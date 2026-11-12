import SwiftUI
import AppKit
import UniformTypeIdentifiers
import SideDockCore
import SideDockWidgets
import MacStashCore
import MacStashDesignSystem

public struct DockTileView: View {
    public let item: DockItem
    public let placement: DockPlacement
    public let baseTileSize: CGFloat
    public let tileSpacing: CGFloat
    public let magnificationScale: CGFloat
    public let liftOffset: CGFloat
    public let isRunning: Bool
    public let isActiveApp: Bool
    public let badgeLabel: String?
    public let indicatorStyle: DockIndicatorStyle
    public let showTooltips: Bool
    public let isEditMode: Bool
    public let isBouncing: Bool
    public let trashItemCount: Int
    public let reduceMotion: Bool
    public let runningApps: [RunningAppInfo]
    public let badgesByBundleID: [String: String]
    public let callbacks: DockInteractionCallbacks

    @State private var isHovered: Bool = false
    @State private var isPressed: Bool = false
    @State private var isDropTargeted: Bool = false
    @State private var showFolderPopover: Bool = false
    @State private var windowRect: CGRect = .zero

    public init(
        item: DockItem,
        placement: DockPlacement = .fixedBottom,
        baseTileSize: CGFloat,
        tileSpacing: CGFloat,
        magnificationScale: CGFloat = 1.0,
        liftOffset: CGFloat = 0.0,
        isRunning: Bool = false,
        isActiveApp: Bool = false,
        badgeLabel: String? = nil,
        indicatorStyle: DockIndicatorStyle = .dot,
        showTooltips: Bool = true,
        isEditMode: Bool = false,
        isBouncing: Bool = false,
        trashItemCount: Int = 0,
        reduceMotion: Bool = false,
        runningApps: [RunningAppInfo] = [],
        badgesByBundleID: [String: String] = [:],
        callbacks: DockInteractionCallbacks
    ) {
        self.item = item
        self.placement = placement
        self.baseTileSize = baseTileSize
        self.tileSpacing = tileSpacing
        self.magnificationScale = magnificationScale
        self.liftOffset = liftOffset
        self.isRunning = isRunning
        self.isActiveApp = isActiveApp
        self.badgeLabel = badgeLabel
        self.indicatorStyle = indicatorStyle
        self.showTooltips = showTooltips
        self.isEditMode = isEditMode
        self.isBouncing = isBouncing
        self.trashItemCount = trashItemCount
        self.reduceMotion = reduceMotion
        self.runningApps = runningApps
        self.badgesByBundleID = badgesByBundleID
        self.callbacks = callbacks
    }

    private func localized(_ key: String) -> String {
        LocalizationService.shared.localized(key)
    }

    private var isVertical: Bool { placement.isVertical }
    private var effectiveTileSize: CGFloat { baseTileSize * magnificationScale }

    private var directionalOffset: CGSize {
        let magnitude = liftOffset + (isBouncing ? 10.0 : 0.0)
        switch placement {
        case .fixedBottom, .floating: return CGSize(width: 0, height: -magnitude)
        case .fixedTop: return CGSize(width: 0, height: magnitude)
        case .fixedLeft: return CGSize(width: magnitude, height: 0)
        case .fixedRight: return CGSize(width: -magnitude, height: 0)
        }
    }

    public var body: some View {
        ZStack(alignment: .topTrailing) {
            tileContent
                .scaleEffect(isPressed ? 0.90 : 1.0)
                .offset(directionalOffset)
                .animation(reduceMotion ? nil : .spring(response: 0.22, dampingFraction: 0.65), value: isPressed)
                .animation(reduceMotion ? nil : .interpolatingSpring(stiffness: 260, damping: 14), value: isBouncing)

            if isEditMode && item.isInteractive {
                Button {
                    callbacks.onRemoveItem(item.id)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(.white, .red)
                        .shadow(radius: 1.5)
                }
                .buttonStyle(.plain)
                .offset(x: 4, y: -4)
            }
        }
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear { windowRect = geo.frame(in: .global) }
                    .onChange(of: geo.frame(in: .global)) { _, newFrame in
                        windowRect = newFrame
                    }
            }
        )
        .onHover { hovered in
            isHovered = hovered
            handleHoverChanged(hovered)
        }
    }

    @ViewBuilder
    private var tileContent: some View {
        switch item {
        case .app(let appItem):
            appTileView(appItem)
        case .folder(let folderItem):
            folderTileView(folderItem)
        case .appFolder(let appFolder):
            AppFolderTileView(
                folder: appFolder,
                tileSize: effectiveTileSize,
                runningApps: runningApps,
                badgesByBundleID: badgesByBundleID,
                onRemove: { callbacks.onRemoveItem(appFolder.id) }
            )
        case .widget(let widgetItem):
            widgetTileView(widgetItem)
        case .smartStack(let stack):
            SmartStackTileView(
                stack: stack,
                baseTileSize: baseTileSize,
                tileSpacing: tileSpacing,
                onCycle: { delta in callbacks.onCycleSmartStack(stack.id, delta) },
                onExpand: { widget in callbacks.onExpandWidget(widget, windowRect) }
            )
        case .action(let actionItem):
            actionTileView(actionItem)
        case .launchpad:
            launchpadTileView
        case .trash:
            TrashTileView(
                itemCount: trashItemCount,
                tileSize: effectiveTileSize,
                onOpenTrash: callbacks.onOpenTrash,
                onEmptyTrash: callbacks.onEmptyTrash,
                onDropFiles: callbacks.onDropFilesToTrash,
                onRemove: { callbacks.onRemoveItem(item.id) }
            )
        case .separator:
            Rectangle()
                .fill(Color.primary.opacity(0.20))
                .frame(width: isVertical ? baseTileSize * 0.6 : 1.2, height: isVertical ? 1.2 : baseTileSize * 0.6)
                .padding(isVertical ? .vertical : .horizontal, 2)
        case .spacer(_, let width):
            Color.clear
                .frame(width: isVertical ? baseTileSize : max(6, width), height: isVertical ? max(6, width) : baseTileSize)
        }
    }

    private func appTileView(_ appItem: AppItem) -> some View {
        let showFace = appItem.showWidgetFace && appItem.widgetFaceKind != nil
        return Button {
            pressFeedback()
            callbacks.onLaunchApp(appItem)
            DockTileActions.launchApp(appItem)
        } label: {
            tileStack {
                ZStack(alignment: .topTrailing) {
                    if showFace, let faceKind = appItem.widgetFaceKind {
                        AppWidgetFaceRegistry.makeFaceView(widgetKind: faceKind)
                            .frame(width: effectiveTileSize, height: effectiveTileSize)
                            .background(
                                RoundedRectangle(cornerRadius: 11, style: .continuous)
                                    .fill(Color.primary.opacity(0.08))
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                    } else {
                        Image(nsImage: resolvedAppIcon(appItem, size: effectiveTileSize * 0.88))
                            .resizable()
                            .interpolation(.high)
                            .antialiased(true)
                            .frame(width: effectiveTileSize * 0.88, height: effectiveTileSize * 0.88)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }

                    DockBadgeView(label: badgeLabel)
                        .offset(x: 4, y: -4)
                }
                .frame(width: effectiveTileSize, height: effectiveTileSize)

                DockRunningIndicatorView(
                    isRunning: isRunning,
                    isActive: isActiveApp,
                    style: indicatorStyle,
                    isVertical: isVertical
                )
            }
            .padding(2)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isDropTargeted ? Color.accentColor.opacity(0.25) : (isHovered ? Color.primary.opacity(0.09) : Color.clear))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
            DockTileActions.extractDroppedURLs(from: providers) { urls in
                callbacks.onDropFilesToApp(urls, appItem)
            }
            return true
        }
        .contextMenu {
            let defaultFace = AppWidgetFaceRegistry.defaultWidgetKind(forBundleID: appItem.bundleIdentifier) ?? appItem.widgetFaceKind
            AppTileContextMenuContent(
                bundleID: appItem.bundleIdentifier,
                displayName: appItem.displayName,
                appPath: appItem.appPath,
                isPinned: true,
                isRunning: isRunning,
                showWidgetFace: appItem.showWidgetFace,
                customIconPath: appItem.customIconPath,
                isEditMode: isEditMode,
                onOpen: {
                    callbacks.onLaunchApp(appItem)
                    DockTileActions.launchApp(appItem)
                },
                onShowInFinder: { DockTileActions.showInFinder(appItem) },
                onShowAllWindows: { callbacks.onShowAppWindows(appItem.bundleIdentifier, appItem.displayName, windowRect) },
                onToggleWidgetFace: { callbacks.onToggleAppWidgetFace(appItem.id) },
                onExpandWidgetFace: defaultFace.map { face in
                    { callbacks.onExpandWidget(WidgetItem(widgetKind: face, size: .medium), windowRect) }
                },
                onPickCustomIcon: {
                    DockTileActions.pickCustomIcon { url in
                        callbacks.onSetCustomAppIcon(appItem.id, url)
                    }
                },
                onResetCustomIcon: { callbacks.onResetCustomAppIcon(appItem.id) },
                onHide: { DockTileActions.hideApp(appItem) },
                onHideOthers: { callbacks.onHideOtherApps(appItem.bundleIdentifier) },
                onQuit: { DockTileActions.quitApp(appItem) },
                onForceQuit: { DockTileActions.forceQuitApp(appItem) },
                onExecuteCuratedAction: { callbacks.onExecuteAction($0) },
                onToggleEditMode: callbacks.onToggleEditMode,
                onRemove: { callbacks.onRemoveItem(appItem.id) }
            )
        }
    }

    private func folderTileView(_ folderItem: FolderItem) -> some View {
        let expanded = (folderItem.folderPath as NSString).expandingTildeInPath
        return Button {
            pressFeedback()
            if folderItem.clickAction == .openInFinder {
                NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: expanded)
            } else {
                showFolderPopover.toggle()
            }
        } label: {
            Image(nsImage: AppIconCache.shared.icon(forPath: expanded, targetSize: NSSize(width: effectiveTileSize * 0.85, height: effectiveTileSize * 0.85)))
                .resizable()
                .interpolation(.high)
                .frame(width: effectiveTileSize * 0.85, height: effectiveTileSize * 0.85)
                .frame(width: effectiveTileSize, height: effectiveTileSize)
                .background(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(isHovered ? Color.primary.opacity(0.09) : Color.clear)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showFolderPopover, arrowEdge: .top) {
            FolderPopoverView(folderItem: folderItem) { newStyle, newSort in
                callbacks.onUpdateFolderPreferences(folderItem.id, newStyle, newSort)
            }
        }
        .contextMenu {
            Button(localized("dock.openInFinder")) {
                NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: expanded)
            }
            Divider()
            Button(localized("dock.remove"), role: .destructive) {
                callbacks.onRemoveItem(folderItem.id)
            }
        }
    }

    private func widgetTileView(_ widgetItem: WidgetItem) -> some View {
        let width = widgetItem.size.width(forBaseTileSize: Double(baseTileSize), spacing: Double(tileSpacing))
        return ZStack(alignment: .topTrailing) {
            WidgetRegistry.shared.makeWidgetView(for: widgetItem)
                .frame(minWidth: width, minHeight: baseTileSize, maxHeight: max(baseTileSize, 56))
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isHovered ? Color.primary.opacity(0.10) : Color.primary.opacity(0.055))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.primary.opacity(isHovered ? 0.18 : 0.09), lineWidth: 0.7)
                )

            if isHovered && !isEditMode {
                Button {
                    callbacks.onExpandWidget(widgetItem, windowRect)
                } label: {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 8.5, weight: .bold))
                        .foregroundColor(.primary)
                        .padding(3.5)
                        .background(Circle().fill(.regularMaterial))
                }
                .buttonStyle(.plain)
                .offset(x: -3, y: 3)
            }
        }
        .contentShape(Rectangle())
        .contextMenu {
            Button(localized("dock.expandWidget")) { callbacks.onExpandWidget(widgetItem, windowRect) }
            Button(localized("dock.configureWidget")) { callbacks.onConfigureWidget(widgetItem) }
            Menu(localized("dock.widgetSize")) {
                Button(localized("dock.sizeSmall")) { callbacks.onResizeWidget(widgetItem.id, .small) }
                Button(localized("dock.sizeMedium")) { callbacks.onResizeWidget(widgetItem.id, .medium) }
                Button(localized("dock.sizeLarge")) { callbacks.onResizeWidget(widgetItem.id, .large) }
            }
            Divider()
            Button(localized("dock.removeWidget"), role: .destructive) { callbacks.onRemoveItem(widgetItem.id) }
        }
    }

    private func actionTileView(_ actionItem: DockActionItem) -> some View {
        Button {
            pressFeedback()
            callbacks.onExecuteAction(actionItem)
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(Color.accentColor.opacity(isHovered ? 0.22 : 0.13))
                Image(systemName: actionItem.systemIconName)
                    .font(.system(size: effectiveTileSize * 0.42, weight: .semibold))
                    .foregroundColor(.accentColor)
            }
            .frame(width: effectiveTileSize, height: effectiveTileSize)
            .overlay(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .strokeBorder(Color.accentColor.opacity(0.28), lineWidth: 0.8)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(localized("dock.runAction")) { callbacks.onExecuteAction(actionItem) }
            Divider()
            Button(localized("dock.remove"), role: .destructive) { callbacks.onRemoveItem(actionItem.id) }
        }
    }

    private var launchpadTileView: some View {
        Button {
            pressFeedback()
            callbacks.onOpenLaunchpad()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.85), Color.purple.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Image(systemName: "square.grid.3x3.fill")
                    .font(.system(size: effectiveTileSize * 0.44, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(width: effectiveTileSize, height: effectiveTileSize)
            .shadow(color: Color.black.opacity(0.18), radius: 3, y: 1.5)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(localized("dock.openLaunchpad")) { callbacks.onOpenLaunchpad() }
            Divider()
            Button(localized("dock.remove"), role: .destructive) { callbacks.onRemoveItem(item.id) }
        }
    }

    @ViewBuilder
    private func tileStack<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        if isVertical {
            HStack(spacing: 3) { content() }
        } else {
            VStack(spacing: 3) { content() }
        }
    }

    private func handleHoverChanged(_ hovered: Bool) {
        if hovered {
            if showTooltips && item.isInteractive {
                callbacks.onHoverTooltipChanged(item.displayName, windowRect)
            }
            if case .app(let appItem) = item, isRunning {
                callbacks.onHoverAppChanged(appItem.bundleIdentifier, appItem.displayName, windowRect)
            } else {
                callbacks.onHoverAppChanged(nil, nil, nil)
            }
        } else {
            callbacks.onHoverTooltipChanged(nil, nil)
            if case .app = item {
                callbacks.onHoverAppChanged(nil, nil, nil)
            }
        }
    }

    private func pressFeedback() {
        guard !reduceMotion else { return }
        isPressed = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            isPressed = false
        }
    }

    private func resolvedAppIcon(_ appItem: AppItem, size: CGFloat) -> NSImage {
        let target = NSSize(width: size, height: size)
        if let custom = appItem.customIconPath,
           FileManager.default.fileExists(atPath: custom),
           let img = NSImage(contentsOfFile: custom) {
            return img
        }
        if FileManager.default.fileExists(atPath: appItem.appPath) {
            return AppIconCache.shared.icon(forPath: appItem.appPath, targetSize: target)
        }
        return AppIconCache.shared.icon(forBundleID: appItem.bundleIdentifier, targetSize: target)
            ?? NSImage(systemSymbolName: "app.fill", accessibilityDescription: appItem.displayName)
            ?? NSImage()
    }
}
