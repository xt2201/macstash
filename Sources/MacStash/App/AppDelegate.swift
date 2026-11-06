import AppKit
import SwiftUI

public final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var settingsWindow: NSWindow?
    private let appState = AppState.shared

    public func applicationDidFinishLaunching(_ notification: Notification) {
        // 1. Setup Status Item in Menu Bar
        setupStatusItem()

        // 2. Setup Multi-Display Floating Screen Edge & Corner Overlays
        ScreenManager.shared.start(appState: appState)
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            let image = NSImage(systemSymbolName: "hand.tap.fill", accessibilityDescription: "MacStash")
            image?.isTemplate = true
            button.image = image
            button.action = #selector(togglePopover)
            button.target = self
        }

        popover = NSPopover()
        popover.contentSize = NSSize(width: 250, height: 320)
        popover.behavior = .transient

        let menuBarView = MenuBarExtraView(appState: appState) { [weak self] in
            self?.openSettings()
        }
        popover.contentViewController = NSHostingController(rootView: menuBarView)
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    public func openSettings() {
        popover.performClose(nil)

        if settingsWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 580, height: 500),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.title = "MacStash Preferences"
            window.center()
            window.isReleasedWhenClosed = false

            let settingsView = SettingsView(appState: appState)
            window.contentView = NSHostingView(rootView: settingsView)
            self.settingsWindow = window
        }

        settingsWindow?.center()
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
