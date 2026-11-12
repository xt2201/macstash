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

    // Right Edge Dwell and Hide State
    private var pendingRightEdgeDisplayID: CGDirectDisplayID?
    private var rightEdgeDwellWorkItem: DispatchWorkItem?
    private var rightEdgeHideWorkItem: DispatchWorkItem?

    // Left Edge Slider Dwell and Hide State
    private var pendingLeftSliderDisplayID: CGDirectDisplayID?
    private var leftSliderDwellWorkItem: DispatchWorkItem?
    private var leftSliderHideWorkItem: DispatchWorkItem?

    // Left Edge Drawer Dwell and Hide State
    private var pendingLeftEdgeDisplayID: CGDirectDisplayID?
    private var leftEdgeDwellWorkItem: DispatchWorkItem?
    private var leftEdgeHideWorkItem: DispatchWorkItem?

    // Drag-and-Drop Gesture Tracking (Shake to summon)
    private var dragHistory: [(point: NSPoint, time: Date)] = []
    private var lastMouseEvalTime: TimeInterval = 0

    private init() {}

    public func start(appState: AppState) {
        self.appState = appState
        rebuildInstances()
        observeScreenChanges()
        observeWorkspaceEvents()
        observeStateChanges()
        startCursorTracking()
        setupGlobalHotkeys()
    }

    private func observeStateChanges() {
        Publishers.CombineLatest(appState.stashShelf.$isShelfOpen, appState.scratchpad.$isScratchpadOpen)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] shelfOpen, padOpen in
                guard let self = self else { return }
                if !shelfOpen && !padOpen {
                    self.cancelPendingLeftEdgeHide()
                }
                let isOpen = shelfOpen || padOpen || self.appState.stashShelf.isDropTargetActive
                let allowKey = shelfOpen || padOpen
                for instance in self.instances.values {
                    instance.setLeftEdgeInteractive(isOpen, allowsKey: allowKey)
                }
            }
            .store(in: &cancellables)

        appState.stashShelf.$isDropTargetActive
            .receive(on: DispatchQueue.main)
            .sink { [weak self] dropActive in
                guard let self = self else { return }
                if dropActive {
                    for instance in self.instances.values {
                        instance.setLeftEdgeInteractive(true, allowsKey: false)
                    }
                }
            }
            .store(in: &cancellables)

        appState.$isRightSliderActive
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sliderActive in
                guard let self = self else { return }
                for (id, instance) in self.instances {
                    let shouldBeInteractive = sliderActive && (self.appState.activeDisplayID == 0 || self.appState.activeDisplayID == id)
                    instance.setRightEdgeInteractive(shouldBeInteractive)
                }
                self.updateEdgeVisualizerState()
            }
            .store(in: &cancellables)

        appState.$isLeftSliderActive
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sliderActive in
                guard let self = self else { return }
                for (id, instance) in self.instances {
                    let shouldBeInteractive = sliderActive && (self.appState.activeDisplayID == 0 || self.appState.activeDisplayID == id)
                    instance.setLeftSliderInteractive(shouldBeInteractive)
                }
                self.updateEdgeVisualizerState()
            }
            .store(in: &cancellables)

        appState.$cornerDisplayTarget
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.resetAllInstances(reason: .displayConfigurationChange)
            }
            .store(in: &cancellables)
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
        dismissRightSlider()
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
            DispatchQueue.main.async { [weak self] in
                self?.evaluateMousePosition(NSEvent.mouseLocation)
            }
        }
        if let t = cursorTrackingTimer {
            RunLoop.main.add(t, forMode: .common)
        }

        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged, .leftMouseDown]) { [weak self] event in
            DispatchQueue.main.async { [weak self] in
                self?.evaluateMousePosition(NSEvent.mouseLocation, isClick: event.type == .leftMouseDown)
            }
        }

        localMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged, .leftMouseDown]) { [weak self] event in
            self?.evaluateMousePosition(NSEvent.mouseLocation, isClick: event.type == .leftMouseDown)
            return event
        }
    }

    public func evaluateMousePosition(_ mouseLoc: NSPoint, isClick: Bool = false) {
        guard appState.isEnabled else {
            if appState.activeCorner != nil {
                dismissActiveDial()
            }
            return
        }

        let now = ProcessInfo.processInfo.systemUptime
        if !isClick {
            if now - lastMouseEvalTime < 0.012 {
                return
            }
        }
        lastMouseEvalTime = now

        let isDragging = (NSEvent.pressedMouseButtons != 0 && !isClick)
        if isDragging {
            detectDragShake(mouseLoc: mouseLoc)
        } else {
            dragHistory.removeAll()
        }

        updateEdgePanelsInteractivity(mouseLoc: mouseLoc, isDragging: isDragging)

        // 1. Mouse Dragging / Pressed Suppression (only when dial is NOT already active)
        if appState.activeCorner == nil && appState.settings.suppressWhenMousePressed && isDragging {
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
                if isClick {
                    dismissActiveDial()
                    return
                }
                if hideWorkItem == nil {
                    scheduleHideTimer(delay: appState.settings.cornerHideDelaySeconds)
                }
            }
            return
        }

        // Outside Click Handling for Transient Panels (Edge Slider, Stash Shelf, Scratchpad, Cursor Palette)
        if isClick {
            if appState.isCursorPalettePresented, let paletteFrame = cursorPalettePanel?.frame {
                if !CornerGeometry.rectContains(paletteFrame, mouseLoc) {
                    dismissCursorPalette()
                }
            }

            if appState.isRightSliderActive {
                var clickedInsideSlider = false
                for instance in instances.values {
                    let frame = instance.screen.frame
                    let sliderRect = instance.sliderRect(for: .right, in: frame)
                    let expandedHitRect = CornerGeometry.edgeSliderHitRect(
                        screenFrame: frame,
                        sliderPanelRect: sliderRect,
                        edge: .right
                    )
                    if CornerGeometry.rectContains(expandedHitRect, mouseLoc) {
                        clickedInsideSlider = true
                        break
                    }
                }
                if !clickedInsideSlider {
                    dismissEdgeSlider(edge: .right)
                }
            }

            if appState.isLeftSliderActive {
                var clickedInsideSlider = false
                for instance in instances.values {
                    let frame = instance.screen.frame
                    let sliderRect = instance.sliderRect(for: .left, in: frame)
                    let expandedHitRect = CornerGeometry.edgeSliderHitRect(
                        screenFrame: frame,
                        sliderPanelRect: sliderRect,
                        edge: .left
                    )
                    if CornerGeometry.rectContains(expandedHitRect, mouseLoc) {
                        clickedInsideSlider = true
                        break
                    }
                }
                if !clickedInsideSlider {
                    dismissEdgeSlider(edge: .left)
                }
            }

            if appState.stashShelf.isShelfOpen || appState.scratchpad.isScratchpadOpen {
                var clickedInsideDrawer = false
                let drawerEdge = appState.settings.drawerEdgePosition
                for instance in instances.values {
                    let frame = instance.screen.frame
                    let drawerPanelRect = instance.drawerRect(in: frame)
                    let activeWidth: CGFloat = appState.scratchpad.isScratchpadOpen
                        ? Defaults.LeftEdgeDrawer.scratchpadTotalWidthPoints
                        : Defaults.LeftEdgeDrawer.shelfTotalWidthPoints
                    let activeHeight: CGFloat = appState.scratchpad.isScratchpadOpen
                        ? Defaults.LeftEdgeDrawer.scratchpadTotalHeightPoints
                        : Defaults.LeftEdgeDrawer.shelfTotalHeightPoints
                    let drawerRect = CornerGeometry.edgeDrawerHitRect(
                        screenFrame: frame,
                        drawerPanelRect: drawerPanelRect,
                        edge: drawerEdge,
                        drawerWidth: activeWidth,
                        drawerHeight: activeHeight
                    )
                    if CornerGeometry.rectContains(drawerRect, mouseLoc) {
                        clickedInsideDrawer = true
                        break
                    }
                }
                if !clickedInsideDrawer {
                    if !appState.stashShelf.isPinned {
                        appState.stashShelf.closeShelf()
                    }
                    if !appState.scratchpad.isPinned {
                        appState.scratchpad.isScratchpadOpen = false
                    }
                }
            }
        }

        // 5. Check Hot Corner Dwell (when no dial is active)
        if appState.isCornerDialsEnabled {
            var foundCandidate = false
            for screen in screens {
                guard let sDisplayID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID else {
                    continue
                }
                guard shouldEnableCorners(on: screen, displayID: sDisplayID) else {
                    continue
                }
                for corner in CornerPosition.allCases {
                    guard appState.settings.cornerEnabled[corner] == true && appState.action(for: corner) != .none else {
                        continue
                    }
                    if appState.settings.onlyOuterCorners {
                        guard CornerGeometry.isOuterCorner(corner: corner, of: screen.frame, in: allFrames) else {
                            continue
                        }
                    }
                    let vertex = cornerVertex(for: corner, in: screen.frame)
                    let dist = hypot(mouseLoc.x - vertex.x, mouseLoc.y - vertex.y)
                    let hitDistance = isClick ? max(sensitivity, 35.0) : sensitivity
                    if dist <= hitDistance {
                        foundCandidate = true
                        if isClick {
                            cancelPendingDwell()
                            activateDial(corner: corner, displayID: sDisplayID)
                        } else if pendingDwellCorner == corner && pendingDwellDisplayID == sDisplayID {
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

    // MARK: - Edge Panels Interactivity & Gestures

    private func detectDragShake(mouseLoc: NSPoint) {
        guard appState.isEnabled && appState.settings.isStashShelfEnabled else { return }
        guard !appState.stashShelf.isShelfOpen else { return }

        let now = Date()
        dragHistory.append((point: mouseLoc, time: now))
        dragHistory.removeAll { now.timeIntervalSince($0.time) > 0.75 }

        guard dragHistory.count >= 6 else { return }

        var reversals = 0
        var lastDirectionX: CGFloat = 0
        var lastDirectionY: CGFloat = 0

        for i in 1..<dragHistory.count {
            let dx = dragHistory[i].point.x - dragHistory[i-1].point.x
            let dy = dragHistory[i].point.y - dragHistory[i-1].point.y

            if abs(dx) > 12 {
                let dirX: CGFloat = dx > 0 ? 1 : -1
                if lastDirectionX != 0 && dirX != lastDirectionX {
                    reversals += 1
                }
                lastDirectionX = dirX
            } else if abs(dy) > 12 {
                let dirY: CGFloat = dy > 0 ? 1 : -1
                if lastDirectionY != 0 && dirY != lastDirectionY {
                    reversals += 1
                }
                lastDirectionY = dirY
            }
        }

        if reversals >= 3 {
            appState.stashShelf.openShelf(transient: true)
            AppLogger.lifecycle.info("Shake-to-summon gesture activated Stash Shelf")
            dragHistory.removeAll()
        }
    }

    public func shouldEnableCorners(on screen: NSScreen, displayID: CGDirectDisplayID) -> Bool {
        let isBuiltIn = CGDisplayIsBuiltin(displayID) != 0
        switch appState.settings.cornerDisplayTarget {
        case .builtIn:
            let hasBuiltIn = NSScreen.screens.contains { s in
                guard let id = s.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID else { return false }
                return CGDisplayIsBuiltin(id) != 0
            }
            if hasBuiltIn {
                return isBuiltIn
            } else {
                return screen == NSScreen.main || screen == NSScreen.screens.first
            }
        case .external:
            return !isBuiltIn
        case .all:
            return true
        }
    }

    private func updateEdgePanelsInteractivity(mouseLoc: NSPoint, isDragging: Bool) {
        guard appState.isEnabled else { return }
        let shelf = appState.stashShelf
        let scratchpad = appState.scratchpad

        // Handle auto-close for Left Drawer (Shelf or Scratchpad) when mouse exits the drawer zone (unless pinned)
        let isDrawerOpen = (shelf.isShelfOpen || scratchpad.isScratchpadOpen)
        let isAnyPinned = (shelf.isShelfOpen && shelf.isPinned) || (scratchpad.isScratchpadOpen && scratchpad.isPinned)
        if isDrawerOpen && !isAnyPinned && !shelf.isDropTargetActive && !isDragging {
            if isMouseInsideLeftDrawer(mouseLoc) {
                cancelPendingLeftEdgeHide()
            } else {
                scheduleLeftEdgeHideTimer()
            }
        } else {
            cancelPendingLeftEdgeHide()
        }

        // 1. Drawer Interactivity & Extreme Edge Dwell (Shelf & Scratchpad)
        if appState.hasDrawerFeatureActive {
            let allFrames = NSScreen.screens.map { $0.frame }
            let isOpen = shelf.isShelfOpen || shelf.isDropTargetActive || scratchpad.isScratchpadOpen
            let isDrawerRight = appState.settings.drawerEdgePosition == .right

            if isOpen {
                for instance in instances.values {
                    instance.setLeftEdgeInteractive(true, allowsKey: (shelf.isShelfOpen || scratchpad.isScratchpadOpen))
                }
            } else if isDragging {
                cancelPendingLeftEdgeDwell()
                for instance in instances.values {
                    let frame = instance.screen.frame
                    let dRect = instance.drawerRect(in: frame)
                    let isDragInRangeX = isDrawerRight
                        ? (mouseLoc.x >= frame.maxX - 60 && mouseLoc.x <= frame.maxX)
                        : (mouseLoc.x >= frame.minX && mouseLoc.x <= frame.minX + 60)
                    if isDragInRangeX && mouseLoc.y >= dRect.minY && mouseLoc.y <= dRect.maxY {
                        instance.setLeftEdgeInteractive(true, allowsKey: false)
                        if !shelf.isShelfOpen {
                            shelf.openShelf(transient: true)
                        }
                    } else {
                        instance.setLeftEdgeInteractive(false, allowsKey: false)
                    }
                }
            } else {
                // Extreme edge (<= 2.5pt) requirement with intentional dwell delay across candidate displays
                let isSliderActiveOnDrawerEdge = appState.isEdgeSlidersEnabled && (
                    isDrawerRight
                        ? (appState.settings.edgeSliderPlacement == .both || appState.settings.edgeSliderPlacement == .right) && appState.activeProfile.rightEdgeAction != .none
                        : (appState.settings.edgeSliderPlacement == .both || appState.settings.edgeSliderPlacement == .left) && appState.activeProfile.leftEdgeAction != .none
                )

                if isSliderActiveOnDrawerEdge {
                    // When an Edge Slider is configured on this edge, normal cursor dwell is owned by the Edge Slider.
                    // Drawer remains fully accessible via file-drag, keyboard shortcuts, menu bar, and hot corners.
                    cancelPendingLeftEdgeDwell()
                    for instance in instances.values {
                        instance.setLeftEdgeInteractive(false, allowsKey: false)
                    }
                } else {
                    var candidateInstance: ScreenOverlayInstance?
                    var candidateFrame: NSRect = .zero
                    var candidateDrawerRect: NSRect = .zero

                    for instance in instances.values {
                        let frame = instance.screen.frame
                        let isOuterEdge: Bool
                        if appState.settings.onlyOuterCorners {
                            isOuterEdge = isDrawerRight
                                ? CornerGeometry.isOuterRightEdge(screen: frame, in: allFrames)
                                : CornerGeometry.isOuterLeftEdge(screen: frame, in: allFrames)
                        } else {
                            isOuterEdge = true
                        }

                        guard isOuterEdge else {
                            instance.setLeftEdgeInteractive(false, allowsKey: false)
                            continue
                        }

                        let dRect = instance.drawerRect(in: frame)
                        let isAtEdgeX = isDrawerRight
                            ? (mouseLoc.x >= (frame.maxX - 2.5) && mouseLoc.x <= (frame.maxX + 1.0))
                            : (mouseLoc.x <= (frame.minX + 2.5) && mouseLoc.x >= (frame.minX - 1.0))
                        let isWithinEdgeY = mouseLoc.y >= dRect.minY && mouseLoc.y <= dRect.maxY

                        if isAtEdgeX && isWithinEdgeY {
                            candidateInstance = instance
                            candidateFrame = frame
                            candidateDrawerRect = dRect
                            break
                        } else {
                            instance.setLeftEdgeInteractive(false, allowsKey: false)
                        }
                    }

                    if let candidate = candidateInstance {
                        scheduleLeftEdgeDwellTimer(displayID: candidate.displayID, screenFrame: candidateFrame, verticalRange: candidateDrawerRect)
                    } else {
                        cancelPendingLeftEdgeDwell()
                    }
                }
            }
        } else {
            cancelPendingLeftEdgeDwell()
            for instance in instances.values {
                instance.setLeftEdgeInteractive(false, allowsKey: false)
            }
        }

        // 2. Edge Slider Interactivity (Dual Edge Sliders)
        if appState.isEdgeSlidersEnabled {
            let allFrames = NSScreen.screens.map { $0.frame }
            let placement = appState.settings.edgeSliderPlacement

            for targetEdge in [EdgePosition.left, EdgePosition.right] {
                let isAllowed = (placement == .both)
                    || (targetEdge == .left && placement == .left)
                    || (targetEdge == .right && placement == .right)
                let action = targetEdge == .left ? appState.activeProfile.leftEdgeAction : appState.activeProfile.rightEdgeAction

                let isDrawerOpenOnThisEdge = (shelf.isShelfOpen || shelf.isDropTargetActive || scratchpad.isScratchpadOpen)
                    && (targetEdge == appState.settings.drawerEdgePosition)

                guard isAllowed && action != .none && !isDrawerOpenOnThisEdge else {
                    cancelPendingEdgeDwell(edge: targetEdge)
                    for instance in instances.values {
                        instance.setEdgeInteractive(false, for: targetEdge)
                    }
                    continue
                }

                let isActive = targetEdge == .left ? appState.isLeftSliderActive : appState.isRightSliderActive
                if isActive {
                    var isInsideActiveSlider = false
                    for (id, instance) in instances {
                        guard appState.activeDisplayID == 0 || appState.activeDisplayID == id else {
                            instance.setEdgeInteractive(false, for: targetEdge)
                            continue
                        }
                        let frame = instance.screen.frame
                        let sRect = instance.sliderRect(for: targetEdge, in: frame)
                        let expandedHitRect = CornerGeometry.edgeSliderHitRect(
                            screenFrame: frame,
                            sliderPanelRect: sRect,
                            edge: targetEdge
                        )
                        if CornerGeometry.rectContains(expandedHitRect, mouseLoc) {
                            isInsideActiveSlider = true
                            cancelEdgeHideTimer(edge: targetEdge)
                            instance.setEdgeInteractive(true, for: targetEdge)
                            break
                        }
                    }
                    if !isInsideActiveSlider {
                        scheduleEdgeHideTimer(edge: targetEdge)
                    }
                } else {
                    var candidateInstance: ScreenOverlayInstance?
                    var candidateFrame: NSRect = .zero
                    var candidateSliderRect: NSRect = .zero

                    for instance in instances.values {
                        let frame = instance.screen.frame
                        let isOuterEdge: Bool
                        if appState.settings.onlyOuterCorners {
                            isOuterEdge = targetEdge == .left
                                ? CornerGeometry.isOuterLeftEdge(screen: frame, in: allFrames)
                                : CornerGeometry.isOuterRightEdge(screen: frame, in: allFrames)
                        } else {
                            isOuterEdge = true
                        }

                        guard isOuterEdge else {
                            instance.setEdgeInteractive(false, for: targetEdge)
                            continue
                        }

                        let sRect = instance.sliderRect(for: targetEdge, in: frame)
                        let isAtEdgeX = targetEdge == .left
                            ? (mouseLoc.x <= (frame.minX + 2.5) && mouseLoc.x >= (frame.minX - 1.0))
                            : (mouseLoc.x >= (frame.maxX - 2.5) && mouseLoc.x <= (frame.maxX + 1.0))
                        let isWithinEdgeY = mouseLoc.y >= sRect.minY && mouseLoc.y <= sRect.maxY

                        if isAtEdgeX && isWithinEdgeY {
                            candidateInstance = instance
                            candidateFrame = frame
                            candidateSliderRect = sRect
                            break
                        } else {
                            instance.setEdgeInteractive(false, for: targetEdge)
                        }
                    }

                    if let candidate = candidateInstance {
                        scheduleEdgeDwellTimer(edge: targetEdge, displayID: candidate.displayID, screenFrame: candidateFrame, verticalRange: candidateSliderRect)
                    } else {
                        cancelPendingEdgeDwell(edge: targetEdge)
                    }
                }
            }
        } else {
            cancelPendingEdgeDwell(edge: .left)
            cancelPendingEdgeDwell(edge: .right)
            for instance in instances.values {
                instance.setEdgeInteractive(false, for: .left)
                instance.setEdgeInteractive(false, for: .right)
            }
        }
    }

    public func scheduleEdgeDwellTimer(edge: EdgePosition, displayID: CGDirectDisplayID, screenFrame: NSRect, verticalRange: NSRect) {
        if edge == .left {
            if pendingLeftSliderDisplayID == displayID { return }
            cancelPendingEdgeDwell(edge: .left)
            pendingLeftSliderDisplayID = displayID
        } else {
            if pendingRightEdgeDisplayID == displayID { return }
            cancelPendingEdgeDwell(edge: .right)
            pendingRightEdgeDisplayID = displayID
        }

        let delay = max(0.15, appState.cornerDwellDelay)
        let item = DispatchWorkItem { [weak self] in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if edge == .left {
                    guard self.pendingLeftSliderDisplayID == displayID else { return }
                } else {
                    guard self.pendingRightEdgeDisplayID == displayID else { return }
                }

                let cur = NSEvent.mouseLocation
                let matchesEdge = CornerGeometry.isCursorAtVerticalEdge(
                    point: cur,
                    screenFrame: screenFrame,
                    verticalRange: verticalRange,
                    edge: edge
                )
                if matchesEdge {
                    self.appState.syncHardwareState(force: true)
                    self.appState.activeDisplayID = displayID
                    if edge == .left {
                        self.appState.isLeftSliderActive = true
                    } else {
                        self.appState.isRightSliderActive = true
                    }
                    for (id, inst) in self.instances {
                        inst.setEdgeInteractive(id == displayID, for: edge)
                    }
                    HapticManager.shared.performDetentTick(intensity: self.appState.effectiveHapticIntensity)
                }
                if edge == .left {
                    self.pendingLeftSliderDisplayID = nil
                } else {
                    self.pendingRightEdgeDisplayID = nil
                }
            }
        }

        if edge == .left {
            self.leftSliderDwellWorkItem = item
        } else {
            self.rightEdgeDwellWorkItem = item
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: item)
    }

    public func cancelPendingEdgeDwell(edge: EdgePosition) {
        if edge == .left {
            leftSliderDwellWorkItem?.cancel()
            leftSliderDwellWorkItem = nil
            pendingLeftSliderDisplayID = nil
        } else {
            rightEdgeDwellWorkItem?.cancel()
            rightEdgeDwellWorkItem = nil
            pendingRightEdgeDisplayID = nil
        }
    }

    public func scheduleEdgeHideTimer(edge: EdgePosition) {
        if edge == .left {
            guard leftSliderHideWorkItem == nil else { return }
        } else {
            guard rightEdgeHideWorkItem == nil else { return }
        }

        let item = DispatchWorkItem { [weak self] in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                let cur = NSEvent.mouseLocation
                var stillInside = false
                for (id, instance) in self.instances {
                    if self.appState.activeDisplayID != 0 && self.appState.activeDisplayID != id {
                        continue
                    }
                    let frame = instance.screen.frame
                    let sliderRect = instance.sliderRect(for: edge, in: frame)
                    let expandedHitRect = CornerGeometry.edgeSliderHitRect(
                        screenFrame: frame,
                        sliderPanelRect: sliderRect,
                        edge: edge
                    )
                    if CornerGeometry.rectContains(expandedHitRect, cur) {
                        stillInside = true
                        break
                    }
                }
                if !stillInside {
                    self.dismissEdgeSlider(edge: edge)
                }
                if edge == .left {
                    self.leftSliderHideWorkItem = nil
                } else {
                    self.rightEdgeHideWorkItem = nil
                }
            }
        }

        if edge == .left {
            leftSliderHideWorkItem = item
        } else {
            rightEdgeHideWorkItem = item
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18, execute: item)
    }

    public func cancelEdgeHideTimer(edge: EdgePosition) {
        if edge == .left {
            leftSliderHideWorkItem?.cancel()
            leftSliderHideWorkItem = nil
        } else {
            rightEdgeHideWorkItem?.cancel()
            rightEdgeHideWorkItem = nil
        }
    }

    public func dismissEdgeSlider(edge: EdgePosition) {
        cancelPendingEdgeDwell(edge: edge)
        cancelEdgeHideTimer(edge: edge)
        if edge == .left {
            appState.isLeftSliderActive = false
        } else {
            appState.isRightSliderActive = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else { return }
            let stillActive = edge == .left ? self.appState.isLeftSliderActive : self.appState.isRightSliderActive
            guard !stillActive else { return }
            if !self.appState.isLeftSliderActive && !self.appState.isRightSliderActive {
                self.appState.activeDisplayID = 0
            }
            for instance in self.instances.values {
                instance.setEdgeInteractive(false, for: edge)
            }
        }
    }

    public func scheduleRightEdgeHideTimer() {
        scheduleEdgeHideTimer(edge: .right)
    }

    public func dismissRightSlider() {
        dismissEdgeSlider(edge: .right)
    }

    public func reconfigureOverlays() {
        for instance in instances.values {
            instance.repositionPanels()
        }
    }

    public func isMouseInsideLeftDrawer(_ point: NSPoint) -> Bool {
        let drawerEdge = appState.settings.drawerEdgePosition
        for instance in instances.values {
            let frame = instance.screen.frame
            let drawerPanelRect = instance.drawerRect(in: frame)
            let activeWidth: CGFloat = appState.scratchpad.isScratchpadOpen
                ? Defaults.LeftEdgeDrawer.scratchpadTotalWidthPoints
                : Defaults.LeftEdgeDrawer.shelfTotalWidthPoints
            let activeHeight: CGFloat = appState.scratchpad.isScratchpadOpen
                ? Defaults.LeftEdgeDrawer.scratchpadTotalHeightPoints
                : Defaults.LeftEdgeDrawer.shelfTotalHeightPoints
            let drawerRect = CornerGeometry.edgeDrawerHitRect(
                screenFrame: frame,
                drawerPanelRect: drawerPanelRect,
                edge: drawerEdge,
                drawerWidth: activeWidth,
                drawerHeight: activeHeight,
                margin: 25.0
            )
            if CornerGeometry.rectContains(drawerRect, point) {
                return true
            }
        }
        return false
    }

    public func scheduleLeftEdgeHideTimer() {
        guard leftEdgeHideWorkItem == nil else { return }
        let item = DispatchWorkItem { [weak self] in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                let cur = NSEvent.mouseLocation
                let stillInside = self.isMouseInsideLeftDrawer(cur)
                let isDragging = (NSEvent.pressedMouseButtons != 0)
                let shelf = self.appState.stashShelf
                let scratchpad = self.appState.scratchpad
                let isAnyPinned = (shelf.isShelfOpen && shelf.isPinned) || (scratchpad.isScratchpadOpen && scratchpad.isPinned)
                if !stillInside && !isDragging && !shelf.isDropTargetActive && !isAnyPinned {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                        shelf.closeShelf()
                        scratchpad.isScratchpadOpen = false
                    }
                }
                self.leftEdgeHideWorkItem = nil
            }
        }
        self.leftEdgeHideWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: item)
    }

    public func cancelPendingLeftEdgeHide() {
        leftEdgeHideWorkItem?.cancel()
        leftEdgeHideWorkItem = nil
    }

    private func scheduleLeftEdgeDwellTimer(displayID: CGDirectDisplayID, screenFrame: NSRect, verticalRange: NSRect) {
        if pendingLeftEdgeDisplayID == displayID { return }
        cancelPendingLeftEdgeDwell()
        pendingLeftEdgeDisplayID = displayID

        let delay = max(0.15, appState.cornerDwellDelay)
        let targetEdge = appState.settings.drawerEdgePosition
        let item = DispatchWorkItem { [weak self] in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                guard self.pendingLeftEdgeDisplayID == displayID else { return }
                let cur = NSEvent.mouseLocation
                let matchesEdge = CornerGeometry.isCursorAtVerticalEdge(
                    point: cur,
                    screenFrame: screenFrame,
                    verticalRange: verticalRange,
                    edge: targetEdge
                )
                if matchesEdge {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                        if self.appState.settings.isStashShelfEnabled {
                            self.appState.stashShelf.openShelf(transient: true)
                        } else if self.appState.settings.isScratchpadEnabled {
                            self.appState.scratchpad.isScratchpadOpen = true
                        }
                    }
                    for (id, inst) in self.instances {
                        inst.setLeftEdgeInteractive(id == displayID, allowsKey: true)
                    }
                    HapticManager.shared.performDetentTick(intensity: self.appState.effectiveHapticIntensity)
                }
                self.pendingLeftEdgeDisplayID = nil
            }
        }
        self.leftEdgeDwellWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: item)
    }

    private func cancelPendingLeftEdgeDwell() {
        leftEdgeDwellWorkItem?.cancel()
        leftEdgeDwellWorkItem = nil
        pendingLeftEdgeDisplayID = nil
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
                let sensitivity = max(Defaults.HotCorner.minHitZoneSizePoints, self.appState.cornerSensitivityRadius)
                if dist <= sensitivity {
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

    public func keepDialActive() {
        hideWorkItem?.cancel()
        hideWorkItem = nil
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
        appState.syncHardwareState(force: true)
        appState.activeCorner = corner
        appState.activeDisplayID = displayID
        instances[displayID]?.setMouseInteractive(true, for: corner)
        appState.haptics.performDetentTick(intensity: appState.effectiveHapticIntensity)
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

    private func updateEdgeVisualizerState() {
        let rightHasMedia = appState.isRightSliderActive
            && ((appState.activeProfile.rightEdgeAction == .volume && appState.settings.edgeBarShowMediaControls)
                || appState.activeProfile.rightEdgeAction == .mediaPlayback)
        let leftHasMedia = appState.isLeftSliderActive
            && ((appState.activeProfile.leftEdgeAction == .volume && appState.settings.edgeBarShowMediaControls)
                || appState.activeProfile.leftEdgeAction == .mediaPlayback)
        let visualizerOn = appState.settings.edgeBarVisualizerEnabled && (rightHasMedia || leftHasMedia)
        NowPlayingManager.shared.setVisualizerActive(visualizerOn)
    }

    private func handleKeyEvent(_ event: NSEvent) {
        if event.keyCode == 53 { // Escape closes the topmost transient surface
            if appState.isCursorPalettePresented {
                dismissCursorPalette()
            } else if appState.activeCorner != nil {
                dismissActiveDial()
            } else if appState.stashShelf.isShelfOpen {
                appState.stashShelf.closeShelf()
            } else if appState.scratchpad.isScratchpadOpen {
                appState.scratchpad.isScratchpadOpen = false
            } else if appState.isRightSliderActive || appState.isLeftSliderActive {
                if appState.isRightSliderActive {
                    dismissEdgeSlider(edge: .right)
                }
                if appState.isLeftSliderActive {
                    dismissEdgeSlider(edge: .left)
                }
            }
            return
        }

        if matchesConfiguredShortcut(event: event, shortcutString: appState.settings.globalToggleDialsShortcut) {
            toggleDials()
            return
        }

        let s = appState.settings
        if s.isCursorPaletteEnabled, !s.cursorPaletteShortcut.isEmpty,
           matchesConfiguredShortcut(event: event, shortcutString: s.cursorPaletteShortcut) {
            toggleCursorPalette()
        } else if s.isStashShelfEnabled, !s.stashShelfShortcut.isEmpty,
                  matchesConfiguredShortcut(event: event, shortcutString: s.stashShelfShortcut) {
            appState.stashShelf.isShelfOpen.toggle()
            HapticManager.shared.performBoundaryClick()
        } else if s.isScratchpadEnabled, !s.scratchpadShortcut.isEmpty,
                  matchesConfiguredShortcut(event: event, shortcutString: s.scratchpadShortcut) {
            appState.scratchpad.isScratchpadOpen.toggle()
            HapticManager.shared.performBoundaryClick()
        } else if matchesConfiguredShortcut(event: event, shortcutString: "ctrl+opt+d") {
            appState.sideDock.toggleDock()
            HapticManager.shared.performBoundaryClick()
        }

        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if flags == [.control] || flags == [.control, .option] {
            let digitCodes: [UInt16: Int] = [
                18: 0,
                19: 1,
                20: 2,
                21: 3,
                23: 4,
                22: 5,
                26: 6,
                28: 7
            ]
            if let profileIdx = digitCodes[event.keyCode], profileIdx < appState.sideDock.config.profiles.count {
                appState.sideDock.selectProfile(at: profileIdx)
                HapticManager.shared.performBoundaryClick()
            }
        }
    }

    private func matchesConfiguredShortcut(event: NSEvent, shortcutString: String) -> Bool {
        let canonical = ShortcutValidator.canonicalize(shortcutString)
        let parts = canonical
            .split(separator: "+")
            .map(String.init)

        guard !parts.isEmpty else { return false }

        var expectedFlags: NSEvent.ModifierFlags = []
        var expectedKey: String? = nil

        for part in parts {
            switch part {
            case "option":
                expectedFlags.insert(.option)
            case "command":
                expectedFlags.insert(.command)
            case "shift":
                expectedFlags.insert(.shift)
            case "control":
                expectedFlags.insert(.control)
            default:
                expectedKey = part
            }
        }

        let eventFlags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        guard eventFlags == expectedFlags else { return false }

        guard let key = expectedKey else { return false }
        guard let expectedCode = keyCode(for: key) else { return false }

        return event.keyCode == expectedCode
    }

    private func keyCode(for keyString: String) -> UInt16? {
        switch keyString.lowercased() {
        case "a": return 0
        case "s": return 1
        case "d": return 2
        case "f": return 3
        case "h": return 4
        case "g": return 5
        case "z": return 6
        case "x": return 7
        case "c": return 8
        case "v": return 9
        case "b": return 11
        case "q": return 12
        case "w": return 13
        case "e": return 14
        case "r": return 15
        case "y": return 16
        case "t": return 17
        case "1": return 18
        case "2": return 19
        case "3": return 20
        case "4": return 21
        case "6": return 22
        case "5": return 23
        case "9": return 25
        case "7": return 26
        case "8": return 28
        case "0": return 29
        case "o": return 31
        case "u": return 32
        case "i": return 34
        case "p": return 35
        case "l": return 37
        case "j": return 38
        case "k": return 40
        case "n": return 45
        case "m": return 46
        case "space": return 49
        case "tab": return 48
        case "return", "enter": return 36
        case "esc", "escape": return 53
        default: return nil
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

    // MARK: - Cursor Radial Palette

    private var cursorPalettePanel: MacStashInteractivePanel?
    private var paletteObserver: AnyCancellable?

    public func toggleCursorPalette() {
        if appState.isCursorPalettePresented {
            dismissCursorPalette()
        } else {
            showCursorPalette()
        }
    }

    public func showCursorPalette() {
        let mouse = NSEvent.mouseLocation
        let side: CGFloat = 284
        let targetScreen = NSScreen.screens.first(where: { $0.frame.contains(mouse) }) ?? NSScreen.main ?? NSScreen.screens.first
        let vis = targetScreen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let clampedX = min(max(mouse.x - side / 2, vis.minX + 12), max(vis.minX + 12, vis.maxX - side - 12))
        let clampedY = min(max(mouse.y - side / 2, vis.minY + 12), max(vis.minY + 12, vis.maxY - side - 12))
        let rect = NSRect(x: clampedX, y: clampedY, width: side, height: side)

        if cursorPalettePanel == nil {
            let panel = MacStashInteractivePanel(
                contentRect: rect,
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            panel.allowsKeyWindow = true
            panel.contentView = InteractiveHostingView(rootView: CursorPaletteView(appState: appState))
            cursorPalettePanel = panel
            paletteObserver = appState.$isCursorPalettePresented
                .receive(on: DispatchQueue.main)
                .sink { [weak self] presented in
                    if !presented {
                        self?.cursorPalettePanel?.orderOut(nil)
                        self?.cursorPalettePanel?.ignoresMouseEvents = true
                    }
                }
        }

        cursorPalettePanel?.ignoresMouseEvents = false
        cursorPalettePanel?.setFrame(rect, display: true)
        cursorPalettePanel?.orderFrontRegardless()
        appState.isCursorPalettePresented = true
        HapticManager.shared.performDetentTick(intensity: appState.effectiveHapticIntensity)
    }

    public func dismissCursorPalette() {
        cursorPalettePanel?.orderOut(nil)
        cursorPalettePanel?.ignoresMouseEvents = true
        appState.isCursorPalettePresented = false
    }
}
