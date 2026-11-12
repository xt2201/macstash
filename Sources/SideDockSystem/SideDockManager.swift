import AppKit
import SwiftUI
import os.log
import SideDockCore
import SideDockWidgets
import SideDockUI

@MainActor
public final class SideDockManager: ObservableObject {
    public static let shared = SideDockManager()
    private nonisolated static let logger = Logger(subsystem: "com.macstash.app", category: "sidedock")

    public let configStore: DockConfigStore
    public var onOpenSettings: (@MainActor () -> Void)?

    private var dockPanel: SideDockPanel?
    private var hostingView: SideDockHostingView<SideDockRootWrapper>?
    private var edgeTrigger: EdgeTriggerManager?
    private var runningAppsMonitor = RunningAppsMonitor.shared
    private let layoutEngine = DockLayoutEngine()

    private let tooltipController = DockTooltipPanelController()
    private let widgetExpansionController = WidgetExpansionPanelController()
    private let windowPreviewController = WindowPreviewPanelController()
    private let badgeMonitor = DockBadgeMonitor()
    private let trashMonitor = TrashMonitor()
    private let profileTriggerEngine = ProfileTriggerEngine()

    private var dragStartMouseLocation: CGPoint?
    private var dragStartPanelOrigin: CGPoint?
    private var lastNativeDockCoordinateState: Bool?

    @Published public var config: SideDockFileConfig
    @Published public var runningApps: [RunningAppInfo] = []
    @Published public var runtimeState: DockRuntimeState = DockRuntimeState()
    @Published public var isRevealed: Bool = true

    public init(configStore: DockConfigStore = DockConfigStore()) {
        self.configStore = configStore
        self.config = configStore.config

        ActionExecutionService.shared.onTriggerLaunchpad = { [weak self] in
            self?.toggleLaunchpad()
        }
        ActionExecutionService.shared.onTriggerWindowSwitcher = { [weak self] in
            self?.toggleWindowSwitcher()
        }
        LaunchpadOverlayController.shared.onLayoutUpdated = { [weak self] updatedLayout in
            guard let self else { return }
            self.configStore.updateConfig { $0.launchpadLayout = updatedLayout }
            self.config = self.configStore.config
        }

        self.runningAppsMonitor.setChangeHandler { [weak self] apps in
            Task { @MainActor in
                self?.runningApps = apps
                self?.refreshMinimizedWindows()
                self?.updateDockLayout()
            }
        }

        setupNotificationObservers()
        setupDockPanel()
        reconfigureBackgroundMonitors()
    }

    public var activeProfile: DockProfile {
        if let found = config.profiles.first(where: { $0.id == config.activeProfileId }) {
            return found
        }
        return configStore.activeProfile()
    }

    // MARK: - Core Actions

    public func toggleDock() {
        configStore.updateConfig { $0.isDockVisible.toggle() }
        self.config = configStore.config
        applyVisibility()
        reconfigureEdgeTrigger()
        reconfigureBackgroundMonitors()
    }

    public func setDockVisible(_ visible: Bool) {
        configStore.updateConfig { $0.isDockVisible = visible }
        self.config = configStore.config
        applyVisibility()
        reconfigureEdgeTrigger()
        reconfigureBackgroundMonitors()
    }

    public func toggleLaunchpad() {
        LaunchpadOverlayController.shared.toggle(layoutConfig: config.launchpadLayout)
    }

    public func toggleWindowSwitcher() {
        guard config.windowSwitcherEnabled else { return }
        WindowSwitcherController.shared.toggle()
    }

    public func selectProfile(_ id: UUID) {
        configStore.updateConfig { $0.activeProfileId = id }
        self.config = configStore.config
        updateDockLayout()
    }

    public func selectProfile(at index: Int) {
        guard index >= 0 && index < config.profiles.count else { return }
        selectProfile(config.profiles[index].id)
    }

