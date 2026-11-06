import AppKit
import SwiftUI
import MacStashCore

/// An NSView hosting wrapper that provides intelligent pass-through hit testing for edge sliders.
/// Only the edge trigger strip receives hit tests when collapsed; the full slider body receives
/// mouse events when hovered, active, or dragging.
public final class EdgeSliderHostingView: NSHostingView<EdgeSliderView> {
    private let appState: AppState
    private let edge: EdgePosition

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

        // When collapsed, only intercept along the thin outer edge strip (10 pt)
        let edgeHitZone: CGFloat = 10
        let triggerRect = (edge == .right)
            ? NSRect(x: bounds.maxX - edgeHitZone, y: bounds.minY, width: edgeHitZone, height: bounds.height)
            : NSRect(x: bounds.minX, y: bounds.minY, width: edgeHitZone, height: bounds.height)

        if triggerRect.contains(point) {
            return super.hitTest(point)
        }

        return nil
    }
}
