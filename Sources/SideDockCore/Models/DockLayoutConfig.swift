import Foundation

public enum DockPlacement: String, Codable, Sendable, CaseIterable {
    case floating
    case fixedBottom
    case fixedTop
    case fixedLeft
    case fixedRight

    public var isVertical: Bool {
        self == .fixedLeft || self == .fixedRight
    }
}

public struct DockLayoutConfig: Codable, Equatable, Sendable {
    public var placement: DockPlacement
    public var scale: Double
    public var tileSpacing: Double
    public var bottomOffset: Double
    public var autoHide: Bool
    public var revealDelaySeconds: Double
    public var edgeTriggerThickness: Double
    public var floatingX: Double
    public var floatingY: Double
    public var reserveDockSpace: Bool
    public var hideInFullscreen: Bool
    public var hideOnWindowHover: Bool
    public var maxDockWidth: Double?
    public var autoFitScreen: Bool
    public var showProfileSwitcher: Bool
    public var showRunningApps: Bool

    public init(
        placement: DockPlacement = .fixedBottom,
        scale: Double = 1.0,
        tileSpacing: Double = 10.0,
        bottomOffset: Double = 8.0,
        autoHide: Bool = false,
        revealDelaySeconds: Double = 0.2,
        edgeTriggerThickness: Double = 8.0,
        floatingX: Double = 200.0,
        floatingY: Double = 100.0,
        reserveDockSpace: Bool = false,
        hideInFullscreen: Bool = false,
        hideOnWindowHover: Bool = false,
        maxDockWidth: Double? = nil,
        autoFitScreen: Bool = true,
        showProfileSwitcher: Bool = true,
        showRunningApps: Bool = true
    ) {
        self.placement = placement
        self.scale = max(0.6, min(1.6, scale))
        self.tileSpacing = max(2.0, min(30.0, tileSpacing))
        self.bottomOffset = max(0.0, min(80.0, bottomOffset))
        self.autoHide = autoHide
        self.revealDelaySeconds = max(0.0, min(3.0, revealDelaySeconds))
        self.edgeTriggerThickness = max(2.0, min(20.0, edgeTriggerThickness))
        self.floatingX = floatingX
        self.floatingY = floatingY
        self.reserveDockSpace = reserveDockSpace
        self.hideInFullscreen = hideInFullscreen
        self.hideOnWindowHover = hideOnWindowHover
        self.maxDockWidth = maxDockWidth
        self.autoFitScreen = autoFitScreen
        self.showProfileSwitcher = showProfileSwitcher
        self.showRunningApps = showRunningApps
    }
}
