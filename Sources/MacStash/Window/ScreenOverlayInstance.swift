import AppKit
import SwiftUI
import MacStashCore

/// Manages floating overlay panels (4 corners, left edge shelf/drawer, left edge slider, and right edge slider) for one specific display.
@MainActor
public final class ScreenOverlayInstance {
    public let displayID: CGDirectDisplayID
    public private(set) var screen: NSScreen
    private let appState: AppState

    private var cornerPanels: [CornerPosition: NSPanel] = [:]
    private var passThroughViews: [CornerPosition: PassThroughHostingView<CornerDialView>] = [:]

    private var rightSliderPanel: MacStashInteractivePanel?
    private var rightSliderHostingView: EdgeSliderHostingView?
    private let rightInteractionState = EdgeSliderInteractionState()

    private var leftSliderPanel: MacStashInteractivePanel?
    private var leftSliderHostingView: EdgeSliderHostingView?
    private let leftInteractionState = EdgeSliderInteractionState()

    private var leftEdgePanel: MacStashInteractivePanel?
    private var stashHostingView: StashShelfHostingView?

    // Backwards compatibility references
    public var rightEdgePanel: MacStashInteractivePanel? { rightSliderPanel }
    public var edgeHostingView: EdgeSliderHostingView? { rightSliderHostingView }

    private var cornerSize: CGFloat {
        appState.settings.dialRadiusPoints + Defaults.HotCorner.cornerWindowPaddingPoints
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
        setRightSliderInteractive(interactive)
    }

    public func setRightSliderInteractive(_ interactive: Bool) {
        if !interactive {
            rightInteractionState.reset()
        }
        guard let panel = rightSliderPanel else { return }
        panel.ignoresMouseEvents = !interactive
        if interactive {
            panel.orderFrontRegardless()
        }
    }

    public func setLeftSliderInteractive(_ interactive: Bool) {
        if !interactive {
            leftInteractionState.reset()
        }
        guard let panel = leftSliderPanel else { return }
        panel.ignoresMouseEvents = !interactive
        if interactive {
            panel.orderFrontRegardless()
        }
    }

    public func setEdgeInteractive(_ interactive: Bool, for edge: EdgePosition) {
        if edge == .left {
            setLeftSliderInteractive(interactive)
        } else {
            setRightSliderInteractive(interactive)
        }
    }

    /// Evaluates whether a global AppKit cursor point lies inside the currently visible active UI bounds
    /// (tight ~74pt Mode A strip vs expanded Mode B Dynamic Island + optional vertical volume bar).
    public func isPointInActiveSlider(_ point: NSPoint, for edge: EdgePosition) -> Bool {
        let state = (edge == .left) ? leftInteractionState : rightInteractionState
        let action = (edge == .left) ? appState.activeProfile.leftEdgeAction : appState.activeProfile.rightEdgeAction
        let showMedia = ((action == .volume && appState.settings.edgeBarShowMediaControls) || action == .mediaPlayback)
            && NowPlayingManager.shared.hasMedia
        let isVolumeActive = state.isVolumeColumnVisible || state.isVolumeButtonHovered || state.isVolumeColumnHovered
        let frame = screen.frame
        let sRect = sliderRect(for: edge, in: frame)
        return CornerGeometry.isPointInActiveEdgeSlider(
            point,
            screenFrame: frame,
            sliderPanelRect: sRect,
            edge: edge,
            isMediaExpanded: state.isMediaExpanded,
            hasMedia: showMedia,
            isVolumeColumnActive: isVolumeActive
        )
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

        createSliderPanelsIfNeeded()
        createDrawerPanelIfNeeded()
    }

