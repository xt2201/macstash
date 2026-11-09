import AppKit
import SideDockCore

public final class EdgeTriggerManager: @unchecked Sendable {
    private var globalMonitor: Any?
    private var revealTimer: Timer?
    private var hideTimer: Timer?
    private var isCurrentlyRevealed: Bool = false
    private let onStateChanged: (Bool) -> Void

    public init(onStateChanged: @escaping (Bool) -> Void) {
        self.onStateChanged = onStateChanged
    }

    deinit {
        stop()
    }

    public func start(
        placement: DockPlacement,
        triggerThickness: Double,
        revealDelaySeconds: Double,
        dockFrame: CGRect
    ) {
        stop()

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { [weak self] event in
            guard let self = self else { return }
            self.handleMouseMove(
                location: event.locationInWindow,
                placement: placement,
                triggerThickness: triggerThickness,
                revealDelaySeconds: revealDelaySeconds,
                dockFrame: dockFrame
            )
        }
    }

    public func stop() {
        if let mon = globalMonitor {
            NSEvent.removeMonitor(mon)
            globalMonitor = nil
        }
        revealTimer?.invalidate()
        revealTimer = nil
        hideTimer?.invalidate()
        hideTimer = nil
    }

    private func handleMouseMove(
        location: CGPoint,
        placement: DockPlacement,
        triggerThickness: Double,
        revealDelaySeconds: Double,
        dockFrame: CGRect
    ) {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.frame
        let engine = DockLayoutEngine()

        let insideTrigger = engine.isInsideEdgeTrigger(
            cursorLocation: location,
            screenFrame: screenFrame,
            placement: placement,
            triggerThickness: triggerThickness
        )

        let insideDock = dockFrame.insetBy(dx: -10, dy: -10).contains(location)

        if insideTrigger || insideDock {
            hideTimer?.invalidate()
            hideTimer = nil

            if !isCurrentlyRevealed && revealTimer == nil {
                if revealDelaySeconds <= 0.05 {
                    self.isCurrentlyRevealed = true
                    self.onStateChanged(true)
                } else {
                    revealTimer = Timer.scheduledTimer(withTimeInterval: revealDelaySeconds, repeats: false) { [weak self] _ in
                        guard let self = self else { return }
                        self.isCurrentlyRevealed = true
                        self.onStateChanged(true)
                        self.revealTimer = nil
                    }
                }
            }
        } else {
            revealTimer?.invalidate()
            revealTimer = nil

            if isCurrentlyRevealed && hideTimer == nil {
                hideTimer = Timer.scheduledTimer(withTimeInterval: 0.35, repeats: false) { [weak self] _ in
                    guard let self = self else { return }
                    self.isCurrentlyRevealed = false
                    self.onStateChanged(false)
                    self.hideTimer = nil
                }
            }
        }
    }
}
