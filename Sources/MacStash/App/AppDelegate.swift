import AppKit
import SwiftUI
import Combine
import MacStashCore

@MainActor
public final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var anchorWindow: NSWindow?
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
            button.action = #selector(togglePopover(_:))
            button.target = self
        }

        popover = NSPopover()
        popover.behavior = .transient
        popover.delegate = self

        let menuBarView = MenuBarExtraView(appState: appState) { [weak self] in
            self?.openSettings()
        }
        popover.contentViewController = NSHostingController(rootView: menuBarView)
        updatePopoverContentSize()

        setupStatusItemSubscribers()
    }

    private func setupStatusItemSubscribers() {
        Publishers.CombineLatest4(appState.$isPomodoroRunning, appState.$pomodoroRemainingSeconds, appState.$pomodoroMode, appState.$isPomodoroPaused)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isRunning, remaining, mode, isPaused in
                self?.updateStatusItem(isRunning: isRunning, remaining: remaining, mode: mode, isPaused: isPaused)
            }
            .store(in: &cancellables)
    }

    private func loadStatusImage(active: Bool) -> NSImage {
        let name = active ? "stash_menubar_active" : "stash_menubar"
        if let url = Bundle.main.url(forResource: name, withExtension: "png"),
           let img = NSImage(contentsOf: url) {
            img.isTemplate = true
            return img
        }
        if let img = NSImage(named: name) {
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

    public func updateStatusItem(isRunning: Bool, remaining: TimeInterval, mode: PomodoroMode, isPaused: Bool = false) {
        guard let button = statusItem?.button else { return }
        button.image = loadStatusImage(active: isRunning)
        button.imagePosition = .imageLeading

        if isRunning || isPaused {
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
            mode: appState.pomodoroMode,
            isPaused: appState.isPomodoroPaused
        )
    }

    private func updatePopoverContentSize(on screen: NSScreen? = nil) {
        guard let contentVC = popover.contentViewController else { return }
        contentVC.view.layoutSubtreeIfNeeded()
        let fitting = contentVC.view.fittingSize
        let currentScreen = screen ?? statusItem?.button?.window?.screen ?? NSScreen.main
        let maxHeight = max(200, (currentScreen?.visibleFrame.height ?? 800) - 40)
        let target = NSSize(
            width: max(260, fitting.width),
            height: min(max(100, fitting.height), maxHeight)
        )
        contentVC.preferredContentSize = target
        popover.contentSize = target
    }

    @objc private func togglePopover(_ sender: AnyObject? = nil) {
        guard let button = statusItem.button else { return }

        let mouseLoc = NSEvent.mouseLocation
        let clickedScreen = NSScreen.screens.first { NSMouseInRect(mouseLoc, $0.frame, false) }
            ?? button.window?.screen
            ?? NSScreen.main
            ?? NSScreen.screens.first

        guard let targetScreen = clickedScreen else { return }

        if popover.isShown {
            let currentWindowScreen = popover.contentViewController?.view.window?.screen
            if currentWindowScreen == targetScreen {
                popover.performClose(nil)
                cleanupAnchorWindow()
                return
            } else {
                popover.performClose(nil)
                cleanupAnchorWindow()
            }
        }

        NSApp.activate(ignoringOtherApps: true)
        appState.keyboard.updateBrightnessFromHardware()
        appState.audio.updateVolumeFromHardware()

        // Ensure popover content size is accurately computed before showing to prevent upward expansion over the menu bar
        updatePopoverContentSize(on: targetScreen)

        // Calculate accurate anchor on the target screen
        let menuBarHeight = max(24, targetScreen.frame.maxY - targetScreen.visibleFrame.maxY)
        let anchorWidth: CGFloat = 24
        var anchorX: CGFloat = mouseLoc.x - (anchorWidth / 2)

        // If button's window resides on the target screen, prefer aligning to button bounds
        if let buttonWin = button.window, buttonWin.screen == targetScreen {
            let buttonScreenRect = buttonWin.convertToScreen(button.bounds)
            anchorX = buttonScreenRect.midX - (anchorWidth / 2)
        }

        anchorX = min(max(anchorX, targetScreen.frame.minX + 8), targetScreen.frame.maxX - anchorWidth - 8)
        let anchorY = targetScreen.frame.maxY - menuBarHeight
        let anchorRect = NSRect(x: anchorX, y: anchorY, width: anchorWidth, height: menuBarHeight)

        showPopover(anchoredAt: anchorRect, on: targetScreen)
    }

    private func showPopover(anchoredAt rect: NSRect, on screen: NSScreen) {
        cleanupAnchorWindow()

        let anchor = NSPanel(
            contentRect: rect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        anchor.isOpaque = false
        anchor.backgroundColor = .clear
        anchor.level = .statusBar
        anchor.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]

        let anchorView = NSView(frame: NSRect(origin: .zero, size: rect.size))
        anchor.contentView = anchorView
        anchor.setFrame(rect, display: true)
        anchor.orderFrontRegardless()

        self.anchorWindow = anchor
        updatePopoverContentSize(on: screen)
        popover.show(relativeTo: anchorView.bounds, of: anchorView, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()

        // Post-display safety check: ensure popover window is strictly bounded within target screen
        if let popoverWindow = popover.contentViewController?.view.window {
            let visFrame = screen.visibleFrame
            var currentFrame = popoverWindow.frame
            if !screen.frame.intersects(currentFrame) || popoverWindow.screen != screen {
                currentFrame.origin.x = min(max(rect.midX - (currentFrame.width / 2), visFrame.minX + 8), visFrame.maxX - currentFrame.width - 8)
                currentFrame.origin.y = min(rect.minY - currentFrame.height, visFrame.maxY - currentFrame.height)
                popoverWindow.setFrame(currentFrame, display: true, animate: false)
            }
        }
    }

    private func cleanupAnchorWindow() {
        anchorWindow?.orderOut(nil)
        anchorWindow?.close()
        anchorWindow = nil
    }

    @objc public func openSettings() {
        popover.performClose(nil)
        cleanupAnchorWindow()

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

extension AppDelegate: NSPopoverDelegate {
    public func popoverDidClose(_ notification: Notification) {
        cleanupAnchorWindow()
    }
}
