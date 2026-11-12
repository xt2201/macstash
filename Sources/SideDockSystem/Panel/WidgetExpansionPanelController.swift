import AppKit
import SwiftUI
import SideDockCore
import SideDockWidgets

@MainActor
public final class WidgetExpansionPanelController {
    private var panel: KeyablePopoverPanel?
    private var outsideClickMonitor: Any?
    private let layoutEngine = DockLayoutEngine()

    public init() {}

    public func show(
        widget: WidgetItem,
        anchorScreenRect: CGRect,
        placement: DockPlacement,
        screenVisibleFrame: CGRect
    ) {
        dismiss()

        let content = WidgetRegistry.shared.makeExpandedView(for: widget)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThickMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.16), lineWidth: 0.8)
            )
            .shadow(color: Color.black.opacity(0.25), radius: 18, y: 8)
            .padding(12)

        let host = NSHostingView(rootView: content)
        host.layoutSubtreeIfNeeded()
        let size = host.fittingSize

        let origin = layoutEngine.calculateAnchoredPopoverOrigin(
            anchorRect: anchorScreenRect,
            popoverSize: size,
            placement: placement,
            visibleFrame: screenVisibleFrame,
            gap: 8.0
        )

        let p = KeyablePopoverPanel(
            contentRect: CGRect(origin: origin, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        p.isOpaque = false
        p.backgroundColor = .clear
        p.hasShadow = false
        p.level = .popUpMenu
        p.collectionBehavior = [.canJoinAllSpaces, .transient, .fullScreenAuxiliary]
        p.contentView = host
        p.onEscape = { [weak self] in
            self?.dismiss()
        }
        p.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: false)

        self.panel = p
        installOutsideClickMonitor()
    }

    public func dismiss() {
        if let mon = outsideClickMonitor {
            NSEvent.removeMonitor(mon)
            outsideClickMonitor = nil
        }
        panel?.orderOut(nil)
        panel = nil
    }

    private func installOutsideClickMonitor() {
        outsideClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            Task { @MainActor in
                self?.dismiss()
            }
        }
    }
}

private final class KeyablePopoverPanel: NSPanel {
    var onEscape: (() -> Void)?

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    override func cancelOperation(_ sender: Any?) {
        onEscape?()
    }
}
