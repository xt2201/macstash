import AppKit
import SwiftUI
import Combine
import MacStashCore

/// Manages multi-display overlay lifecycles across MacBook built-in & all external monitors
@MainActor
public final class ScreenManager: ObservableObject {
    public static let shared = ScreenManager()

    private var appState: AppState = AppState.shared
    private var instances: [CGDirectDisplayID: ScreenOverlayInstance] = [:]
    private var cancellables = Set<AnyCancellable>()

    // Continuous Cursor Tracking & Event Monitors
    private var cursorTrackingTimer: Timer?
    private var globalMouseMonitor: Any?
    private var localMouseMonitor: Any?
    private var globalKeyMonitor: Any?
    private var localKeyMonitor: Any?

    // Dwell and Hide State
    private var pendingDwellCorner: CornerPosition?
    private var pendingDwellDisplayID: CGDirectDisplayID?
    private var dwellWorkItem: DispatchWorkItem?
    private var hideWorkItem: DispatchWorkItem?

    private init() {}

    public func start(appState: AppState) {
        self.appState = appState
        rebuildInstances()
        observeScreenChanges()
        observeWorkspaceEvents()
        startCursorTracking()
        setupGlobalHotkeys()
    }

    private func observeScreenChanges() {
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.rebuildInstances()
                self?.resetAllInstances(reason: .displayConfigurationChange)
            }
        }
    }

    private func observeWorkspaceEvents() {
        let wsCenter = NSWorkspace.shared.notificationCenter

        wsCenter.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.resetAllInstances(reason: .spaceChange)
            }
        }

        wsCenter.addObserver(
            forName: NSWorkspace.screensDidSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.resetAllInstances(reason: .systemSleep)
            }
        }

        wsCenter.addObserver(
            forName: NSWorkspace.screensDidWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.rebuildInstances()
            }
        }

        wsCenter.addObserver(
            forName: NSWorkspace.sessionDidResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.resetAllInstances(reason: .screenLock)
            }
        }

        NotificationCenter.default.addObserver(
            forName: NSWindow.didEnterFullScreenNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.resetAllInstances(reason: .fullscreenToggle)
            }
        }

        NotificationCenter.default.addObserver(
            forName: NSWindow.didExitFullScreenNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.resetAllInstances(reason: .fullscreenToggle)
            }
        }

        NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.resetAllInstances(reason: .appDeactivated)
            }
        }
    }

    public func resetAllInstances(reason: ResetReason) {
        AppLogger.hotcorner.debug("Resetting all overlay instances with reason: \(reason.rawValue)")
        dismissActiveDial()
        for instance in instances.values {
            instance.resetAllCorners(reason: reason)
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

    // MARK: - Cursor Tracking Engine

    private func startCursorTracking() {
        cursorTrackingTimer?.invalidate()
        cursorTrackingTimer = Timer.scheduledTimer(withTimeInterval: 0.04, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.evaluateMousePosition(NSEvent.mouseLocation)
            }
        }
        if let t = cursorTrackingTimer {
            RunLoop.main.add(t, forMode: .common)
        }

        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged]) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.evaluateMousePosition(NSEvent.mouseLocation)
            }
        }

        localMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged]) { [weak self] event in
            Task { @MainActor [weak self] in
                self?.evaluateMousePosition(NSEvent.mouseLocation)
            }
            return event
        }
    }

    public func evaluateMousePosition(_ mouseLoc: NSPoint) {
        guard appState.isEnabled else {
            if appState.activeCorner != nil {
                dismissActiveDial()
            }
            return
        }

        // 1. Mouse Dragging / Pressed Suppression (only when dial is NOT already active)
        if appState.activeCorner == nil && appState.settings.suppressWhenMousePressed && NSEvent.pressedMouseButtons != 0 {
            cancelPendingDwell()
            return
        }

        // 2. Fullscreen Suppression
        if appState.settings.suppressInFullscreen && NSApplication.shared.presentationOptions.contains(.fullScreen) {
            cancelPendingDwell()
            if appState.activeCorner != nil { dismissActiveDial() }
            return
        }

        // 3. Excluded Applications Suppression
        if let frontApp = NSWorkspace.shared.frontmostApplication?.bundleIdentifier {
            if appState.settings.excludedBundleIDs.contains(frontApp) {
                cancelPendingDwell()
                if appState.activeCorner != nil { dismissActiveDial() }
                return
            }
        }

        let screens = NSScreen.screens
        let allFrames = screens.map { $0.frame }
        let dialRadius = appState.settings.dialRadiusPoints
        let sensitivity = max(Defaults.HotCorner.minHitZoneSizePoints, appState.cornerSensitivityRadius)

        // 4. Check Active Dial State
        if let activeCorner = appState.activeCorner, let activeInstance = instances[appState.activeDisplayID] {
            let vertex = cornerVertex(for: activeCorner, in: activeInstance.screen.frame)
            let dist = hypot(mouseLoc.x - vertex.x, mouseLoc.y - vertex.y)
            if dist <= dialRadius + 25 {
                hideWorkItem?.cancel()
                hideWorkItem = nil
                activeInstance.setMouseInteractive(true, for: activeCorner)
            } else {
                if hideWorkItem == nil {
                    scheduleHideTimer(delay: appState.settings.cornerHideDelaySeconds)
                }
            }
            return
        }

        // 5. Check Hot Corner Dwell (when no dial is active)
        if appState.isCornerDialsEnabled {
            var foundCandidate = false
            for screen in screens {
                guard let sDisplayID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID else {
                    continue
                }
                for corner in CornerPosition.allCases {
                    guard appState.settings.cornerEnabled[corner] == true && appState.action(for: corner) != .none else {
                        continue
                    }
                    guard CornerGeometry.isOuterCorner(corner: corner, of: screen.frame, in: allFrames) else {
                        continue
                    }
                    let vertex = cornerVertex(for: corner, in: screen.frame)
                    let dist = hypot(mouseLoc.x - vertex.x, mouseLoc.y - vertex.y)
                    if dist <= sensitivity {
                        foundCandidate = true
                        if pendingDwellCorner == corner && pendingDwellDisplayID == sDisplayID {
                            // Already pending
                        } else {
                            scheduleDwellTimer(corner: corner, displayID: sDisplayID, screenFrame: screen.frame)
                        }
                        break
                    }
                }
                if foundCandidate { break }
            }
            if !foundCandidate {
                cancelPendingDwell()
            }
        }
    }

    private func scheduleDwellTimer(corner: CornerPosition, displayID: CGDirectDisplayID, screenFrame: NSRect) {
        cancelPendingDwell()
        pendingDwellCorner = corner
        pendingDwellDisplayID = displayID

        let delay = appState.cornerDwellDelay
        if delay <= 0 {
            activateDial(corner: corner, displayID: displayID)
            return
        }

        let item = DispatchWorkItem { [weak self] in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                guard self.pendingDwellCorner == corner && self.pendingDwellDisplayID == displayID else { return }
                let cur = NSEvent.mouseLocation
                let v = self.cornerVertex(for: corner, in: screenFrame)
                let dist = hypot(cur.x - v.x, cur.y - v.y)
                if dist <= self.appState.settings.dialRadiusPoints {
                    self.activateDial(corner: corner, displayID: displayID)
                }
                self.pendingDwellCorner = nil
                self.pendingDwellDisplayID = nil
            }
        }
        self.dwellWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: item)
    }

    private func cancelPendingDwell() {
        dwellWorkItem?.cancel()
        dwellWorkItem = nil
        pendingDwellCorner = nil
        pendingDwellDisplayID = nil
    }

    private func scheduleHideTimer(delay: TimeInterval) {
        hideWorkItem?.cancel()
        let item = DispatchWorkItem { [weak self] in
            Task { @MainActor [weak self] in
                self?.dismissActiveDial()
            }
        }
        self.hideWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: item)
    }

    public func activateDial(corner: CornerPosition, displayID: CGDirectDisplayID) {
        AppLogger.hotcorner.info("Activating corner dial at \(corner.rawValue) on display \(displayID)")
        appState.activeCorner = corner
        appState.activeDisplayID = displayID
        instances[displayID]?.setMouseInteractive(true, for: corner)
        appState.haptics.performDetentTick()
        appState.sound.playTick(enabled: appState.isSoundEnabled, volume: appState.soundVolume)
    }

    public func dismissActiveDial() {
        hideWorkItem?.cancel()
        hideWorkItem = nil
        cancelPendingDwell()
        appState.activeCorner = nil
        appState.activeDisplayID = 0
        for instance in instances.values {
            for c in CornerPosition.allCases {
                instance.setMouseInteractive(false, for: c)
            }
        }
    }

    public func cornerVertex(for corner: CornerPosition, in frame: NSRect) -> CGPoint {
        switch corner {
        case .topLeft:
            return CGPoint(x: frame.minX, y: frame.maxY)
        case .topRight:
            return CGPoint(x: frame.maxX, y: frame.maxY)
        case .bottomLeft:
            return CGPoint(x: frame.minX, y: frame.minY)
        case .bottomRight:
            return CGPoint(x: frame.maxX, y: frame.minY)
        }
    }

    // MARK: - Global Hotkeys

    private func setupGlobalHotkeys() {
        globalKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            Task { @MainActor [weak self] in
                self?.handleKeyEvent(event)
            }
        }
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            Task { @MainActor [weak self] in
                self?.handleKeyEvent(event)
            }
            return event
        }
    }

    private func handleKeyEvent(_ event: NSEvent) {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if flags.contains(.option) {
            if event.keyCode == 1 { // 's'
                toggleDials()
            }
        }
    }

    public func toggleDials() {
        if appState.activeCorner != nil {
            dismissActiveDial()
        } else {
            let mouse = NSEvent.mouseLocation
            let targetScreen = NSScreen.screens.first(where: {
                mouse.x >= $0.frame.minX - 5 && mouse.x <= $0.frame.maxX + 5 &&
                mouse.y >= $0.frame.minY - 5 && mouse.y <= $0.frame.maxY + 5
            }) ?? NSScreen.main ?? NSScreen.screens.first
            guard let screen = targetScreen else { return }
            guard let id = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID else { return }
            activateDial(corner: .topRight, displayID: id)
        }
    }
}
