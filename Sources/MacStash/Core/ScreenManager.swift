import AppKit
import SwiftUI
import Combine

/// Manages multi-display overlay lifecycles across MacBook built-in & all external monitors
public final class ScreenManager: ObservableObject {
    public static let shared = ScreenManager()

    private var appState: AppState = AppState.shared
    private var instances: [CGDirectDisplayID: ScreenOverlayInstance] = [:]
    private var quickLauncherPanel: NSPanel?
    private var cancellables = Set<AnyCancellable>()

    private init() {}

    public func start(appState: AppState) {
        self.appState = appState
        rebuildInstances()
        observeScreenChanges()
        observeQuickLauncher()
    }

    private func observeScreenChanges() {
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.rebuildInstances()
        }
    }

    public func rebuildInstances() {
        var activeIDs = Set<CGDirectDisplayID>()

        for screen in NSScreen.screens {
            guard let id = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID else {
                continue
            }
            activeIDs.insert(id)

            if let existing = instances[id] {
                existing.updateScreen(screen)
            } else {
                let newInstance = ScreenOverlayInstance(displayID: id, screen: screen, appState: appState)
                instances[id] = newInstance
            }
        }

        // Clean up detached displays
        for (id, instance) in instances where !activeIDs.contains(id) {
            instance.destroyPanels()
            instances.removeValue(forKey: id)
        }
    }

    private func observeQuickLauncher() {
        appState.$isQuickLauncherPresented
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isPresented in
                if isPresented {
                    self?.showQuickLauncher()
                } else {
                    self?.hideQuickLauncher()
                }
            }
            .store(in: &cancellables)
    }

    private func showQuickLauncher() {
        // Place Quick Launcher on the screen containing mouse cursor
        let mouseLoc = NSEvent.mouseLocation
        let targetScreen = NSScreen.screens.first(where: { $0.frame.contains(mouseLoc) }) ?? NSScreen.main ?? NSScreen.screens.first

        guard let screen = targetScreen else { return }

        if quickLauncherPanel == nil {
            let width: CGFloat = 560
            let height: CGFloat = 420
            let frame = NSRect(
                x: screen.frame.midX - (width / 2),
                y: screen.frame.midY - (height / 2) + 100,
                width: width,
                height: height
            )

            let panel = NSPanel(
                contentRect: frame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            panel.level = .floating
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.hasShadow = false

            let rootView = QuickLauncherSheet(appState: appState)
            panel.contentView = NSHostingView(rootView: rootView)
            self.quickLauncherPanel = panel
        }

        let width: CGFloat = 560
        let height: CGFloat = 420
        let newFrame = NSRect(
            x: screen.frame.midX - (width / 2),
            y: screen.frame.midY - (height / 2) + 60,
            width: width,
            height: height
        )
        quickLauncherPanel?.setFrame(newFrame, display: true)
        quickLauncherPanel?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func hideQuickLauncher() {
        quickLauncherPanel?.orderOut(nil)
    }
}