    private func createDrawerPanelIfNeeded() {
        guard appState.hasDrawerFeatureActive else {
            leftEdgePanel?.orderOut(nil)
            return
        }

        let isRight = appState.settings.drawerEdgePosition == .right
        if appState.settings.onlyOuterCorners {
            let allFrames = NSScreen.screens.map { $0.frame }
            if isRight {
                guard CornerGeometry.isOuterRightEdge(screen: screen.frame, in: allFrames) else { return }
            } else {
                guard CornerGeometry.isOuterLeftEdge(screen: screen.frame, in: allFrames) else { return }
            }
        }

        let panel = makeEdgePanel(contentRect: drawerRect(in: screen.frame))
        let hostingView = StashShelfHostingView(rootView: LeftEdgeContainerView(appState: appState), appState: appState)
        panel.contentView = hostingView
        panel.orderFrontRegardless()

        leftEdgePanel = panel
        stashHostingView = hostingView
    }

    public func drawerRect(in frame: NSRect) -> NSRect {
        let isRight = appState.settings.drawerEdgePosition == .right
        let panelWidth: CGFloat = Defaults.LeftEdgeDrawer.panelWidthPoints
        let panelHeight: CGFloat = Defaults.LeftEdgeDrawer.panelHeightPoints
        let panelY = frame.minY + (frame.height - panelHeight) / 2.0
        let panelX = isRight ? (frame.maxX - panelWidth) : frame.minX
        return NSRect(x: panelX, y: panelY, width: panelWidth, height: panelHeight)
    }

    public func leftEdgeRect(in frame: NSRect) -> NSRect {
        drawerRect(in: frame)
    }

    private func createSliderPanelsIfNeeded() {
        guard appState.settings.isEdgeSlidersEnabled else {
            rightSliderPanel?.orderOut(nil)
            leftSliderPanel?.orderOut(nil)
            return
        }

        let placement = appState.settings.edgeSliderPlacement
        let allFrames = NSScreen.screens.map { $0.frame }

        // Right Edge Slider
        let rightAllowed = (placement == .both || placement == .right) && appState.activeProfile.rightEdgeAction != .none
        let rightOuter = !appState.settings.onlyOuterCorners || CornerGeometry.isOuterRightEdge(screen: screen.frame, in: allFrames)
        if rightAllowed && rightOuter {
            let edgeFrame = sliderRect(for: .right, in: screen.frame)
            let panel = makeEdgePanel(contentRect: edgeFrame)
            let sliderView = EdgeSliderView(appState: appState, edge: .right, displayID: displayID, interactionState: rightInteractionState)
            let hostingView = EdgeSliderHostingView(rootView: sliderView, appState: appState, displayID: displayID, interactionState: rightInteractionState)

            panel.contentView = hostingView
            panel.orderFrontRegardless()

            self.rightSliderPanel = panel
            self.rightSliderHostingView = hostingView
        } else {
            rightSliderPanel?.orderOut(nil)
        }

        // Left Edge Slider
        let leftAllowed = (placement == .both || placement == .left) && appState.activeProfile.leftEdgeAction != .none
        let leftOuter = !appState.settings.onlyOuterCorners || CornerGeometry.isOuterLeftEdge(screen: screen.frame, in: allFrames)
        if leftAllowed && leftOuter {
            let edgeFrame = sliderRect(for: .left, in: screen.frame)
            let panel = makeEdgePanel(contentRect: edgeFrame)
            let sliderView = EdgeSliderView(appState: appState, edge: .left, displayID: displayID, interactionState: leftInteractionState)
            let hostingView = EdgeSliderHostingView(rootView: sliderView, appState: appState, displayID: displayID, interactionState: leftInteractionState)

            panel.contentView = hostingView
            panel.orderFrontRegardless()

            self.leftSliderPanel = panel
            self.leftSliderHostingView = hostingView
        } else {
            leftSliderPanel?.orderOut(nil)
        }
    }

    public func sliderRect(for edge: EdgePosition, in frame: NSRect) -> NSRect {
        let isLeft = edge == .left
        let panelWidth = Defaults.EdgeSliders.panelWidthPoints
        let panelHeight = Defaults.EdgeSliders.panelHeightPoints
        let panelY = frame.minY + (frame.height - panelHeight) / 2.0
        let panelX = isLeft ? frame.minX : (frame.maxX - panelWidth)
        return NSRect(x: panelX, y: panelY, width: panelWidth, height: panelHeight)
    }

