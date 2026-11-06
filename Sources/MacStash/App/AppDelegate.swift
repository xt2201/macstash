import AppKit
import SwiftUI
import Combine
import MacStashCore

@MainActor
public final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var settingsWindow: NSWindow?
    private var helpWindow: NSWindow?
    private var onboardingWindow: NSWindow?
    private let appState = AppState.shared
    private var cancellables = Set<AnyCancellable>()

    public func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        setupMainMenu()
        setupStatusItem()
        ScreenManager.shared.start(appState: appState)
        SystemPermissionService.shared.requestNotificationPermission()
        if !SystemPermissionService.shared.isAccessibilityGranted {
            SystemPermissionService.shared.requestAccessibilityPermission()
        }
        if !SystemPermissionService.shared.isInputMonitoringGranted {
            SystemPermissionService.shared.requestInputMonitoringPermission()
        }

        appState.$effectiveLanguage
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.settingsWindow?.title = self.appState.localized("settings.windowTitle")
                self.helpWindow?.title = self.appState.localized("guide.windowTitle")
            }
            .store(in: &cancellables)

        let hasLaunchedBefore = UserDefaults.standard.bool(forKey: "com.macstash.has_launched")
        if !hasLaunchedBefore {
            UserDefaults.standard.set(true, forKey: "com.macstash.has_launched")
            openOnboarding()
        } else if !SystemPermissionService.shared.isAccessibilityGranted {
            openSettings()
        }
    }

    public func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        openSettings()
        return true
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
        popover.contentSize = NSSize(width: 260, height: 350)
        popover.behavior = .transient

        let menuBarView = MenuBarExtraView(appState: appState) { [weak self] in
            self?.openSettings()
        }
        popover.contentViewController = NSHostingController(rootView: menuBarView)

        setupStatusItemSubscribers()
    }

    private func setupStatusItemSubscribers() {
        Publishers.CombineLatest3(appState.$isPomodoroRunning, appState.$pomodoroRemainingSeconds, appState.$pomodoroMode)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isRunning, remaining, mode in
                self?.updateStatusItem(isRunning: isRunning, remaining: remaining, mode: mode)
            }
            .store(in: &cancellables)
    }

    private func loadStatusImage(active: Bool) -> NSImage {
        let name = active ? "stash_menubar_active" : "stash_menubar"
        if let url = Bundle.module.url(forResource: name, withExtension: "png"),
           let img = NSImage(contentsOf: url) {
            img.isTemplate = true
            return img
        }
        return createMenuBarVectorImage(active: active)
    }

    private func createMenuBarVectorImage(active: Bool) -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let img = NSImage(size: size, flipped: false) { bounds in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
            ctx.clear(bounds)
            let origin = CGPoint(x: 3.5, y: 3.5)

            // 1. Pivot Dot
            ctx.setFillColor(NSColor.black.cgColor)
            ctx.fillEllipse(in: CGRect(x: origin.x - 1.5, y: origin.y - 1.5, width: 3.0, height: 3.0))

            // 2. Outer Track Arc
            let trackRadius: CGFloat = 11.5
            let trackPath = CGMutablePath()
            trackPath.addArc(center: origin, radius: trackRadius, startAngle: 0, endAngle: .pi / 2, clockwise: false)
            ctx.addPath(trackPath)
            ctx.setStrokeColor(NSColor.black.cgColor)
            ctx.setLineWidth(1.75)
            ctx.setLineCap(.round)
            ctx.strokePath()

            // 3. Indicator Detent / Active Wedge
            if active {
                let activeRadius: CGFloat = 7.0
                let activePath = CGMutablePath()
                activePath.addArc(center: origin, radius: activeRadius, startAngle: 0, endAngle: .pi / 2, clockwise: false)
                ctx.addPath(activePath)
                ctx.setStrokeColor(NSColor.black.cgColor)
                ctx.setLineWidth(2.0)
                ctx.strokePath()

                let pipAngle = CGFloat.pi / 4
                let pipDist: CGFloat = 9.25
                let pipCenter = CGPoint(x: origin.x + pipDist * cos(pipAngle), y: origin.y + pipDist * sin(pipAngle))
                ctx.fillEllipse(in: CGRect(x: pipCenter.x - 1.25, y: pipCenter.y - 1.25, width: 2.5, height: 2.5))
            } else {
                let angle = CGFloat.pi / 4
                let innerR: CGFloat = 5.5
                let outerR: CGFloat = 8.5
                let p1 = CGPoint(x: origin.x + innerR * cos(angle), y: origin.y + innerR * sin(angle))
                let p2 = CGPoint(x: origin.x + outerR * cos(angle), y: origin.y + outerR * sin(angle))
                ctx.move(to: p1)
                ctx.addLine(to: p2)
                ctx.setLineWidth(1.5)
                ctx.strokePath()
            }
            return true
        }
        img.isTemplate = true
        return img
    }

    public func updateStatusItem(isRunning: Bool, remaining: TimeInterval, mode: PomodoroMode) {
        guard let button = statusItem?.button else { return }
        button.image = loadStatusImage(active: isRunning)
        button.imagePosition = .imageLeading

        if isRunning {
            let total = max(0, Int(round(remaining)))
            let mins = total / 60
            let secs = total % 60
            let timeStr = String(format: "%02d:%02d", mins, secs)
            button.title = " \(timeStr)"
        } else {
            button.title = ""
        }
    }

    public func updateStatusItemImage() {
        updateStatusItem(
            isRunning: appState.isPomodoroRunning,
            remaining: appState.pomodoroRemainingSeconds,
            mode: appState.pomodoroMode
        )
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
            window.title = appState.localized("settings.windowTitle")
            window.center()
            window.isReleasedWhenClosed = false

            let settingsView = SettingsView(appState: appState)
            window.contentView = NSHostingView(rootView: settingsView)
            self.settingsWindow = window
        } else {
            settingsWindow?.title = appState.localized("settings.windowTitle")
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
            window.title = appState.localized("guide.windowTitle")
            window.center()
            window.isReleasedWhenClosed = false

            let guideView = UserGuideView(appState: appState)
            window.contentView = NSHostingView(rootView: guideView)
            self.helpWindow = window
        } else {
            helpWindow?.title = appState.localized("guide.windowTitle")
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
