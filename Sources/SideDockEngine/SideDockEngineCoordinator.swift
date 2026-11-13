import AppKit
import ApplicationServices
import ServiceManagement
import SwiftUI
import os.log

@MainActor
enum LaunchAtLoginService {
    static let shared = LaunchAtLoginBridge()
}

@MainActor
final class LaunchAtLoginBridge {
    var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    func setEnabled(_ enabled: Bool) -> Bool {
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            }
            return true
        } catch {
            return false
        }
    }
}

@MainActor
public final class SideDockEngineCoordinator: ObservableObject {
    public static let shared = SideDockEngineCoordinator()
    private static let logger = Logger(subsystem: "com.macstash.app", category: "sidedock")

    private var mainWindowController: MainWindowController?
    private var mainWindow: MainWindow?
    private var standaloneSettingsWindow: NSWindow?
    private var hasStarted: Bool = false

    @Published public private(set) var isDockVisible: Bool = false

    public var onOpenSettingsRequested: (@MainActor () -> Void)?
    public var onSendMediaCommand: (@MainActor (String) -> Void)?
    public var onSeekMediaTime: (@MainActor (Double) -> Void)?

    private init() {}

    public func start(initiallyVisible: Bool) {
        if !hasStarted {
            hasStarted = true
            AXUIElementSetMessagingTimeout(AXUIElementCreateSystemWide(), 1.0)
            SystemDockVisibilityService.shared.recoverStaleSnapshotIfNeeded()

            _ = LaunchpadHotKeyService.shared
            _ = LaunchpadOverlayService.shared
            ExternalWidgetLoader.shared.discoverAndLoad()

            TileStore.shared.syncPreferencesFromSystemDockIfNeeded()
            PermissionsService.shared.refresh()
        }

        setVisible(initiallyVisible)
    }

    public func setVisible(_ visible: Bool) {
        isDockVisible = visible
        if visible {
            if mainWindowController == nil {
                let win = MainWindow(
                    contentRect: NSRect(x: 196, y: 240, width: 480, height: 270),
                    styleMask: [.nonactivatingPanel, .borderless, .fullSizeContentView],
                    backing: .buffered,
                    defer: false
                )
                win.contentView = MainWindowContainerView(frame: NSRect(x: 0, y: 0, width: 480, height: 270))
                win.awakeFromNib()
                mainWindow = win
                mainWindowController = MainWindowController(window: win)
            }
            mainWindowController?.showWindow(nil)
            WindowReservationService.shared.start()
            DockBadgeService.shared.start()
            ProfileTriggerEngine.shared.start()
            SideDockPreferences.shared.applySystemDockVisibilityPreference()
        } else {
            mainWindow?.orderOut(nil)
            DockBadgeService.shared.stop()
        }
    }

    public func toggleVisible() {
        setVisible(!isDockVisible)
    }

    public func toggleLaunchpad() {
        LaunchpadOverlayService.shared.toggle()
    }

    public func toggleWindowSwitcher() {
        WindowSwitcherService.shared.handleHotKeyPress(direction: 1)
    }

    public func enterEditMode() {
        DockEditModeService.shared.enter()
    }

    public func selectProfile(at index: Int) {
        let profiles = ProfileService.shared.profiles
        guard index >= 0 && index < profiles.count else { return }
        ProfileService.shared.setActiveProfile(id: profiles[index].id)
    }

    public func updateNowPlaying(
        title: String,
        artist: String,
        album: String,
        appBundleID: String,
        appName: String,
        isPlaying: Bool,
        duration: Double,
        elapsedTime: Double,
        artworkImage: NSImage?
    ) {
        MediaPlaybackService.shared.applyExternalState(
            title: title,
            artist: artist,
            album: album,
            bundleIdentifier: appBundleID,
            appName: appName,
            isPlaying: isPlaying,
            duration: duration,
            elapsedTime: elapsedTime,
            artworkImage: artworkImage
        )
    }

    public func makeEmbeddedSettingsView() -> AnyView {
        AnyView(SettingsRootView())
    }

    public func openDedicatedSettingsWindow() {
        if let onOpenSettingsRequested {
            onOpenSettingsRequested()
        }
    }

    public func resetLayoutToDefaults() {
        _ = TileStore.shared.resetPinnedItemsToSystemDock()
    }
}
