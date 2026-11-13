import AppKit
import SwiftUI
import os.log
import SideDockCore
import SideDockWidgets
import SideDockUI
import SideDockEngine

@MainActor
public final class SideDockManager: ObservableObject {
    public static let shared = SideDockManager()
    private nonisolated static let logger = Logger(subsystem: "com.macstash.app", category: "sidedock")

    public let configStore: DockConfigStore
    public var onOpenSettings: (@MainActor () -> Void)? {
        didSet {
            SideDockEngineCoordinator.shared.onOpenSettingsRequested = onOpenSettings
        }
    }

    @Published public var config: SideDockFileConfig
    @Published public var runningApps: [RunningAppInfo] = []
    @Published public var runtimeState: DockRuntimeState = DockRuntimeState()
    @Published public var isRevealed: Bool = true

    public init(configStore: DockConfigStore = DockConfigStore()) {
        self.configStore = configStore
        self.config = configStore.config

        SideDockEngineCoordinator.shared.onOpenSettingsRequested = { [weak self] in
            self?.onOpenSettings?()
        }
        SideDockEngineCoordinator.shared.start(initiallyVisible: self.config.isDockVisible)
        Self.logger.info("SideDockManager initialized (SideDock Engine, visible: \(self.config.isDockVisible))")
    }

    public var activeProfile: DockProfile {
        if let found = config.profiles.first(where: { $0.id == config.activeProfileId }) {
            return found
        }
        return configStore.activeProfile()
    }

    // MARK: - Core Actions Bridging to SideDockEngine

    public func toggleDock() {
        setDockVisible(!config.isDockVisible)
    }

    public func setDockVisible(_ visible: Bool) {
        configStore.updateConfig { $0.isDockVisible = visible }
        self.config = configStore.config
        SideDockEngineCoordinator.shared.setVisible(visible)
    }

    public func toggleLaunchpad() {
        SideDockEngineCoordinator.shared.toggleLaunchpad()
    }

    public func toggleWindowSwitcher() {
        SideDockEngineCoordinator.shared.toggleWindowSwitcher()
    }

    public func toggleEditMode() {
        SideDockEngineCoordinator.shared.enterEditMode()
    }

    public func selectProfile(_ id: UUID) {
        if let idx = config.profiles.firstIndex(where: { $0.id == id }) {
            selectProfile(at: idx)
        }
    }

    public func selectProfile(at index: Int) {
        SideDockEngineCoordinator.shared.selectProfile(at: index)
    }

    public func updateDockLayout() {
        // MainWindowController & TileStore reactively manage layout via @Observable.
    }

    public func resetLayout() {
        configStore.resetLayout()
        self.config = configStore.config
        SideDockEngineCoordinator.shared.resetLayoutToDefaults()
    }

    public func resetLayoutToDefaults() {
        resetLayout()
    }

    public func openFullSettingsWindow() {
        SideDockEngineCoordinator.shared.openDedicatedSettingsWindow()
    }
}
