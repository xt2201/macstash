import AppKit
import SwiftUI
import MacStashCore

/// Manages floating overlay panels (4 corners, left edge shelf, and right edge slider) for one specific display
@MainActor
public final class ScreenOverlayInstance {
    public let displayID: CGDirectDisplayID
    public private(set) var screen: NSScreen
    private let appState: AppState

    private var cornerPanels: [CornerPosition: NSPanel] = [:]
    private var passThroughViews: [CornerPosition: PassThroughHostingView<CornerDialView>] = [:]
    private var rightEdgePanel: MacStashInteractivePanel?
    private var edgeHostingView: EdgeSliderHostingView?
    private var leftEdgePanel: MacStashInteractivePanel?
    private var stashHostingView: StashShelfHostingView?

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

    public func setLeftEdgeInteractive(_ interactive: Bool, allowsKey: Bool = false) {
        guard let panel = leftEdgePanel else { return }
        panel.ignoresMouseEvents = !interactive
        panel.allowsKeyWindow = allowsKey

        if interactive {
            panel.orderFrontRegardless()
            if allowsKey {
                panel.makeKey()
            }
        } else {
            panel.allowsKeyWindow = false
            if NSApplication.shared.keyWindow === panel {
                panel.resignKey()
            }
        }
    }

    public func setRightEdgeInteractive(_ interactive: Bool) {
        guard let panel = rightEdgePanel else { return }
        panel.ignoresMouseEvents = !interactive
        if interactive {
            panel.orderFrontRegardless()
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

        createRightEdgePanelIfNeeded()
        createLeftEdgePanelIfNeeded()
    }

    private func createLeftEdgePanelIfNeeded() {
        if appState.settings.onlyOuterCorners {
            let allFrames = NSScreen.screens.map { $0.frame }
            guard CornerGeometry.isOuterLeftEdge(screen: screen.frame, in: allFrames) else { return }
        }

        let panel = makeEdgePanel(contentRect: leftEdgeRect(in: screen.frame))
        let hostingView = StashShelfHostingView(rootView: LeftEdgeContainerView(appState: appState), appState: appState)
        panel.contentView = hostingView
        panel.orderFrontRegardless()

        leftEdgePanel = panel
        stashHostingView = hostingView
    }

    public func leftEdgeRect(in frame: NSRect) -> NSRect {
        let panelWidth: CGFloat = 380
        let panelHeight: CGFloat = 500
        let panelY = frame.minY + (frame.height - panelHeight) / 2
        return NSRect(x: frame.minX, y: panelY, width: panelWidth, height: panelHeight)
    }

    private func createRightEdgePanelIfNeeded() {
        if appState.settings.onlyOuterCorners {
            let allFrames = NSScreen.screens.map { $0.frame }
            guard CornerGeometry.isOuterRightEdge(screen: screen.frame, in: allFrames) else {
                return
            }
        }

        let edgeFrame = rightEdgeRect(in: screen.frame)
        let panel = makeEdgePanel(contentRect: edgeFrame)
        let sliderView = EdgeSliderView(appState: appState, displayID: displayID, edge: .right)
        let hostingView = EdgeSliderHostingView(rootView: sliderView, appState: appState, displayID: displayID, edge: .right)

        panel.contentView = hostingView
        panel.orderFrontRegardless()

        self.rightEdgePanel = panel
        self.edgeHostingView = hostingView
    }

    public func rightEdgeRect(in frame: NSRect) -> NSRect {
        let panelWidth: CGFloat = 80
        let panelHeight: CGFloat = 460
        let panelY = frame.minY + (frame.height - panelHeight) / 2
        let panelX = frame.maxX - panelWidth
        return NSRect(x: panelX, y: panelY, width: panelWidth, height: panelHeight)
    }

    public func repositionPanels() {
        let frame = screen.frame

        for (corner, panel) in cornerPanels {
            let rect = cornerRect(for: corner, in: frame)
            panel.setFrame(rect, display: true)
        }

        if let edgePanel = rightEdgePanel {
            let shouldShow: Bool
            if appState.settings.onlyOuterCorners {
                let allFrames = NSScreen.screens.map { $0.frame }
                shouldShow = CornerGeometry.isOuterRightEdge(screen: screen.frame, in: allFrames)
            } else {
                shouldShow = true
            }

            if shouldShow {
                let rect = rightEdgeRect(in: frame)
                edgePanel.setFrame(rect, display: true)
                edgePanel.orderFrontRegardless()
            } else {
                edgePanel.orderOut(nil)
            }
        } else {
            createRightEdgePanelIfNeeded()
        }

        if let leftPanel = leftEdgePanel {
            let shouldShow: Bool
            if appState.settings.onlyOuterCorners {
                shouldShow = CornerGeometry.isOuterLeftEdge(screen: screen.frame, in: NSScreen.screens.map { $0.frame })
            } else {
                shouldShow = true
            }
            if shouldShow {
                leftPanel.setFrame(leftEdgeRect(in: frame), display: true)
                leftPanel.orderFrontRegardless()
            } else {
                leftPanel.orderOut(nil)
            }
        } else {
            createLeftEdgePanelIfNeeded()
        }
    }

    public func destroyPanels() {
        for (_, panel) in cornerPanels {
            panel.orderOut(nil)
            panel.close()
        }
        cornerPanels.removeAll()
        passThroughViews.removeAll()

        rightEdgePanel?.orderOut(nil)
        rightEdgePanel?.close()
        rightEdgePanel = nil
        edgeHostingView = nil

        leftEdgePanel?.orderOut(nil)
        leftEdgePanel?.close()
        leftEdgePanel = nil
        stashHostingView = nil
    }

    private func makeEdgePanel(contentRect: NSRect) -> MacStashInteractivePanel {
        let panel = MacStashInteractivePanel(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        // Default to passive (ignoring mouse events) so underlying macOS apps receive all clicks cleanly
        panel.ignoresMouseEvents = true
        return panel
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
