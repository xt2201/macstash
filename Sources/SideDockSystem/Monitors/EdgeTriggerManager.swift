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
        dockFrame: CGRect,
        autoHide: Bool = true,
        hideInFullscreen: Bool = false,
        hideOnWindowHover: Bool = false,
        initiallyRevealed: Bool = false,
        onHoverAlphaChanged: (@Sendable (CGFloat) -> Void)? = nil
    ) {
        stop()
        isCurrentlyRevealed = initiallyRevealed

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { [weak self] _ in
            guard let self = self else { return }
            let screenMouseLocation = NSEvent.mouseLocation
            self.handleMouseMove(
                location: screenMouseLocation,
                placement: placement,
                triggerThickness: triggerThickness,
                revealDelaySeconds: revealDelaySeconds,
                dockFrame: dockFrame,
                autoHide: autoHide,
                hideInFullscreen: hideInFullscreen,
                hideOnWindowHover: hideOnWindowHover,
                onHoverAlphaChanged: onHoverAlphaChanged
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
        dockFrame: CGRect,
        autoHide: Bool,
        hideInFullscreen: Bool,
        hideOnWindowHover: Bool,
        onHoverAlphaChanged: (@Sendable (CGFloat) -> Void)?
    ) {
        let screen = NSScreen.screens.first(where: { $0.frame.contains(location) }) ?? NSScreen.main
        guard let targetScreen = screen else { return }
        let screenFrame = targetScreen.frame
        let engine = DockLayoutEngine()

        let insideTrigger = engine.isInsideEdgeTrigger(
            cursorLocation: location,
            screenFrame: screenFrame,
            placement: placement,
            triggerThickness: triggerThickness
        )

        let insideDock = dockFrame.insetBy(dx: -10, dy: -10).contains(location)

        if hideOnWindowHover {
            if insideDock {
                onHoverAlphaChanged?(0.15)
            } else {
                onHoverAlphaChanged?(1.0)
            }
        }

        var isFullscreen = false
        if hideInFullscreen {
            if let frontApp = NSWorkspace.shared.frontmostApplication,
               frontApp.bundleIdentifier != Bundle.main.bundleIdentifier {
                let appRef = AXUIElementCreateApplication(frontApp.processIdentifier)
                var focusedWindow: CFTypeRef?
                if AXUIElementCopyAttributeValue(appRef, kAXFocusedWindowAttribute as CFString, &focusedWindow) == .success,
                   let win = focusedWindow {
                    var sizeVal: CFTypeRef?
                    // swiftlint:disable:next force_cast
                    if AXUIElementCopyAttributeValue(win as! AXUIElement, kAXSizeAttribute as CFString, &sizeVal) == .success,
                       let sVal = sizeVal {
                        var size = CGSize.zero
                        // swiftlint:disable:next force_cast
                        if AXValueGetValue(sVal as! AXValue, .cgSize, &size) {
                            if size.width >= screenFrame.width && size.height >= screenFrame.height {
                                isFullscreen = true
                            }
                        }
                    }
                }
            }
        }

        let shouldHideWhenIdle = autoHide || (hideInFullscreen && isFullscreen)

        if !shouldHideWhenIdle || insideTrigger || (insideDock && (!hideInFullscreen || !isFullscreen)) {
            hideTimer?.invalidate()
            hideTimer = nil

            if !isCurrentlyRevealed && revealTimer == nil {
                let effectiveDelay = isFullscreen ? max(1.0, revealDelaySeconds) : revealDelaySeconds
                if !shouldHideWhenIdle || effectiveDelay <= 0.05 {
                    self.isCurrentlyRevealed = true
                    self.onStateChanged(true)
                } else {
                    revealTimer = Timer.scheduledTimer(withTimeInterval: effectiveDelay, repeats: false) { [weak self] _ in
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
                let effectiveHideDelay = isFullscreen ? 1.0 : 0.35
                hideTimer = Timer.scheduledTimer(withTimeInterval: effectiveHideDelay, repeats: false) { [weak self] _ in
                    guard let self = self else { return }
                    self.isCurrentlyRevealed = false
                    self.onStateChanged(false)
                    self.hideTimer = nil
                }
            }
        }
    }
}
