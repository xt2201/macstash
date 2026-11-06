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
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @available(*, unavailable)
    required init(rootView: Content) {
        fatalError("init(rootView:) has not been implemented")
    }

    public override func hitTest(_ point: NSPoint) -> NSView? {
        guard appState.isEnabled && appState.isCornerDialsEnabled else {
            return nil
        }

        // 1. Mouse Dragging / Pressed Suppression
        if appState.settings.suppressWhenMousePressed && NSEvent.pressedMouseButtons != 0 {
            return nil
        }

        // 2. Fullscreen Application Suppression
        if appState.settings.suppressInFullscreen {
            if NSApplication.shared.presentationOptions.contains(.fullScreen) {
                return nil
            }
        }

        // 3. Excluded Bundle IDs Suppression
        if let currentBundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier {
            if appState.settings.excludedBundleIDs.contains(currentBundleID) {
                return nil
            }
        }

        // 4. Multi-Monitor Geometric Outer Corner Verification
        let allScreenFrames = NSScreen.screens.map { $0.frame }
        guard CornerGeometry.isOuterCorner(corner: corner, of: screenFrame, in: allScreenFrames) else {
            return nil
        }

        let vertex = localCornerVertex(in: bounds, corner: corner)
        let dist = hypot(point.x - vertex.x, point.y - vertex.y)
        let sensitivity = appState.cornerSensitivityRadius
        let dialRadius = appState.settings.dialRadiusPoints

        if stateMachine.currentState.isVisibleOrPending {
            if dist <= dialRadius {
                let effect = stateMachine.handle(event: .mouseMovedInsideDial)
                apply(effect: effect)
                return super.hitTest(point)
            } else {
                let effect = stateMachine.handle(event: .mouseExitedDialZone)
                apply(effect: effect)
                return nil
            }
        } else {
            // Dial is currently hidden; check if mouse is within extreme hot zone
            if dist <= sensitivity {
                let effect = stateMachine.handle(event: .mouseEnteredHotZone(corner: corner, displayID: displayID))
                apply(effect: effect)
            }
            // Pass-through clicks to apps beneath when dial is not visible
            return nil
        }
    }

    public func reset(reason: ResetReason) {
        let effect = stateMachine.handle(event: .reset(reason: reason))
        apply(effect: effect)
    }

    private func apply(effect: TransitionEffect) {
        for action in effect.actions {
            switch action {
            case .scheduleDwellTimer(let gen, let delay):
                dwellTimer?.invalidate()
                if delay <= 0 {
                    let next = stateMachine.handle(event: .dwellTimerFired(generation: gen))
                    apply(effect: next)
                } else {
                    dwellTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
                        Task { @MainActor [weak self] in
                            guard let self = self else { return }
                            let next = self.stateMachine.handle(event: .dwellTimerFired(generation: gen))
                            self.apply(effect: next)
                        }
                    }
                    if let t = dwellTimer {
                        RunLoop.main.add(t, forMode: .common)
                    }
                }

            case .cancelDwellTimer:
                dwellTimer?.invalidate()
                dwellTimer = nil

            case .showDial(_, let c, let d):
                appState.activeCorner = c
                appState.activeDisplayID = d
                AppLogger.hotcorner.debug("Showing dial at \(c.rawValue) on display \(d)")

            case .scheduleHideTimer(let gen, let delay):
                hideTimer?.invalidate()
                hideTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
                    Task { @MainActor [weak self] in
                        guard let self = self else { return }
                        let next = self.stateMachine.handle(event: .hideTimerFired(generation: gen))
                        self.apply(effect: next)
                    }
                }
                if let t = hideTimer {
                    RunLoop.main.add(t, forMode: .common)
                }

            case .cancelHideTimer:
                hideTimer?.invalidate()
                hideTimer = nil

            case .hideDial(_, let c, let d):
                if appState.activeCorner == c && appState.activeDisplayID == d {
                    appState.activeCorner = nil
                    appState.activeDisplayID = 0
                }
                AppLogger.hotcorner.debug("Hiding dial at \(c.rawValue) on display \(d)")
            }
        }
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
