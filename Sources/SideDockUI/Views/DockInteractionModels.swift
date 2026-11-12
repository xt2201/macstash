import Foundation
import CoreGraphics
import SideDockCore

public struct MinimizedWindowSummary: Identifiable, Equatable, Sendable {
    public let id: String
    public let windowID: CGWindowID
    public let pid: pid_t
    public let bundleIdentifier: String?
    public let appName: String
    public let windowTitle: String
    public let appPath: String?

    public init(
        windowID: CGWindowID,
        pid: pid_t,
        bundleIdentifier: String?,
        appName: String,
        windowTitle: String,
        appPath: String?
    ) {
        self.id = "\(pid)_\(windowID)"
        self.windowID = windowID
        self.pid = pid
        self.bundleIdentifier = bundleIdentifier
        self.appName = appName
        self.windowTitle = windowTitle
        self.appPath = appPath
    }
}

public struct DockRuntimeState: Equatable, Sendable {
    public var badgesByBundleID: [String: String]
    public var minimizedWindows: [MinimizedWindowSummary]
    public var trashItemCount: Int
    public var isEditMode: Bool
    public var bouncingItemID: UUID?

    public init(
        badgesByBundleID: [String: String] = [:],
        minimizedWindows: [MinimizedWindowSummary] = [],
        trashItemCount: Int = 0,
        isEditMode: Bool = false,
        bouncingItemID: UUID? = nil
    ) {
        self.badgesByBundleID = badgesByBundleID
        self.minimizedWindows = minimizedWindows
        self.trashItemCount = trashItemCount
        self.isEditMode = isEditMode
        self.bouncingItemID = bouncingItemID
    }
}

@MainActor
public struct DockInteractionCallbacks {
    public var onSelectProfile: (UUID) -> Void
    public var onRemoveItem: (UUID) -> Void
    public var onLaunchApp: (AppItem) -> Void
    public var onPinRunningApp: (RunningAppInfo) -> Void
    public var onHideRunningApp: (String) -> Void
    public var onHideOtherApps: (String) -> Void
    public var onShowAppWindows: (String, String, CGRect) -> Void
    public var onMoveItem: (UUID, UUID) -> Void
    public var onDropExternalURLs: ([URL], Int?) -> Void
    public var onDropFilesToApp: ([URL], AppItem) -> Void
    public var onDropFilesToTrash: ([URL]) -> Void
    public var onEmptyTrash: () -> Void
    public var onOpenTrash: () -> Void
    public var onOpenLaunchpad: () -> Void
    public var onExecuteAction: (DockActionItem) -> Void
    public var onCycleSmartStack: (UUID, Int) -> Void
    public var onToggleAppWidgetFace: (UUID) -> Void
    public var onSetCustomAppIcon: (UUID, URL) -> Void
    public var onResetCustomAppIcon: (UUID) -> Void
    public var onResizeWidget: (UUID, WidgetSize) -> Void
    public var onExpandWidget: (WidgetItem, CGRect) -> Void
    public var onUpdateFolderPreferences: (UUID, FolderPresentationStyle, FolderSortOrder) -> Void
    public var onHoverAppChanged: (String?, String?, CGRect?) -> Void
    public var onHoverTooltipChanged: (String?, CGRect?) -> Void
    public var onRestoreMinimizedWindow: (MinimizedWindowSummary) -> Void
    public var onToggleEditMode: () -> Void
    public var onAddQuickItem: (DockItem) -> Void
    public var onConfigureWidget: (WidgetItem) -> Void
    public var onDragBegin: (() -> Void)?
    public var onDragUpdate: (() -> Void)?
    public var onDragEnd: (() -> Void)?
    public var onOpenSettings: () -> Void

