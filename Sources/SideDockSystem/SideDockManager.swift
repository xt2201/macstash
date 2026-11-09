import AppKit
import SwiftUI
import SideDockCore
import SideDockWidgets
import SideDockUI

@MainActor
public final class SideDockManager: ObservableObject {
    public static let shared = SideDockManager()

    public let configStore: DockConfigStore
    private var dockPanel: SideDockPanel?
    private var edgeTrigger: EdgeTriggerManager?
    private var runningAppsMonitor = RunningAppsMonitor.shared
    private let layoutEngine = DockLayoutEngine()

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
        configStore.activeProfile()
    }

    public func toggleDock() {
        configStore.updateConfig { cfg in
            cfg.isDockVisible.toggle()
        }
        self.config = configStore.config
        applyVisibility()
    }

    public func setDockVisible(_ visible: Bool) {
        configStore.updateConfig { cfg in
            cfg.isDockVisible = visible
        }
        self.config = configStore.config
        applyVisibility()
    }

    public func selectProfile(_ id: UUID) {
        configStore.updateConfig { cfg in
            cfg.activeProfileId = id
        }
        self.config = configStore.config
        updateDockLayout()
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

    public func handleDragFloating(offset: CGPoint) {
        let prof = activeProfile
        guard prof.layoutConfig.placement == .floating, let panel = dockPanel, let screen = panel.screen ?? NSScreen.main else { return }

        let currentFrame = panel.frame
        let proposed = CGPoint(x: currentFrame.origin.x + offset.x, y: currentFrame.origin.y + offset.y)
        let clamped = layoutEngine.clampFloatingCoordinates(
            proposedPoint: proposed,
            dockSize: currentFrame.size,
            screenBounds: screen.visibleFrame
        )

        panel.setFrameOrigin(clamped)

        configStore.updateConfig { cfg in
            if let idx = cfg.profiles.firstIndex(where: { $0.id == cfg.activeProfileId }) {
                cfg.profiles[idx].layoutConfig.floatingX = clamped.x
                cfg.profiles[idx].layoutConfig.floatingY = clamped.y
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
        let hostingView = SideDockHostingView(rootView: makeDockRootView())
        panel.contentView = hostingView
        self.dockPanel = panel

        updateDockLayout()
        applyVisibility()
        setupEdgeTrigger()
    }

    public func updateDockLayout() {
        guard let panel = dockPanel, let screen = panel.screen ?? NSScreen.main else { return }

        let hostingView = SideDockHostingView(rootView: makeDockRootView())
        panel.contentView = hostingView

        let fittingSize = hostingView.fittingSize
        let prof = activeProfile
        let targetFrame = layoutEngine.calculateWindowFrame(
            screenFrame: screen.frame,
            visibleFrame: screen.visibleFrame,
            contentSize: CGSize(width: max(160, fittingSize.width), height: max(48, fittingSize.height)),
            config: prof.layoutConfig
        )

        panel.setFrame(targetFrame, display: true, animate: !prof.theme.reduceMotion)
    }

    private func applyVisibility() {
        guard let panel = dockPanel else { return }
        if config.isDockVisible && isRevealed {
            panel.orderFrontRegardless()
        } else {
            panel.orderOut(nil)
        }
    }

    private func setupEdgeTrigger() {
        edgeTrigger = EdgeTriggerManager { [weak self] revealed in
            Task { @MainActor in
                self?.isRevealed = revealed
                self?.applyVisibility()
            }
        }

        let prof = activeProfile
        if prof.layoutConfig.autoHide, let panel = dockPanel {
            edgeTrigger?.start(
                placement: prof.layoutConfig.placement,
                triggerThickness: prof.layoutConfig.edgeTriggerThickness,
                revealDelaySeconds: prof.layoutConfig.revealDelaySeconds,
                dockFrame: panel.frame
            )
        }
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

    private func makeDockRootView() -> some View {
        SideDockBarView(
            profile: activeProfile,
            profiles: config.profiles,
            runningApps: runningApps,
            onSelectProfile: { [weak self] id in self?.selectProfile(id) },
            onRemoveItem: { [weak self] id in self?.removeItem(id) },
            onResizeWidget: { [weak self] id, size in self?.resizeWidget(id: id, newSize: size) },
            onDragFloating: { [weak self] pt in self?.handleDragFloating(offset: pt) },
            onOpenSettings: {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }
        )
    }
}