    public func triggerLaunchBounce(for itemID: UUID) {
        performDockInteractionFeedback()
        guard activeProfile.layoutConfig.bounceOnLaunch,
              !activeProfile.theme.reduceMotion else { return }
        runtimeState.bouncingItemID = itemID
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            if self?.runtimeState.bouncingItemID == itemID {
                self?.runtimeState.bouncingItemID = nil
            }
        }
    }

    public func toggleEditMode() {
        runtimeState.isEditMode.toggle()
    }

    public func removeItem(_ id: UUID) {
        configStore.updateConfig { cfg in
            if let idx = cfg.profiles.firstIndex(where: { $0.id == cfg.activeProfileId }) {
                cfg.profiles[idx].items.removeAll(where: { $0.id == id })
            }
        }
        self.config = configStore.config
        updateDockLayout()
    }

    public func moveItem(fromID: UUID, toID: UUID) {
        guard fromID != toID else { return }
        configStore.updateConfig { cfg in
            guard let pIdx = cfg.profiles.firstIndex(where: { $0.id == cfg.activeProfileId }) else { return }
            var items = cfg.profiles[pIdx].items
            guard let fromIdx = items.firstIndex(where: { $0.id == fromID }),
                  let toIdx = items.firstIndex(where: { $0.id == toID }) else { return }
            let moved = items.remove(at: fromIdx)
            items.insert(moved, at: toIdx)
            cfg.profiles[pIdx].items = items
        }
        self.config = configStore.config
        updateDockLayout()
    }

    public func pinExternalURLs(_ urls: [URL], at insertIndex: Int?) {
        var addedItems: [DockItem] = []
        for url in urls {
            var isDir: ObjCBool = false
            guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) else { continue }
            if url.pathExtension == "app" {
                let bundle = Bundle(url: url)
                let bid = bundle?.bundleIdentifier ?? url.deletingPathExtension().lastPathComponent
                let name = FileManager.default.displayName(atPath: url.path).replacingOccurrences(of: ".app", with: "")
                let face = AppWidgetFaceRegistry.defaultWidgetKind(forBundleID: bid)
                addedItems.append(.app(AppItem(bundleIdentifier: bid, displayName: name, appPath: url.path, widgetFaceKind: face)))
            } else if isDir.boolValue {
                addedItems.append(.folder(FolderItem(folderPath: url.path, displayName: url.lastPathComponent)))
            }
        }
        guard !addedItems.isEmpty else { return }

        configStore.updateConfig(immediate: true) { cfg in
            guard let pIdx = cfg.profiles.firstIndex(where: { $0.id == cfg.activeProfileId }) else { return }
            if let idx = insertIndex, idx >= 0 && idx <= cfg.profiles[pIdx].items.count {
                cfg.profiles[pIdx].items.insert(contentsOf: addedItems, at: idx)
            } else {
                cfg.profiles[pIdx].items.append(contentsOf: addedItems)
            }
        }
        self.config = configStore.config
        updateDockLayout()
    }

    public func openFiles(_ urls: [URL], withApp appItem: AppItem) {
        let appURL: URL? = FileManager.default.fileExists(atPath: appItem.appPath)
            ? URL(fileURLWithPath: appItem.appPath)
            : NSWorkspace.shared.urlForApplication(withBundleIdentifier: appItem.bundleIdentifier)
        guard let targetAppURL = appURL else { return }
        NSWorkspace.shared.open(urls, withApplicationAt: targetAppURL, configuration: NSWorkspace.OpenConfiguration())
    }

    public func recycleFilesToTrash(_ urls: [URL]) {
        NSWorkspace.shared.recycle(urls) { _, error in
            if let error {
                Self.logger.warning("Recycle to trash failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    public func cycleSmartStack(id: UUID, delta: Int) {
        configStore.updateConfig { cfg in
            guard let pIdx = cfg.profiles.firstIndex(where: { $0.id == cfg.activeProfileId }),
                  let iIdx = cfg.profiles[pIdx].items.firstIndex(where: { $0.id == id }),
                  case .smartStack(var stack) = cfg.profiles[pIdx].items[iIdx],
                  !stack.widgets.isEmpty else { return }
            let count = stack.widgets.count
            stack.activeIndex = ((stack.activeIndex + delta) % count + count) % count
            cfg.profiles[pIdx].items[iIdx] = .smartStack(stack)
        }
        self.config = configStore.config
    }

    public func toggleAppWidgetFace(id: UUID) {
        configStore.updateConfig(immediate: true) { cfg in
            guard let pIdx = cfg.profiles.firstIndex(where: { $0.id == cfg.activeProfileId }),
                  let iIdx = cfg.profiles[pIdx].items.firstIndex(where: { $0.id == id }),
                  case .app(var appItem) = cfg.profiles[pIdx].items[iIdx] else { return }
            if appItem.widgetFaceKind == nil {
                appItem.widgetFaceKind = AppWidgetFaceRegistry.defaultWidgetKind(forBundleID: appItem.bundleIdentifier)
            }
            appItem.showWidgetFace.toggle()
            cfg.profiles[pIdx].items[iIdx] = .app(appItem)
        }
        self.config = configStore.config
    }

    public func setCustomAppIcon(id: UUID, sourceURL: URL) {
        guard let savedPath = CustomIconStorage.importCustomIcon(from: sourceURL, itemID: id) else { return }
        configStore.updateConfig(immediate: true) { cfg in
            guard let pIdx = cfg.profiles.firstIndex(where: { $0.id == cfg.activeProfileId }),
                  let iIdx = cfg.profiles[pIdx].items.firstIndex(where: { $0.id == id }),
                  case .app(var appItem) = cfg.profiles[pIdx].items[iIdx] else { return }
            appItem.customIconPath = savedPath
            cfg.profiles[pIdx].items[iIdx] = .app(appItem)
        }
        self.config = configStore.config
    }

    public func resetCustomAppIcon(id: UUID) {
        configStore.updateConfig(immediate: true) { cfg in
            guard let pIdx = cfg.profiles.firstIndex(where: { $0.id == cfg.activeProfileId }),
                  let iIdx = cfg.profiles[pIdx].items.firstIndex(where: { $0.id == id }),
                  case .app(var appItem) = cfg.profiles[pIdx].items[iIdx] else { return }
            CustomIconStorage.removeCustomIcon(at: appItem.customIconPath)
            appItem.customIconPath = nil
            cfg.profiles[pIdx].items[iIdx] = .app(appItem)
        }
        self.config = configStore.config
    }

    public func resizeWidget(id: UUID, newSize: WidgetSize) {
        configStore.updateConfig { cfg in
            if let profIdx = cfg.profiles.firstIndex(where: { $0.id == cfg.activeProfileId }),
               let itemIdx = cfg.profiles[profIdx].items.firstIndex(where: { $0.id == id }) {
                if case .widget(var wItem) = cfg.profiles[profIdx].items[itemIdx] {
                    wItem.size = newSize
                    cfg.profiles[profIdx].items[itemIdx] = .widget(wItem)
                }
            }
        }
        self.config = configStore.config
        updateDockLayout()
    }

    public func resetLayout() {
        configStore.resetLayout()
        self.config = configStore.config
        updateDockLayout()
    }

    // MARK: - Popover / Hover / Drag Coordination

    public func showTooltip(_ text: String?, localRect: CGRect?) {
        guard let text, let localRect, let screen = resolveScreen() else {
            tooltipController.hide()
            return
        }
        let sRect = screenRect(fromWindowLocalRect: localRect)
        tooltipController.show(
            text: text,
            anchorScreenRect: sRect,
            placement: activeProfile.layoutConfig.placement,
            screenVisibleFrame: screen.visibleFrame
        )
    }

    public func handleAppHover(bundleID: String?, appName: String?, localRect: CGRect?, immediate: Bool = false) {
        let prof = activeProfile
        guard (prof.layoutConfig.showWindowPreviewsOnHover || immediate),
              let screen = resolveScreen() else {
            windowPreviewController.hideImmediately()
            return
        }
        let sRect = localRect.map { screenRect(fromWindowLocalRect: $0) }
        windowPreviewController.handleAppHover(
            bundleID: bundleID,
            appName: appName,
            anchorScreenRect: sRect,
            placement: prof.layoutConfig.placement,
            screenVisibleFrame: screen.visibleFrame,
            delaySeconds: prof.layoutConfig.windowPreviewHoverDelaySeconds,
            immediate: immediate
        )
    }

    public func expandWidget(_ widget: WidgetItem, localRect: CGRect) {
        guard let screen = resolveScreen() else { return }
        let sRect = screenRect(fromWindowLocalRect: localRect)
        widgetExpansionController.show(
            widget: widget,
            anchorScreenRect: sRect,
            placement: activeProfile.layoutConfig.placement,
            screenVisibleFrame: screen.visibleFrame
        )
    }

    public func beginFloatingDrag() {
        guard activeProfile.layoutConfig.placement == .floating, let panel = dockPanel else { return }
        dragStartMouseLocation = NSEvent.mouseLocation
        dragStartPanelOrigin = panel.frame.origin
    }

    public func updateFloatingDrag() {
        let prof = activeProfile
        guard prof.layoutConfig.placement == .floating,
              let panel = dockPanel,
              let startMouse = dragStartMouseLocation,
              let startOrigin = dragStartPanelOrigin,
              let screen = panel.screen ?? NSScreen.main else { return }

        let currentMouse = NSEvent.mouseLocation
        let proposed = CGPoint(
            x: startOrigin.x + (currentMouse.x - startMouse.x),
            y: startOrigin.y + (currentMouse.y - startMouse.y)
        )
        let clamped = layoutEngine.clampFloatingCoordinates(
            proposedPoint: proposed,
            dockSize: panel.frame.size,
            screenBounds: screen.visibleFrame
        )
        panel.setFrameOrigin(clamped)
    }

    public func endFloatingDrag() {
        defer {
            dragStartMouseLocation = nil
            dragStartPanelOrigin = nil
        }
        guard activeProfile.layoutConfig.placement == .floating, let panel = dockPanel else { return }
        let origin = panel.frame.origin
        configStore.updateConfig(immediate: true) { cfg in
            if let idx = cfg.profiles.firstIndex(where: { $0.id == cfg.activeProfileId }) {
                cfg.profiles[idx].layoutConfig.floatingX = origin.x
                cfg.profiles[idx].layoutConfig.floatingY = origin.y
            }
        }
        self.config = configStore.config
    }

    // MARK: - Panel Lifecycle

    public func setupDockPanel() {
        guard dockPanel == nil else {
            updateDockLayout()
            return
        }

        let panel = SideDockPanel(contentRect: NSRect(x: 200, y: 100, width: 420, height: 64))
        let rootWrapper = SideDockRootWrapper(manager: self)
        let host = SideDockHostingView(rootView: rootWrapper)
        panel.contentView = host
        self.dockPanel = panel
        self.hostingView = host

        updateDockLayout()
    }

    public func updateDockLayout() {
        guard let panel = dockPanel, let host = hostingView else { return }
        guard let screen = resolveScreen() else { return }

        host.layoutSubtreeIfNeeded()
        let fittingSize = host.fittingSize
        let prof = activeProfile
        let targetFrame = layoutEngine.calculateWindowFrame(
            screenFrame: screen.frame,
            visibleFrame: screen.visibleFrame,
            contentSize: CGSize(width: max(160, fittingSize.width), height: max(48, fittingSize.height)),
            config: prof.layoutConfig
        )

        panel.setFrame(targetFrame, display: true, animate: !prof.theme.reduceMotion)
        if !prof.layoutConfig.hideOnWindowHover {
            panel.alphaValue = 1.0
        }

        if prof.layoutConfig.reserveDockSpace && prof.layoutConfig.placement != .floating {
            ReserveSpaceManager.shared.startObserving { [weak self] in
                guard let self = self, let panel = self.dockPanel, let screen = panel.screen else { return nil }
                return (panel.frame, self.activeProfile.layoutConfig.placement, screen.visibleFrame)
            }
        } else {
            ReserveSpaceManager.shared.stopObserving()
        }

        if lastNativeDockCoordinateState != prof.layoutConfig.coordinateNativeDockAutoHide {
            lastNativeDockCoordinateState = prof.layoutConfig.coordinateNativeDockAutoHide
            if prof.layoutConfig.coordinateNativeDockAutoHide {
                ActionExecutionService.shared.setNativeDockAutoHide(true)
            }
        }

        applyVisibility()
        reconfigureEdgeTrigger()
        reconfigureBackgroundMonitors()
    }

    public func applyVisibility() {
        guard let panel = dockPanel else { return }
        let prof = activeProfile
        let gateByTrigger = prof.layoutConfig.autoHide || prof.layoutConfig.hideInFullscreen
        let shouldShow = config.isDockVisible && (!gateByTrigger || isRevealed)
        if shouldShow {
            panel.orderFrontRegardless()
        } else {
            panel.orderOut(nil)
            tooltipController.hide()
            windowPreviewController.hideImmediately()
        }
    }

    private func resolveScreen() -> NSScreen? {
        dockPanel?.screen ?? NSScreen.main ?? NSScreen.screens.first
    }

    private func screenRect(fromWindowLocalRect localRect: CGRect) -> CGRect {
        guard let panel = dockPanel, localRect != .zero else { return .zero }
        let frame = panel.frame
        return CGRect(
            x: frame.minX + localRect.minX,
            y: frame.maxY - localRect.maxY,
            width: localRect.width,
            height: localRect.height
        )
    }

    private func refreshMinimizedWindows() {
        guard activeProfile.layoutConfig.showMinimizedWindows else {
            runtimeState.minimizedWindows = []
            return
        }
        runtimeState.minimizedWindows = WindowRegistryService.shared.minimizedWindowSummaries()
    }

    private func reconfigureBackgroundMonitors() {
        let prof = activeProfile
        if config.isDockVisible {
            if prof.layoutConfig.showNotificationBadges {
                badgeMonitor.start { [weak self] badges in
                    self?.runtimeState.badgesByBundleID = badges
                }
            } else {
                badgeMonitor.stop()
            }

            if prof.items.contains(where: { if case .trash = $0 { return true }; return false }) {
                trashMonitor.start { [weak self] count in
                    self?.runtimeState.trashItemCount = count
                }
            } else {
                trashMonitor.stop()
            }

            profileTriggerEngine.start(
                profilesProvider: { [weak self] in self?.config.profiles ?? [] },
                activeProfileIDProvider: { [weak self] in self?.config.activeProfileId ?? UUID() },
                onMatchProfile: { [weak self] matchedID in
                    self?.selectProfile(matchedID)
                }
            )
        } else {
            badgeMonitor.stop()
            trashMonitor.stop()
            profileTriggerEngine.stop()
        }
    }

    private func reconfigureEdgeTrigger() {
        let prof = activeProfile
        let needsMonitor = config.isDockVisible && (prof.layoutConfig.autoHide || prof.layoutConfig.hideInFullscreen || prof.layoutConfig.hideOnWindowHover)

        guard needsMonitor, let panel = dockPanel else {
            edgeTrigger?.stop()
            edgeTrigger = nil
            isRevealed = true
            dockPanel?.alphaValue = 1.0
            return
        }

        if !prof.layoutConfig.autoHide && !isRevealed {
            isRevealed = true
        }

        if edgeTrigger == nil {
            edgeTrigger = EdgeTriggerManager { [weak self] revealed in
                Task { @MainActor in
                    self?.isRevealed = revealed
                    self?.applyVisibility()
                }
            }
        }

        edgeTrigger?.start(
            placement: prof.layoutConfig.placement,
            triggerThickness: prof.layoutConfig.edgeTriggerThickness,
            revealDelaySeconds: prof.layoutConfig.revealDelaySeconds,
            dockFrame: panel.frame,
            autoHide: prof.layoutConfig.autoHide,
            hideInFullscreen: prof.layoutConfig.hideInFullscreen,
            hideOnWindowHover: prof.layoutConfig.hideOnWindowHover,
            initiallyRevealed: !prof.layoutConfig.autoHide,
            onHoverAlphaChanged: { [weak self] alpha in
                Task { @MainActor in
                    self?.dockPanel?.animator().alphaValue = alpha
                }
            }
        )
    }

    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.updateDockLayout()
            }
        }
    }
}

