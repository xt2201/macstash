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
    public var baseTileSize: Double
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

    // Docky-parity physics, previews, badges, and behavior flags
    public var magnificationEnabled: Bool
    public var magnificationScale: Double
    public var showTooltips: Bool
    public var showNotificationBadges: Bool
    public var showWindowPreviewsOnHover: Bool
    public var windowPreviewHoverDelaySeconds: Double
    public var showMinimizedWindows: Bool
    public var bounceOnLaunch: Bool
    public var dockSoundFeedback: Bool
    public var coordinateNativeDockAutoHide: Bool
    public var hiddenRunningBundleIDs: [String]

    public init(
        placement: DockPlacement = .fixedBottom,
        scale: Double = 1.0,
        baseTileSize: Double = 46.0,
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
        showRunningApps: Bool = true,
        magnificationEnabled: Bool = true,
        magnificationScale: Double = 1.45,
        showTooltips: Bool = true,
        showNotificationBadges: Bool = true,
        showWindowPreviewsOnHover: Bool = true,
        windowPreviewHoverDelaySeconds: Double = 0.35,
        showMinimizedWindows: Bool = true,
        bounceOnLaunch: Bool = true,
        dockSoundFeedback: Bool = false,
        coordinateNativeDockAutoHide: Bool = false,
        hiddenRunningBundleIDs: [String] = []
    ) {
        self.placement = placement
        self.scale = max(0.6, min(1.6, scale))
        self.baseTileSize = max(36.0, min(68.0, baseTileSize))
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
        self.magnificationEnabled = magnificationEnabled
        self.magnificationScale = max(1.0, min(2.0, magnificationScale))
        self.showTooltips = showTooltips
        self.showNotificationBadges = showNotificationBadges
        self.showWindowPreviewsOnHover = showWindowPreviewsOnHover
        self.windowPreviewHoverDelaySeconds = max(0.1, min(1.5, windowPreviewHoverDelaySeconds))
        self.showMinimizedWindows = showMinimizedWindows
        self.bounceOnLaunch = bounceOnLaunch
        self.dockSoundFeedback = dockSoundFeedback
        self.coordinateNativeDockAutoHide = coordinateNativeDockAutoHide
        self.hiddenRunningBundleIDs = hiddenRunningBundleIDs
    }

    private enum CodingKeys: String, CodingKey {
        case placement, scale, baseTileSize, tileSpacing, bottomOffset, autoHide
        case revealDelaySeconds, edgeTriggerThickness, floatingX, floatingY
        case reserveDockSpace, hideInFullscreen, hideOnWindowHover, maxDockWidth
        case autoFitScreen, showProfileSwitcher, showRunningApps
        case magnificationEnabled, magnificationScale, showTooltips, showNotificationBadges
        case showWindowPreviewsOnHover, windowPreviewHoverDelaySeconds, showMinimizedWindows
        case bounceOnLaunch, dockSoundFeedback, coordinateNativeDockAutoHide, hiddenRunningBundleIDs
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            placement: try c.decodeIfPresent(DockPlacement.self, forKey: .placement) ?? .fixedBottom,
            scale: try c.decodeIfPresent(Double.self, forKey: .scale) ?? 1.0,
            baseTileSize: try c.decodeIfPresent(Double.self, forKey: .baseTileSize) ?? 46.0,
            tileSpacing: try c.decodeIfPresent(Double.self, forKey: .tileSpacing) ?? 10.0,
            bottomOffset: try c.decodeIfPresent(Double.self, forKey: .bottomOffset) ?? 8.0,
            autoHide: try c.decodeIfPresent(Bool.self, forKey: .autoHide) ?? false,
            revealDelaySeconds: try c.decodeIfPresent(Double.self, forKey: .revealDelaySeconds) ?? 0.2,
            edgeTriggerThickness: try c.decodeIfPresent(Double.self, forKey: .edgeTriggerThickness) ?? 8.0,
            floatingX: try c.decodeIfPresent(Double.self, forKey: .floatingX) ?? 200.0,
            floatingY: try c.decodeIfPresent(Double.self, forKey: .floatingY) ?? 100.0,
            reserveDockSpace: try c.decodeIfPresent(Bool.self, forKey: .reserveDockSpace) ?? false,
            hideInFullscreen: try c.decodeIfPresent(Bool.self, forKey: .hideInFullscreen) ?? false,
            hideOnWindowHover: try c.decodeIfPresent(Bool.self, forKey: .hideOnWindowHover) ?? false,
            maxDockWidth: try c.decodeIfPresent(Double.self, forKey: .maxDockWidth),
            autoFitScreen: try c.decodeIfPresent(Bool.self, forKey: .autoFitScreen) ?? true,
            showProfileSwitcher: try c.decodeIfPresent(Bool.self, forKey: .showProfileSwitcher) ?? true,
            showRunningApps: try c.decodeIfPresent(Bool.self, forKey: .showRunningApps) ?? true,
            magnificationEnabled: try c.decodeIfPresent(Bool.self, forKey: .magnificationEnabled) ?? true,
            magnificationScale: try c.decodeIfPresent(Double.self, forKey: .magnificationScale) ?? 1.45,
            showTooltips: try c.decodeIfPresent(Bool.self, forKey: .showTooltips) ?? true,
            showNotificationBadges: try c.decodeIfPresent(Bool.self, forKey: .showNotificationBadges) ?? true,
            showWindowPreviewsOnHover: try c.decodeIfPresent(Bool.self, forKey: .showWindowPreviewsOnHover) ?? true,
            windowPreviewHoverDelaySeconds: try c.decodeIfPresent(Double.self, forKey: .windowPreviewHoverDelaySeconds) ?? 0.35,
            showMinimizedWindows: try c.decodeIfPresent(Bool.self, forKey: .showMinimizedWindows) ?? true,
            bounceOnLaunch: try c.decodeIfPresent(Bool.self, forKey: .bounceOnLaunch) ?? true,
            dockSoundFeedback: try c.decodeIfPresent(Bool.self, forKey: .dockSoundFeedback) ?? false,
            coordinateNativeDockAutoHide: try c.decodeIfPresent(Bool.self, forKey: .coordinateNativeDockAutoHide) ?? false,
            hiddenRunningBundleIDs: try c.decodeIfPresent([String].self, forKey: .hiddenRunningBundleIDs) ?? []
        )
    }
}
