import AppKit
import SwiftUI
import SideDockCore
import SideDockWidgets
import SideDockUI

@MainActor
public final class SideDockManager: ObservableObject {
    public static let shared = SideDockManager()

    public let configStore: DockConfigStore
    public var onOpenSettings: (@MainActor () -> Void)?

    private var dockPanel: SideDockPanel?
    private var hostingView: SideDockHostingView<SideDockRootWrapper>?
    private var edgeTrigger: EdgeTriggerManager?
    private var runningAppsMonitor = RunningAppsMonitor.shared
    private let layoutEngine = DockLayoutEngine()

    private var dragStartMouseLocation: CGPoint?
    private var dragStartPanelOrigin: CGPoint?

    @Published public var config: SideDockFileConfig
    @Published public var runningApps: [RunningAppInfo] = []
    @Published public var isRevealed: Bool = true

    public init(configStore: DockConfigStore = DockConfigStore()) {
        self.configStore = configStore
        self.config = configStore.config

        self.runningAppsMonitor.setChangeHandler { [weak self] apps in
            Task { @MainActor in
                self?.runningApps = apps
                self?.updateDockLayout()
            }
        }

        setupNotificationObservers()
        setupDockPanel()
    }

    public var activeProfile: DockProfile {
        if let found = config.profiles.first(where: { $0.id == config.activeProfileId }) {
            return found
        }
        return configStore.activeProfile()
    }

    public func toggleDock() {
        configStore.updateConfig { cfg in
            cfg.isDockVisible.toggle()
        }
        self.config = configStore.config
        applyVisibility()
        reconfigureEdgeTrigger()
    }

    public func setDockVisible(_ visible: Bool) {
        configStore.updateConfig { cfg in
            cfg.isDockVisible = visible
        }
        self.config = configStore.config
        applyVisibility()
        reconfigureEdgeTrigger()
    }

    public func selectProfile(_ id: UUID) {
        configStore.updateConfig { cfg in
            cfg.activeProfileId = id
        }
        self.config = configStore.config
        updateDockLayout()
    }

    public func selectProfile(at index: Int) {
        guard index >= 0 && index < config.profiles.count else { return }
        selectProfile(config.profiles[index].id)
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
        let deltaX = currentMouse.x - startMouse.x
        let deltaY = currentMouse.y - startMouse.y

        let proposed = CGPoint(x: startOrigin.x + deltaX, y: startOrigin.y + deltaY)
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

        let panel = SideDockPanel(contentRect: NSRect(x: 200, y: 100, width: 400, height: 60))
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

        // Allow SwiftUI to propagate latest @Published config/runningApps before measuring fittingSize
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

        applyVisibility()
        reconfigureEdgeTrigger()
    }

    private func resolveScreen() -> NSScreen? {
        return dockPanel?.screen ?? NSScreen.main ?? NSScreen.screens.first
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
        }
    }

    private func reconfigureEdgeTrigger() {
        let prof = activeProfile
        let needsMonitor = config.isDockVisible && (prof.layoutConfig.autoHide || prof.layoutConfig.hideInFullscreen || prof.layoutConfig.hideOnWindowHover)

        guard needsMonitor, let panel = dockPanel else {
            edgeTrigger?.stop()
            edgeTrigger = nil
            isRevealed = true
            panelOpacityReset()
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

    private func panelOpacityReset() {
        dockPanel?.alphaValue = 1.0
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
            onSelectProfile: { id in manager.selectProfile(id) },
            onRemoveItem: { id in manager.removeItem(id) },
            onResizeWidget: { id, size in manager.resizeWidget(id: id, newSize: size) },
            onDragBegin: { manager.beginFloatingDrag() },
            onDragUpdate: { manager.updateFloatingDrag() },
            onDragEnd: { manager.endFloatingDrag() },
            onOpenSettings: {
                manager.onOpenSettings?()
            }
        )
    }
}
