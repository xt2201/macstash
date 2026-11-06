import AppKit
import SwiftUI
import MacStashCore

/// Manages floating overlay panels (4 corners + left dock) for one specific display
@MainActor
public final class ScreenOverlayInstance {
    public let displayID: CGDirectDisplayID
    public private(set) var screen: NSScreen
    private let appState: AppState

    private var cornerPanels: [CornerPosition: NSPanel] = [:]
    private var passThroughViews: [CornerPosition: PassThroughHostingView<CornerDialView>] = [:]
    private var dockPanel: NSPanel?

    private var cornerSize: CGFloat {
        appState.settings.dialRadiusPoints + 15
    }
    private let dockWidth: CGFloat = 80
    private let dockHeight: CGFloat = 460

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
        cornerPanels[corner]?.ignoresMouseEvents = !interactive
    }

    public func setDockInteractive(_ interactive: Bool) {
        dockPanel?.ignoresMouseEvents = !interactive
    }

    private func createPanels() {
        let frame = screen.frame

        // 1. Create 4 Corner Panels with PassThroughHostingView
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

        // 2. Create Left Edge Hidden Dock
        let dockRect = NSRect(
            x: frame.minX,
            y: frame.midY - (dockHeight / 2),
            width: dockWidth,
            height: dockHeight
        )
        let dPanel = makeFloatingPanel(contentRect: dockRect)
        let dockView = HiddenDockView(appState: appState)
        dPanel.contentView = NSHostingView(rootView: dockView)
        dPanel.orderFrontRegardless()
        self.dockPanel = dPanel
    }

    public func repositionPanels() {
        let frame = screen.frame

        for (corner, panel) in cornerPanels {
            let rect = cornerRect(for: corner, in: frame)
            panel.setFrame(rect, display: true)
        }

        let dockRect = NSRect(
            x: frame.minX,
            y: frame.midY - (dockHeight / 2),
            width: dockWidth,
            height: dockHeight
        )
        dockPanel?.setFrame(dockRect, display: true)
    }

    public func destroyPanels() {
        for (_, panel) in cornerPanels {
            panel.orderOut(nil)
            panel.close()
        }
        cornerPanels.removeAll()
        passThroughViews.removeAll()

        dockPanel?.orderOut(nil)
        dockPanel?.close()
        dockPanel = nil
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
