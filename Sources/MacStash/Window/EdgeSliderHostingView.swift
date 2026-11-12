import AppKit
import SwiftUI
import MacStashCore

/// An NSView hosting wrapper that provides intelligent pass-through hit testing for edge sliders.
/// Only the edge trigger strip receives hit tests when collapsed; the full slider body and
/// horizontally expanded Dynamic Island receive mouse events when active or dragging.
public final class EdgeSliderHostingView: NSHostingView<EdgeSliderView> {
    private let appState: AppState
    private let interactionState: EdgeSliderInteractionState
    public let displayID: CGDirectDisplayID
    private var scrollEndWorkItem: DispatchWorkItem?

    public var edge: EdgePosition {
        rootView.edge
    }

    public init(
        rootView: EdgeSliderView,
        appState: AppState,
        displayID: CGDirectDisplayID = 0,
        interactionState: EdgeSliderInteractionState = EdgeSliderInteractionState()
    ) {
        self.appState = appState
        self.displayID = displayID
        self.interactionState = interactionState
        super.init(rootView: rootView)
        // The panel frame is the single source of truth for the interactive hit zone (ScreenManager hit rects).
        // SwiftUI content must never resize the window, otherwise the bar drifts outside the hit zone and gets dismissed.
        sizingOptions = []
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @available(*, unavailable)
    required init(rootView: EdgeSliderView) {
        fatalError("init(rootView:) has not been implemented")
    }

    public override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }

    public override func hitTest(_ point: NSPoint) -> NSView? {
        guard appState.isEnabled && appState.isEdgeSlidersEnabled else {
            return nil
        }

        let action = edge == .left ? appState.activeProfile.leftEdgeAction : appState.activeProfile.rightEdgeAction
        guard action != .none else {
            return nil
        }

        // Fullscreen suppression
        if appState.settings.suppressInFullscreen && NSApplication.shared.presentationOptions.contains(.fullScreen) {
            return nil
        }

        // Excluded applications suppression
        if let frontApp = NSWorkspace.shared.frontmostApplication?.bundleIdentifier,
           appState.settings.excludedBundleIDs.contains(frontApp) {
            return nil
        }

        // Dial active suppression
        if appState.activeCorner != nil {
            return nil
        }

        // When slider is active (expanded), intercept only visible UI bounds so transparent outer space passes through
        let isActive = edge == .left ? appState.isLeftSliderActive : appState.isRightSliderActive
        if isActive {
            if appState.activeDisplayID != 0 && appState.activeDisplayID != displayID {
                return nil
            }
            let localPoint = superview != nil ? convert(point, from: superview) : point
            if isPointInsideVisibleSurface(localPoint) {
                return super.hitTest(point)
            }
            return nil
        }

        // When collapsed, return nil completely so background application scrollbars,
        // window controls, and edge click targets remain 100% unobstructed.
        return nil
    }

    private func isPointInsideVisibleSurface(_ point: NSPoint) -> Bool {
        guard bounds.contains(point) else { return false }
        if interactionState.isSliderDragging || NowPlayingManager.shared.isInteractiveScrubbing {
            return true
        }
        let isRight = (edge == .right)
        let stripWidth: CGFloat = 88.0
        let stripX = isRight ? (bounds.maxX - stripWidth) : bounds.minX
        let edgeStripRect = NSRect(x: stripX, y: bounds.minY, width: stripWidth, height: bounds.height)

        if interactionState.isMediaExpanded {
            let bandH: CGFloat = 145.0
            let isVolumeShowing = interactionState.isVolumeColumnVisible
                || interactionState.isVolumeButtonHovered
                || interactionState.isVolumeColumnHovered
            let islandBottom = bounds.height - 60.0
            let bandY = isFlipped ? (islandBottom - bandH) : (60.0 - 10.0)
            let islandBandRect = NSRect(x: bounds.minX, y: bandY, width: bounds.width, height: bandH + 10.0)
            if islandBandRect.contains(point) {
                return true
            }
            return isVolumeShowing && edgeStripRect.contains(point)
        }

        return edgeStripRect.contains(point)
    }

    // MARK: - Mouse Exit & Tracking Area

    private var sliderTrackingArea: NSTrackingArea?

