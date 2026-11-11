import AppKit
import SwiftUI
import MacStashCore

/// An NSView hosting wrapper that provides intelligent pass-through hit testing for edge sliders.
/// Only the edge trigger strip receives hit tests when collapsed; the full slider body receives
/// mouse events when hovered, active, or dragging.
public final class EdgeSliderHostingView: NSHostingView<EdgeSliderView> {
    private let appState: AppState
    public let displayID: CGDirectDisplayID
    private var scrollEndWorkItem: DispatchWorkItem?

    public init(
        rootView: EdgeSliderView,
        appState: AppState,
        displayID: CGDirectDisplayID = 0
    ) {
        self.appState = appState
        self.displayID = displayID
        super.init(rootView: rootView)
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

        guard appState.activeProfile.rightEdgeAction != .none else {
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

        // When slider is active (expanded), intercept mouse events within the 80pt slider panel
        if appState.isRightSliderActive {
            if appState.activeDisplayID != 0 && appState.activeDisplayID != displayID {
                return nil
            }
            return super.hitTest(point)
        }

        // When collapsed, return nil completely so background application scrollbars,
        // window controls, and rightmost click targets remain 100% unobstructed.
        return nil
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
        ScreenManager.shared.scheduleRightEdgeHideTimer()
    }

    public override func scrollWheel(with event: NSEvent) {
        guard appState.isEnabled,
              appState.isEdgeSlidersEnabled,
              appState.scrollAdjustmentEnabled else {
            super.scrollWheel(with: event)
            return
        }

        let action = appState.activeProfile.rightEdgeAction
        guard action != .none else {
            super.scrollWheel(with: event)
            return
        }

        // Filter out momentum events to prevent values from runaway changes after lifting fingers
        if event.hasPreciseScrollingDeltas && !event.momentumPhase.isEmpty {
            return
        }

        let rawDeltaY = event.hasPreciseScrollingDeltas ? event.scrollingDeltaY : (event.deltaY * 10.0)
        guard abs(rawDeltaY) > 0.001 else { return }

        // With Natural Scrolling on macOS, swiping fingers UP produces negative rawDeltaY.
        // On a vertical slider, swiping fingers UP should slide the slider UP (increase).
        let deltaY: CGFloat = event.isDirectionInvertedFromDevice ? -rawDeltaY : rawDeltaY

        let sensitivity: Float = 0.005
        let step = Float(deltaY) * sensitivity
        let current = appState.liveEdgeSliderValue ?? Float(appState.getValue(for: action, displayID: rootView.displayID))
        let clamped = max(0.0, min(1.0, current + step))

        appState.liveEdgeSliderValue = clamped
        appState.setValue(for: action, value: Double(clamped), displayID: rootView.displayID)

        scrollEndWorkItem?.cancel()
        if event.phase == .ended || event.phase == .cancelled {
            appState.liveEdgeSliderValue = nil
            appState.saveSettings()
        } else {
            let item = DispatchWorkItem { [weak self] in
                guard let self = self else { return }
                self.appState.liveEdgeSliderValue = nil
                self.appState.saveSettings()
            }
            scrollEndWorkItem = item
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22, execute: item)
        }
    }
}
