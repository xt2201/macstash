import AppKit
import SwiftUI
import SideDockCore

@MainActor
public final class DockTooltipPanelController {
    private var panel: NSPanel?
    private var hostingView: NSHostingView<DockTooltipPillView>?
    private var pendingHideWorkItem: DispatchWorkItem?
    private let layoutEngine = DockLayoutEngine()

    public init() {}

    public func show(text: String, anchorScreenRect: CGRect, placement: DockPlacement, screenVisibleFrame: CGRect) {
        pendingHideWorkItem?.cancel()
        pendingHideWorkItem = nil

        guard !text.isEmpty, anchorScreenRect != .zero else {
            hide()
            return
        }

        if panel == nil {
            let p = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 140, height: 28),
                styleMask: [.nonactivatingPanel, .borderless],
                backing: .buffered,
                defer: false
            )
            p.isOpaque = false
            p.backgroundColor = .clear
            p.hasShadow = true
            p.level = .statusBar
            p.ignoresMouseEvents = true
            p.collectionBehavior = [.canJoinAllSpaces, .transient, .ignoresCycle, .fullScreenAuxiliary]

            let host = NSHostingView(rootView: DockTooltipPillView(text: text))
            p.contentView = host
            self.panel = p
            self.hostingView = host
        } else {
            hostingView?.rootView = DockTooltipPillView(text: text)
        }

        guard let panel, let hostingView else { return }
        hostingView.layoutSubtreeIfNeeded()
        let size = hostingView.fittingSize
        let origin = layoutEngine.calculateAnchoredPopoverOrigin(
            anchorRect: anchorScreenRect,
            popoverSize: size,
            placement: placement,
            visibleFrame: screenVisibleFrame,
            gap: 10.0
        )

        panel.setFrame(CGRect(origin: origin, size: size), display: true)
        panel.orderFrontRegardless()
    }

    public func hide() {
        pendingHideWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.panel?.orderOut(nil)
        }
        pendingHideWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06, execute: work)
    }
}

private struct DockTooltipPillView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 11.5, weight: .semibold))
            .foregroundColor(.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule(style: .continuous)
                    .fill(.ultraThickMaterial)
            )
            .overlay(
                Capsule(style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.16), lineWidth: 0.7)
            )
            .fixedSize()
    }
}