    public init(
        onSelectProfile: @escaping (UUID) -> Void,
        onRemoveItem: @escaping (UUID) -> Void,
        onLaunchApp: @escaping (AppItem) -> Void = { _ in },
        onPinRunningApp: @escaping (RunningAppInfo) -> Void = { _ in },
        onHideRunningApp: @escaping (String) -> Void = { _ in },
        onHideOtherApps: @escaping (String) -> Void = { _ in },
        onShowAppWindows: @escaping (String, String, CGRect) -> Void = { _, _, _ in },
        onMoveItem: @escaping (UUID, UUID) -> Void = { _, _ in },
        onDropExternalURLs: @escaping ([URL], Int?) -> Void = { _, _ in },
        onDropFilesToApp: @escaping ([URL], AppItem) -> Void = { _, _ in },
        onDropFilesToTrash: @escaping ([URL]) -> Void = { _ in },
        onEmptyTrash: @escaping () -> Void = {},
        onOpenTrash: @escaping () -> Void = {},
        onOpenLaunchpad: @escaping () -> Void = {},
        onExecuteAction: @escaping (DockActionItem) -> Void = { _ in },
        onCycleSmartStack: @escaping (UUID, Int) -> Void = { _, _ in },
        onToggleAppWidgetFace: @escaping (UUID) -> Void = { _ in },
        onSetCustomAppIcon: @escaping (UUID, URL) -> Void = { _, _ in },
        onResetCustomAppIcon: @escaping (UUID) -> Void = { _ in },
        onResizeWidget: @escaping (UUID, WidgetSize) -> Void,
        onExpandWidget: @escaping (WidgetItem, CGRect) -> Void = { _, _ in },
        onUpdateFolderPreferences: @escaping (UUID, FolderPresentationStyle, FolderSortOrder) -> Void = { _, _, _ in },
        onHoverAppChanged: @escaping (String?, String?, CGRect?) -> Void = { _, _, _ in },
        onHoverTooltipChanged: @escaping (String?, CGRect?) -> Void = { _, _ in },
        onRestoreMinimizedWindow: @escaping (MinimizedWindowSummary) -> Void = { _ in },
        onToggleEditMode: @escaping () -> Void = {},
        onAddQuickItem: @escaping (DockItem) -> Void = { _ in },
        onConfigureWidget: @escaping (WidgetItem) -> Void = { _ in },
        onDragBegin: (() -> Void)? = nil,
        onDragUpdate: (() -> Void)? = nil,
        onDragEnd: (() -> Void)? = nil,
        onOpenSettings: @escaping () -> Void
    ) {
        self.onSelectProfile = onSelectProfile
        self.onRemoveItem = onRemoveItem
        self.onLaunchApp = onLaunchApp
        self.onPinRunningApp = onPinRunningApp
        self.onHideRunningApp = onHideRunningApp
        self.onHideOtherApps = onHideOtherApps
        self.onShowAppWindows = onShowAppWindows
        self.onMoveItem = onMoveItem
        self.onDropExternalURLs = onDropExternalURLs
        self.onDropFilesToApp = onDropFilesToApp
        self.onDropFilesToTrash = onDropFilesToTrash
        self.onEmptyTrash = onEmptyTrash
        self.onOpenTrash = onOpenTrash
        self.onOpenLaunchpad = onOpenLaunchpad
        self.onExecuteAction = onExecuteAction
        self.onCycleSmartStack = onCycleSmartStack
        self.onToggleAppWidgetFace = onToggleAppWidgetFace
        self.onSetCustomAppIcon = onSetCustomAppIcon
        self.onResetCustomAppIcon = onResetCustomIconFallback(onResetCustomAppIcon)
        self.onResizeWidget = onResizeWidget
        self.onExpandWidget = onExpandWidget
        self.onUpdateFolderPreferences = onUpdateFolderPreferences
        self.onHoverAppChanged = onHoverAppChanged
        self.onHoverTooltipChanged = onHoverTooltipChanged
        self.onRestoreMinimizedWindow = onRestoreMinimizedWindow
        self.onToggleEditMode = onToggleEditMode
        self.onAddQuickItem = onAddQuickItem
        self.onConfigureWidget = onConfigureWidget
        self.onDragBegin = onDragBegin
        self.onDragUpdate = onDragUpdate
        self.onDragEnd = onDragEnd
        self.onOpenSettings = onOpenSettings
    }
}

private func onResetCustomIconFallback(_ fn: @escaping (UUID) -> Void) -> (UUID) -> Void {
    fn
}
