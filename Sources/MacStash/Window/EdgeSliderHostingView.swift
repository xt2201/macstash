import AppKit
import SwiftUI
import MacStashCore

/// An NSView hosting wrapper that provides intelligent pass-through hit testing for edge sliders.
/// Only the edge trigger strip receives hit tests when collapsed; the full slider body receives
/// mouse events when hovered, active, or dragging.
public final class EdgeSliderHostingView: NSHostingView<EdgeSliderView> {
    private let appState: AppState
    private let edge: EdgePosition
    private var scrollEndWorkItem: DispatchWorkItem?

    public init(
        rootView: EdgeSliderView,
        appState: AppState,
        edge: EdgePosition = .right
    ) {
        self.appState = appState
        self.edge = edge
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

        // When slider is active (expanded), full frame is interactive
        if appState.isRightSliderActive {
            return super.hitTest(point)
        }

        // When collapsed, only intercept along the thin outer edge strip (14 pt)
        let edgeHitZone: CGFloat = 14
        let triggerRect = (edge == .right)
            ? NSRect(x: bounds.maxX - edgeHitZone, y: bounds.minY, width: edgeHitZone, height: bounds.height)
            : NSRect(x: bounds.minX, y: bounds.minY, width: edgeHitZone, height: bounds.height)

        if triggerRect.contains(point) {
            return super.hitTest(point)
        }

        return nil
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

        let deltaY = event.hasPreciseScrollingDeltas ? event.scrollingDeltaY : (event.deltaY * 10.0)
        guard abs(deltaY) > 0.001 else { return }

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
