import AppKit
import SwiftUI

/// Renders a subtle glowing outline around an on-screen window when hovered in previews or Window Switcher.
@MainActor
public final class WindowHighlightOverlay {
    public static let shared = WindowHighlightOverlay()
    private var panel: NSPanel?

    public init() {}

    public func highlight(cgWindowFrame: CGRect) {
        guard cgWindowFrame.width > 10, cgWindowFrame.height > 10,
              let primaryScreen = NSScreen.screens.first else {
            hide()
            return
        }

        // Convert CGWindow top-left coordinates to AppKit bottom-left screen coordinates
        let appKitY = primaryScreen.frame.maxY - cgWindowFrame.maxY
        let targetRect = CGRect(x: cgWindowFrame.origin.x, y: appKitY, width: cgWindowFrame.width, height: cgWindowFrame.height)

        if panel == nil {
            let p = NSPanel(
                contentRect: targetRect,
                styleMask: [.nonactivatingPanel, .borderless],
                backing: .buffered,
                defer: false
            )
            p.isOpaque = false
            p.backgroundColor = .clear
            p.hasShadow = false
            p.ignoresMouseEvents = true
            p.level = .floating
            p.collectionBehavior = [.canJoinAllSpaces, .transient, .ignoresCycle, .fullScreenAuxiliary]
            p.contentView = NSHostingView(rootView: HighlightBorderView())
            panel = p
        }

        panel?.setFrame(targetRect, display: true)
        panel?.orderFrontRegardless()
    }

    public func hide() {
        panel?.orderOut(nil)
    }
}

private struct HighlightBorderView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color.accentColor.opacity(0.08))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.accentColor.opacity(0.85), lineWidth: 3)
            )
    }
}