private struct SideDockRootWrapper: View {
    @ObservedObject var manager: SideDockManager

    var body: some View {
        SideDockBarView(
            profile: manager.activeProfile,
            profiles: manager.config.profiles,
            runningApps: manager.runningApps,
            runtimeState: manager.runtimeState,
            callbacks: DockInteractionCallbacks(
                onSelectProfile: { manager.selectProfile($0) },
                onRemoveItem: { manager.removeItem($0) },
                onLaunchApp: { app in manager.triggerLaunchBounce(for: app.id) },
                onPinRunningApp: { app in manager.pinRunningApp(app) },
                onHideRunningApp: { bid in manager.hideFromRunningApps(bid) },
                onHideOtherApps: { bid in manager.hideOtherApps(exceptBundleID: bid) },
                onShowAppWindows: { bid, name, rect in
                    manager.handleAppHover(bundleID: bid, appName: name, localRect: rect, immediate: true)
                },
                onMoveItem: { fromID, toID in manager.moveItem(fromID: fromID, toID: toID) },
                onDropExternalURLs: { urls, idx in manager.pinExternalURLs(urls, at: idx) },
                onDropFilesToApp: { urls, app in manager.openFiles(urls, withApp: app) },
                onDropFilesToTrash: { urls in manager.recycleFilesToTrash(urls) },
                onEmptyTrash: { ActionExecutionService.shared.confirmAndEmptyTrash() },
                onOpenTrash: {
                    let trashURL = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent(".Trash")
                    NSWorkspace.shared.open(trashURL)
                },
                onOpenLaunchpad: { manager.toggleLaunchpad() },
                onExecuteAction: { ActionExecutionService.shared.execute($0) },
                onCycleSmartStack: { id, delta in manager.cycleSmartStack(id: id, delta: delta) },
                onToggleAppWidgetFace: { manager.toggleAppWidgetFace(id: $0) },
                onSetCustomAppIcon: { id, url in manager.setCustomAppIcon(id: id, sourceURL: url) },
                onResetCustomAppIcon: { manager.resetCustomAppIcon(id: $0) },
                onResizeWidget: { id, size in manager.resizeWidget(id: id, newSize: size) },
                onExpandWidget: { widget, localRect in manager.expandWidget(widget, localRect: localRect) },
                onUpdateFolderPreferences: { id, style, sort in
                    manager.updateFolderPreferences(id: id, style: style, sortOrder: sort)
                },
                onHoverAppChanged: { bid, name, rect in manager.handleAppHover(bundleID: bid, appName: name, localRect: rect) },
                onHoverTooltipChanged: { text, rect in manager.showTooltip(text, localRect: rect) },
                onRestoreMinimizedWindow: { WindowRegistryService.shared.restoreMinimizedWindow($0) },
                onToggleEditMode: { manager.toggleEditMode() },
                onAddQuickItem: { item in manager.addQuickItem(item) },
                onConfigureWidget: { _ in manager.onOpenSettings?() },
                onDragBegin: { manager.beginFloatingDrag() },
                onDragUpdate: { manager.updateFloatingDrag() },
                onDragEnd: { manager.endFloatingDrag() },
                onOpenSettings: { manager.onOpenSettings?() }
            )
        )
    }
}
