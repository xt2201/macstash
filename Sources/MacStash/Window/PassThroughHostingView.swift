import AppKit
import SwiftUI
import MacStashCore

/// An NSView hosting wrapper that implements precise outer-corner dwell detection,
/// pass-through mouse handling, and formal overlay state machine transitions.
public final class PassThroughHostingView<Content: View>: NSHostingView<Content> {
    public let corner: CornerPosition
    public let displayID: CGDirectDisplayID
    public let screenFrame: NSRect
    private let appState: AppState

    private var stateMachine: OverlayStateMachine
    private var dwellTimer: Timer?
    private var hideTimer: Timer?

    public init(
        rootView: Content,
        corner: CornerPosition,
        displayID: CGDirectDisplayID,
        screenFrame: NSRect,
        appState: AppState
    ) {
        self.corner = corner
        self.displayID = displayID
        self.screenFrame = screenFrame
        self.appState = appState
        self.stateMachine = OverlayStateMachine(
            dwellDelaySeconds: appState.cornerDwellDelay,
            hideDelaySeconds: appState.settings.cornerHideDelaySeconds
        )
        super.init(rootView: rootView)
        sizingOptions = []
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @available(*, unavailable)
    required init(rootView: Content) {
        fatalError("init(rootView:) has not been implemented")
    }

    public override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }

    public override func hitTest(_ point: NSPoint) -> NSView? {
        guard appState.isEnabled && appState.isCornerDialsEnabled else {
            return nil
        }

        // Only accept hit testing when this specific dial is actively expanded
        guard appState.activeCorner == corner && appState.activeDisplayID == displayID else {
            return nil
        }

        let localPoint = superview != nil ? convert(point, from: superview) : point
        let vertex = localCornerVertex(in: bounds, corner: corner)
        let dist = hypot(localPoint.x - vertex.x, localPoint.y - vertex.y)
        let dialRadius = appState.settings.dialRadiusPoints

        if dist <= dialRadius + 20 {
            return super.hitTest(point)
        }

        return nil
    }

    public override func scrollWheel(with event: NSEvent) {
        guard appState.isEnabled,
              appState.isCornerDialsEnabled,
              appState.scrollAdjustmentEnabled else {
            super.scrollWheel(with: event)
            return
        }

        guard appState.activeCorner == corner && appState.activeDisplayID == displayID else {
            super.scrollWheel(with: event)
            return
        }

        ScreenManager.shared.keepDialActive()

        // Filter out momentum events to prevent values from runaway changes after lifting fingers
        if event.hasPreciseScrollingDeltas && !event.momentumPhase.isEmpty {
            return
        }

        let action = appState.action(for: corner)
        guard action != .none else {
            super.scrollWheel(with: event)
            return
        }

        if action == .timer && appState.isPomodoroRunning {
            return
        }

        if action == .mediaPlayback && (event.phase == .ended || event.phase == .cancelled) {
            NowPlayingManager.shared.commitInteractiveScrub()
            return
        }

        let rawDeltaX = event.hasPreciseScrollingDeltas ? event.scrollingDeltaX : (event.deltaX * 10.0)
        let rawDeltaY = event.hasPreciseScrollingDeltas ? event.scrollingDeltaY : (event.deltaY * 10.0)

        let vector = ScrollInputPolicy.normalize(
            rawDeltaX: Double(rawDeltaX),
            rawDeltaY: Double(rawDeltaY),
            isDirectionInvertedFromDevice: event.isDirectionInvertedFromDevice
        )

        guard vector.totalMotion > 0.001 else { return }

        if action == .mediaPlayback {
            let dur = NowPlayingManager.shared.duration
            let durFactor = dur > 0 ? max(0.35, min(2.5, dur / 240.0)) : 1.0
            let primaryStep = ScrollInputPolicy.dominantAxisStep(x: vector.x, y: vector.y)
            let deltaSeconds = primaryStep * 0.25 * durFactor
            NowPlayingManager.shared.updateInteractiveScrub(deltaSeconds: deltaSeconds)
            return
        }

        // Unified natural swipe physics across all 4 corner dials:
        // 0% is aligned at the bottom/lower perimeter, 100% rises to the top/upper edge.
        // Swiping fingers UP (+y) or RIGHT (+x) turns UP the value.
        // Swiping fingers DOWN (-y) or LEFT (-x) turns DOWN the value.
        let effectiveStep: Double = vector.y + vector.x

        let sensitivity: Double = 0.005
        let step = effectiveStep * sensitivity
        let current = appState.getValue(for: action, displayID: displayID)
        let newValue = max(0.0, min(1.0, current + step))

        if action == .timer {
            let mins = max(1, min(60, Int(round(newValue * 60.0))))
            let snapped = Double(mins) / 60.0
            appState.setValue(for: action, value: snapped, displayID: displayID)
        } else {
            appState.setValue(for: action, value: newValue, displayID: displayID)
        }

        if event.phase == .ended || event.phase == .cancelled {
            appState.saveSettings()
        }
    }

    public func reset(reason: ResetReason) {
        dwellTimer?.invalidate()
        dwellTimer = nil
        hideTimer?.invalidate()
        hideTimer = nil
        _ = stateMachine.handle(event: .reset(reason: reason))
    }

    private func localCornerVertex(in rect: NSRect, corner: CornerPosition) -> NSPoint {
        switch corner {
        case .topLeft:
            return NSPoint(x: rect.minX, y: rect.minY)
        case .topRight:
            return NSPoint(x: rect.maxX, y: rect.minY)
        case .bottomLeft:
            return NSPoint(x: rect.minX, y: rect.maxY)
        case .bottomRight:
            return NSPoint(x: rect.maxX, y: rect.maxY)
        }
    }
}
