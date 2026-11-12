import SwiftUI
import AppKit
import SideDockCore
import SideDockWidgets
import MacStashCore

public struct AppTileContextMenuContent: View {
    public let bundleID: String
    public let displayName: String
    public let appPath: String
    public let isPinned: Bool
    public let isRunning: Bool
    public let showWidgetFace: Bool
    public let customIconPath: String?
    public let isEditMode: Bool

    public let onOpen: () -> Void
    public let onShowInFinder: () -> Void
    public let onShowAllWindows: () -> Void
    public let onKeepInDock: (() -> Void)?
    public let onToggleWidgetFace: (() -> Void)?
    public let onExpandWidgetFace: (() -> Void)?
    public let onPickCustomIcon: (() -> Void)?
    public let onResetCustomIcon: (() -> Void)?
    public let onHide: () -> Void
    public let onHideOthers: () -> Void
    public let onQuit: () -> Void
    public let onForceQuit: () -> Void
    public let onExecuteCuratedAction: (DockActionItem) -> Void
    public let onHideFromRunningApps: (() -> Void)?
    public let onToggleEditMode: () -> Void
    public let onRemove: (() -> Void)?

    public init(
        bundleID: String,
        displayName: String,
        appPath: String,
        isPinned: Bool,
        isRunning: Bool,
        showWidgetFace: Bool = false,
        customIconPath: String? = nil,
        isEditMode: Bool,
        onOpen: @escaping () -> Void,
        onShowInFinder: @escaping () -> Void,
        onShowAllWindows: @escaping () -> Void,
        onKeepInDock: (() -> Void)? = nil,
        onToggleWidgetFace: (() -> Void)? = nil,
        onExpandWidgetFace: (() -> Void)? = nil,
        onPickCustomIcon: (() -> Void)? = nil,
        onResetCustomIcon: (() -> Void)? = nil,
        onHide: @escaping () -> Void,
        onHideOthers: @escaping () -> Void,
        onQuit: @escaping () -> Void,
        onForceQuit: @escaping () -> Void,
        onExecuteCuratedAction: @escaping (DockActionItem) -> Void,
        onHideFromRunningApps: (() -> Void)? = nil,
        onToggleEditMode: @escaping () -> Void,
        onRemove: (() -> Void)? = nil
    ) {
        self.bundleID = bundleID
        self.displayName = displayName
        self.appPath = appPath
        self.isPinned = isPinned
        self.isRunning = isRunning
        self.showWidgetFace = showWidgetFace
        self.customIconPath = customIconPath
        self.isEditMode = isEditMode
        self.onOpen = onOpen
        self.onShowInFinder = onShowInFinder
        self.onShowAllWindows = onShowAllWindows
        self.onKeepInDock = onKeepInDock
        self.onToggleWidgetFace = onToggleWidgetFace
        self.onExpandWidgetFace = onExpandWidgetFace
        self.onPickCustomIcon = onPickCustomIcon
        self.onResetCustomIcon = onResetCustomIcon
        self.onHide = onHide
        self.onHideOthers = onHideOthers
        self.onQuit = onQuit
        self.onForceQuit = onForceQuit
        self.onExecuteCuratedAction = onExecuteCuratedAction
        self.onHideFromRunningApps = onHideFromRunningApps
        self.onToggleEditMode = onToggleEditMode
        self.onRemove = onRemove
    }

    private func localized(_ key: String) -> String {
        LocalizationService.shared.localized(key)
    }

    public var body: some View {
        let curated = CuratedMenuCatalog.actions(forBundleID: bundleID)
            .filter { !$0.requiresRunning || isRunning }
        let optionHeld = NSEvent.modifierFlags.contains(.option)

        Button(localized("dock.open")) { onOpen() }

        if isRunning {
            Button(localized("dock.showAllWindows")) { onShowAllWindows() }
        }

        if !curated.isEmpty {
            Divider()
            ForEach(curated) { action in
                Button {
                    onExecuteCuratedAction(action.asDockActionItem())
                } label: {
                    Label(action.title, systemImage: action.systemIconName)
                }
            }
        }

        Divider()
        Menu(localized("dock.optionsSubmenu")) {
            if !isPinned, let onKeepInDock {
                Button(localized("dock.keepInDock")) { onKeepInDock() }
            }
            Button(localized("dock.openInFinder")) { onShowInFinder() }
            if let onPickCustomIcon {
                Button(localized("dock.chooseCustomIcon")) { onPickCustomIcon() }
            }
            if customIconPath != nil, let onResetCustomIcon {
                Button(localized("dock.resetCustomIcon")) { onResetCustomIcon() }
            }
            if !isPinned, let onHideFromRunningApps {
                Divider()
                Button(localized("dock.hideFromRunning")) { onHideFromRunningApps() }
            }
        }

        if isPinned, let onToggleWidgetFace,
           AppWidgetFaceRegistry.defaultWidgetKind(forBundleID: bundleID) != nil {
            Divider()
            Button(showWidgetFace ? localized("dock.showAppIcon") : localized("dock.showWidgetFace")) {
                onToggleWidgetFace()
            }
            if !showWidgetFace, let onExpandWidgetFace {
                Button(localized("dock.expandWidget")) { onExpandWidgetFace() }
            }
        }

        if isRunning && bundleID != "com.apple.finder" {
            Divider()
            if optionHeld {
                Button(localized("dock.hideOthers")) { onHideOthers() }
                Button(localized("dock.forceQuit"), role: .destructive) { onForceQuit() }
            } else {
                Button(localized("dock.hide")) { onHide() }
                Button(localized("dock.quit")) { onQuit() }
            }
        }

        Divider()
        Button(isEditMode ? localized("dock.doneEditing") : localized("dock.editDock")) {
            onToggleEditMode()
        }

        if isPinned, let onRemove {
            Button(localized("dock.remove"), role: .destructive) { onRemove() }
        }
    }
}
