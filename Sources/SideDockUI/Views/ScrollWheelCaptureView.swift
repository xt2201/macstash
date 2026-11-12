import SwiftUI
import AppKit

/// Captures vertical/horizontal scroll wheel events over a SwiftUI view without stealing clicks.
public struct ScrollWheelCaptureView: NSViewRepresentable {
    public let onScrollSteps: @MainActor (Int) -> Void

    public init(onScrollSteps: @escaping @MainActor (Int) -> Void) {
        self.onScrollSteps = onScrollSteps
    }

    public func makeNSView(context: Context) -> ScrollCaptureNSView {
        let view = ScrollCaptureNSView()
        view.onScrollSteps = onScrollSteps
        return view
    }

    public func updateNSView(_ nsView: ScrollCaptureNSView, context: Context) {
        nsView.onScrollSteps = onScrollSteps
    }

    public final class ScrollCaptureNSView: NSView {
        var onScrollSteps: (@MainActor (Int) -> Void)?
        private var accumulatedDelta: CGFloat = 0
        private var lastFireTime: TimeInterval = 0

        public override func hitTest(_ point: NSPoint) -> NSView? {
            return nil
        }

        public override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            installMonitorIfNeeded()
        }

        private nonisolated(unsafe) var monitor: Any?

        deinit {
            if let monitor {
                NSEvent.removeMonitor(monitor)
            }
        }

        private func installMonitorIfNeeded() {
            guard monitor == nil else { return }
            monitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
                guard let self, let win = self.window, event.window === win else { return event }
                let locInView = self.convert(event.locationInWindow, from: nil)
                guard self.bounds.contains(locInView) else { return event }

                let delta = abs(event.scrollingDeltaY) >= abs(event.scrollingDeltaX)
                    ? event.scrollingDeltaY
                    : event.scrollingDeltaX
                self.accumulatedDelta += delta

                let threshold: CGFloat = event.hasPreciseScrollingDeltas ? 24.0 : 0.5
                let now = ProcessInfo.processInfo.systemUptime
                if abs(self.accumulatedDelta) >= threshold && (now - self.lastFireTime) > 0.16 {
                    let step = self.accumulatedDelta > 0 ? -1 : 1
                    self.accumulatedDelta = 0
                    self.lastFireTime = now
                    Task { @MainActor in
                        self.onScrollSteps?(step)
                    }
                    return nil
                }
                return event
            }
        }
    }
}