    public func sliderRect(in frame: NSRect) -> NSRect {
        sliderRect(for: .right, in: frame)
    }

    public func rightEdgeRect(in frame: NSRect) -> NSRect {
        sliderRect(for: .right, in: frame)
    }

    public func repositionPanels() {
        let frame = screen.frame

        for (corner, panel) in cornerPanels {
            let rect = cornerRect(for: corner, in: frame)
            panel.setFrame(rect, display: true)
            if let existingView = passThroughViews[corner], existingView.screenFrame != frame {
                let updatedView = PassThroughHostingView(
                    rootView: CornerDialView(appState: appState, corner: corner, displayID: displayID),
                    corner: corner,
                    displayID: displayID,
                    screenFrame: frame,
                    appState: appState
                )
                panel.contentView = updatedView
                passThroughViews[corner] = updatedView
            }
        }

        if appState.settings.isEdgeSlidersEnabled {
            let placement = appState.settings.edgeSliderPlacement
            let allFrames = NSScreen.screens.map { $0.frame }

            // Right Slider
            if let rightPanel = rightSliderPanel {
                let rightAllowed = (placement == .both || placement == .right) && appState.activeProfile.rightEdgeAction != .none
                let shouldShow = rightAllowed && (!appState.settings.onlyOuterCorners || CornerGeometry.isOuterRightEdge(screen: frame, in: allFrames))
                if shouldShow {
                    let rect = sliderRect(for: .right, in: frame)
                    rightPanel.setFrame(rect, display: true)
                    rightPanel.orderFrontRegardless()
                } else {
                    rightPanel.orderOut(nil)
                }
            } else {
                createSliderPanelsIfNeeded()
            }

            // Left Slider
            if let leftPanel = leftSliderPanel {
                let leftAllowed = (placement == .both || placement == .left) && appState.activeProfile.leftEdgeAction != .none
                let shouldShow = leftAllowed && (!appState.settings.onlyOuterCorners || CornerGeometry.isOuterLeftEdge(screen: frame, in: allFrames))
                if shouldShow {
                    let rect = sliderRect(for: .left, in: frame)
                    leftPanel.setFrame(rect, display: true)
                    leftPanel.orderFrontRegardless()
                } else {
                    leftPanel.orderOut(nil)
                }
            } else {
                createSliderPanelsIfNeeded()
            }
        } else {
            rightSliderPanel?.orderOut(nil)
            leftSliderPanel?.orderOut(nil)
        }

        if appState.hasDrawerFeatureActive {
            if let leftPanel = leftEdgePanel {
                let isRight = appState.settings.drawerEdgePosition == .right
                let shouldShow: Bool
                if appState.settings.onlyOuterCorners {
                    let allFrames = NSScreen.screens.map { $0.frame }
                    shouldShow = isRight
                        ? CornerGeometry.isOuterRightEdge(screen: screen.frame, in: allFrames)
                        : CornerGeometry.isOuterLeftEdge(screen: screen.frame, in: allFrames)
                } else {
                    shouldShow = true
                }
                if shouldShow {
                    leftPanel.setFrame(drawerRect(in: frame), display: true)
                    leftPanel.orderFrontRegardless()
                } else {
                    leftPanel.orderOut(nil)
                }
            } else {
                createDrawerPanelIfNeeded()
            }
        } else {
            leftEdgePanel?.orderOut(nil)
        }
    }

    public func destroyPanels() {
        for (_, panel) in cornerPanels {
            panel.orderOut(nil)
            panel.close()
        }
        cornerPanels.removeAll()
        passThroughViews.removeAll()

        rightSliderPanel?.orderOut(nil)
        rightSliderPanel?.close()
        rightSliderPanel = nil
        rightSliderHostingView = nil

        leftSliderPanel?.orderOut(nil)
        leftSliderPanel?.close()
        leftSliderPanel = nil
        leftSliderHostingView = nil

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
        return panel
    }
}
