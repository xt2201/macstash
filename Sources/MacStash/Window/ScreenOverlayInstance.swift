import AppKit
import SwiftUI
import MacStashCore

/// Manages floating overlay panels (4 corners) for one specific display
@MainActor
public final class ScreenOverlayInstance {
    public let displayID: CGDirectDisplayID
    public private(set) var screen: NSScreen
    private let appState: AppState

    private var cornerPanels: [CornerPosition: NSPanel] = [:]
    private var passThroughViews: [CornerPosition: PassThroughHostingView<CornerDialView>] = [:]

    private var cornerSize: CGFloat {
        appState.settings.dialRadiusPoints + 15
    }

    public init(displayID: CGDirectDisplayID, screen: NSScreen, appState: AppState) {
        self.displayID = displayID
        self.screen = screen
        self.appState = appState

        createPanels()
    }

    deinit {
        // NSPanels cleaned up on main actor
    }

    public func updateScreen(_ newScreen: NSScreen) {
        self.screen = newScreen
        repositionPanels()
    }

    public func resetAllCorners(reason: ResetReason) {
        for (corner, view) in passThroughViews {
            view.reset(reason: reason)
            setMouseInteractive(false, for: corner)
        }
    }

    public func setMouseInteractive(_ interactive: Bool, for corner: CornerPosition) {
        if let panel = cornerPanels[corner] {
            panel.ignoresMouseEvents = !interactive
            if interactive {
                panel.orderFrontRegardless()
            }
        }
    }

    private func createPanels() {
        let frame = screen.frame

        // Create 4 Corner Panels with PassThroughHostingView
        for corner in CornerPosition.allCases {
            let panelRect = cornerRect(for: corner, in: frame)
            let panel = makeFloatingPanel(contentRect: panelRect)

            let dialView = CornerDialView(appState: appState, corner: corner, displayID: displayID)
            let hostingView = PassThroughHostingView(
                rootView: dialView,
                corner: corner,
                displayID: displayID,
                screenFrame: frame,
                appState: appState
            )

            panel.contentView = hostingView
            panel.orderFrontRegardless()

            cornerPanels[corner] = panel
            passThroughViews[corner] = hostingView
        }
    }

    public func repositionPanels() {
        let frame = screen.frame

        for (corner, panel) in cornerPanels {
            let rect = cornerRect(for: corner, in: frame)
            panel.setFrame(rect, display: true)
        }
    }

    public func destroyPanels() {
        for (_, panel) in cornerPanels {
            panel.orderOut(nil)
            panel.close()
        }
        cornerPanels.removeAll()
        passThroughViews.removeAll()
    }

    private func cornerRect(for corner: CornerPosition, in frame: NSRect) -> NSRect {
        switch corner {
        case .bottomLeft:
            return NSRect(x: frame.minX, y: frame.minY, width: cornerSize, height: cornerSize)
        case .bottomRight:
            return NSRect(x: frame.maxX - cornerSize, y: frame.minY, width: cornerSize, height: cornerSize)
        case .topLeft:
            return NSRect(x: frame.minX, y: frame.maxY - cornerSize, width: cornerSize, height: cornerSize)
        case .topRight:
            return NSRect(x: frame.maxX - cornerSize, y: frame.maxY - cornerSize, width: cornerSize, height: cornerSize)
        }
    }

    private func makeFloatingPanel(contentRect: NSRect) -> NSPanel {
        let panel = NSPanel(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.acceptsMouseMovedEvents = true
        panel.ignoresMouseEvents = true
        panel.isMovable = false
        panel.isMovableByWindowBackground = false
        return panel
    }
}
