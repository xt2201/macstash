import AppKit
import SwiftUI
import MacStashCore

/// An NSView hosting wrapper that provides intelligent pass-through hit testing for edge sliders.
/// Only the edge trigger strip receives hit tests when collapsed; the full slider body and
/// horizontally expanded Dynamic Island receive mouse events when active or dragging.
public final class EdgeSliderHostingView: NSHostingView<EdgeSliderView> {
    private let appState: AppState
    public let displayID: CGDirectDisplayID
    private var scrollEndWorkItem: DispatchWorkItem?

    public var edge: EdgePosition {
        rootView.edge
    }

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

        // When slider is active (expanded), intercept mouse events
        let isActive = edge == .left ? appState.isLeftSliderActive : appState.isRightSliderActive
        if isActive {
            if appState.activeDisplayID != 0 && appState.activeDisplayID != displayID {
                return nil
            }
            return super.hitTest(point)
        }

        // When collapsed, return nil completely so background application scrollbars,
        // window controls, and edge click targets remain 100% unobstructed.
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

        // Filter out momentum events to prevent values from runaway changes after lifting fingers
        if event.hasPreciseScrollingDeltas && !event.momentumPhase.isEmpty {
            return
        }

        let rawDeltaX = event.hasPreciseScrollingDeltas ? event.scrollingDeltaX : (event.deltaX * 10.0)
        let rawDeltaY = event.hasPreciseScrollingDeltas ? event.scrollingDeltaY : (event.deltaY * 10.0)

        // Physical finger movement vector accounting for macOS Natural Scrolling
        let physicalX: Double = event.isDirectionInvertedFromDevice ? -Double(rawDeltaX) : Double(rawDeltaX)
        let physicalY: Double = event.isDirectionInvertedFromDevice ? -Double(rawDeltaY) : Double(rawDeltaY)

        let loc = convert(event.locationInWindow, from: nil)
        let isOverBottomMedia = loc.y < 160.0
        let hasMedia = NowPlayingManager.shared.hasMedia

        // Horizontal audio scrubbing: when cursor is over media island OR when swiping horizontally with active media
        let isHorizontalScrub = hasMedia && (isOverBottomMedia || abs(physicalX) > abs(physicalY) * 1.25) && abs(physicalX) > 0.05

        if isHorizontalScrub {
            ScreenManager.shared.cancelEdgeHideTimer(edge: edge)

            let dur = NowPlayingManager.shared.duration
            let durFactor = dur > 0 ? max(0.6, min(2.5, dur / 240.0)) : 1.0
            let deltaSeconds = physicalX * 0.22 * durFactor

            NowPlayingManager.shared.updateInteractiveScrub(deltaSeconds: deltaSeconds)

            if event.phase == .ended || event.phase == .cancelled {
                NowPlayingManager.shared.commitInteractiveScrub()
                ScreenManager.shared.scheduleEdgeHideTimer(edge: edge)
            }
            return
        }

        guard abs(physicalY) > 0.001 else { return }

        ScreenManager.shared.cancelEdgeHideTimer(edge: edge)

        let sensitivity: Float = 0.005
        let step = Float(physicalY) * sensitivity
        let current = (edge == .left ? appState.liveLeftSliderValue : appState.liveRightSliderValue) ?? Float(appState.getValue(for: action, displayID: rootView.displayID))
        let clamped = max(0.0, min(1.0, current + step))

        if edge == .left {
            appState.liveLeftSliderValue = clamped
        } else {
            appState.liveRightSliderValue = clamped
        }
        appState.setValue(for: action, value: Double(clamped), displayID: rootView.displayID)

        scrollEndWorkItem?.cancel()
        if event.phase == .ended || event.phase == .cancelled {
            if edge == .left {
                appState.liveLeftSliderValue = nil
            } else {
                appState.liveRightSliderValue = nil
            }
            appState.saveSettings()
            ScreenManager.shared.scheduleEdgeHideTimer(edge: edge)
        } else {
            let item = DispatchWorkItem { [weak self] in
                guard let self = self else { return }
                if self.edge == .left {
                    self.appState.liveLeftSliderValue = nil
                } else {
                    self.appState.liveRightSliderValue = nil
                }
            }
            scrollEndWorkItem = item
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: item)
        }
    }
}