    public override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let existing = sliderTrackingArea {
            removeTrackingArea(existing)
        }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .mouseMoved, .activeAlways],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        self.sliderTrackingArea = area
    }

    public override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        ScreenManager.shared.scheduleEdgeHideTimer(edge: edge)
    }

    public override func scrollWheel(with event: NSEvent) {
        guard appState.isEnabled,
              appState.isEdgeSlidersEnabled,
              appState.scrollAdjustmentEnabled else {
            super.scrollWheel(with: event)
            return
        }

        let action = edge == .left ? appState.activeProfile.leftEdgeAction : appState.activeProfile.rightEdgeAction
        guard action != .none else {
            super.scrollWheel(with: event)
            return
        }

        // Commit active gestures immediately when fingers lift (delta on .ended is typically 0)
        if event.phase == .ended || event.phase == .cancelled {
            if NowPlayingManager.shared.isInteractiveScrubbing {
                NowPlayingManager.shared.commitInteractiveScrub()
            }
            scrollEndWorkItem?.cancel()
            if edge == .left {
                appState.liveLeftSliderValue = nil
            } else {
                appState.liveRightSliderValue = nil
            }
            appState.saveSettings()
            ScreenManager.shared.scheduleEdgeHideTimer(edge: edge)
            return
        }

        // Filter out momentum events to prevent runaway changes after lifting fingers
        if event.hasPreciseScrollingDeltas && !event.momentumPhase.isEmpty {
            return
        }

        let rawDeltaX = event.hasPreciseScrollingDeltas ? event.scrollingDeltaX : (event.deltaX * 10.0)
        let rawDeltaY = event.hasPreciseScrollingDeltas ? event.scrollingDeltaY : (event.deltaY * 10.0)

        let vector = ScrollInputPolicy.normalize(
            rawDeltaX: Double(rawDeltaX),
            rawDeltaY: Double(rawDeltaY),
            isDirectionInvertedFromDevice: event.isDirectionInvertedFromDevice
        )

        let loc = convert(event.locationInWindow, from: nil)
        let boundaryY = isFlipped ? (bounds.maxY - 60.0 - 145.0) : (bounds.minY + 60.0 + 145.0)
        let isInUpperColumnY = isFlipped ? (loc.y < boundaryY) : (loc.y > boundaryY)
        let isInVolumeBtnRect = EdgeBarScrollPolicy.isCursorInIslandVolumeButton(
            localPoint: loc,
            bounds: bounds,
            edge: edge,
            isFlipped: isFlipped,
            bottomInset: 60.0
        )

        let scrollTarget = EdgeBarScrollPolicy.resolveTarget(
            action: action,
            isMediaExpanded: interactionState.isMediaExpanded,
            isVolumeButtonHovered: interactionState.isVolumeButtonHovered,
            isVolumeColumnHovered: interactionState.isVolumeColumnHovered,
            isVolumeColumnVisible: interactionState.isVolumeColumnVisible,
            isCursorInUpperColumn: isInUpperColumnY,
            isCursorInVolumeButtonRect: isInVolumeBtnRect
        )

        switch scrollTarget {
        case .audioScrub:
            let scrubMotion = ScrollInputPolicy.dominantAxisStep(x: vector.x, y: vector.y)
            guard abs(scrubMotion) > 0.001 else { return }

            ScreenManager.shared.cancelEdgeHideTimer(edge: edge)

            let dur = NowPlayingManager.shared.duration
            let durFactor = dur > 0 ? max(0.35, min(2.5, dur / 240.0)) : 1.0
            let deltaSeconds = scrubMotion * 0.22 * durFactor

            NowPlayingManager.shared.updateInteractiveScrub(deltaSeconds: deltaSeconds)

        case .control(let targetAction):
            if NowPlayingManager.shared.isInteractiveScrubbing {
                NowPlayingManager.shared.commitInteractiveScrub()
            }

            let sliderMotion = ScrollInputPolicy.dominantAxisStep(x: vector.x, y: vector.y)
            guard abs(sliderMotion) > 0.001 else { return }

            ScreenManager.shared.cancelEdgeHideTimer(edge: edge)

            let sensitivity: Float = 0.005
            let step = Float(sliderMotion) * sensitivity
            let current: Float
            if targetAction == action {
                current = (edge == .left ? appState.liveLeftSliderValue : appState.liveRightSliderValue)
                    ?? Float(appState.getValue(for: targetAction, displayID: rootView.displayID))
            } else {
                current = Float(appState.getValue(for: targetAction, displayID: rootView.displayID))
            }
            let clamped = max(0.0, min(1.0, current + step))

            if targetAction == action {
                if edge == .left {
                    appState.liveLeftSliderValue = clamped
                } else {
                    appState.liveRightSliderValue = clamped
                }
            }
            appState.setValue(for: targetAction, value: Double(clamped), displayID: rootView.displayID)

            scrollEndWorkItem?.cancel()
            let item = DispatchWorkItem { [weak self] in
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    if self.edge == .left {
                        self.appState.liveLeftSliderValue = nil
                    } else {
                        self.appState.liveRightSliderValue = nil
                    }
                }
            }
            scrollEndWorkItem = item
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: item)
        }
    }
}
