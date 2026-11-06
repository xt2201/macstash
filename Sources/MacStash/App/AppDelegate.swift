import AppKit
import SwiftUI
import MacStashCore

@MainActor
public final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var settingsWindow: NSWindow?
    private var helpWindow: NSWindow?
    private var onboardingWindow: NSWindow?
    private let appState = AppState.shared

    public func applicationDidFinishLaunching(_ notification: Notification) {
        setupMainMenu()
        setupStatusItem()
        ScreenManager.shared.start(appState: appState)

        let hasLaunchedBefore = UserDefaults.standard.bool(forKey: "com.macstash.has_launched")
        if !hasLaunchedBefore {
            UserDefaults.standard.set(true, forKey: "com.macstash.has_launched")
            openOnboarding()
        }
    }

    private func setupMainMenu() {
        let mainMenu = NSMenu()

        // Application Menu
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "About MacStash", action: #selector(openSettings), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.keyEquivalentModifierMask = .command
        appMenu.addItem(settingsItem)
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Hide MacStash", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        appMenu.addItem(withTitle: "Hide Others", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
        appMenu.addItem(withTitle: "Show All", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Quit MacStash", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        // File Menu (Window closing)
        let fileMenuItem = NSMenuItem()
        let fileMenu = NSMenu(title: "File")
        fileMenu.addItem(withTitle: "Close Window", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        fileMenuItem.submenu = fileMenu
        mainMenu.addItem(fileMenuItem)

        // Help Menu
        let helpMenuItem = NSMenuItem()
        let helpMenu = NSMenu(title: "Help")
        helpMenu.addItem(withTitle: "MacStash User Guide", action: #selector(openHelp), keyEquivalent: "?")
        helpMenuItem.submenu = helpMenu
        mainMenu.addItem(helpMenuItem)

        NSApp.mainMenu = mainMenu
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = loadStatusImage(active: false)
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

    private func loadStatusImage(active: Bool) -> NSImage {
        let name = active ? "stash_menubar_active" : "stash_menubar"
        if let url = Bundle.module.url(forResource: name, withExtension: "png"),
           let img = NSImage(contentsOf: url) {
            img.isTemplate = true
            return img
        }
        if let img = NSImage(named: name) {
            img.isTemplate = true
            return img
        }
        let fallback = NSImage(systemSymbolName: active ? "bolt.circle.fill" : "circle.dashed", accessibilityDescription: "MacStash")
        fallback?.isTemplate = true
        return fallback ?? NSImage()
    }

    public func updateStatusItemImage() {
        guard let button = statusItem?.button else { return }
        button.image = loadStatusImage(active: appState.isPomodoroRunning)
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

    @objc public func openSettings() {
        popover.performClose(nil)

        if settingsWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 660, height: 560),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.title = "MacStash Settings"
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

    @objc public func openHelp() {
        if helpWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 720, height: 520),
                styleMask: [.titled, .closable, .resizable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.title = "MacStash User Guide"
            window.center()
            window.isReleasedWhenClosed = false

            let guideView = UserGuideView()
            window.contentView = NSHostingView(rootView: guideView)
            self.helpWindow = window
        }

        helpWindow?.center()
        helpWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    public func openOnboarding() {
        if onboardingWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 520, height: 400),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "Welcome to MacStash"
            window.center()
            window.isReleasedWhenClosed = false

            let onboardingView = OnboardingView { [weak self] in
                self?.onboardingWindow?.close()
                self?.onboardingWindow = nil
            }
            window.contentView = NSHostingView(rootView: onboardingView)
            self.onboardingWindow = window
        }

        onboardingWindow?.center()
        onboardingWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
