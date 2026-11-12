import Foundation

public struct CuratedAppAction: Identifiable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let systemIconName: String
    public let kind: DockActionKind
    public let payload: String
    public let targetBundleIdentifier: String?
    public let requiresRunning: Bool

    public init(
        id: String,
        title: String,
        systemIconName: String,
        kind: DockActionKind,
        payload: String,
        targetBundleIdentifier: String? = nil,
        requiresRunning: Bool = false
    ) {
        self.id = id
        self.title = title
        self.systemIconName = systemIconName
        self.kind = kind
        self.payload = payload
        self.targetBundleIdentifier = targetBundleIdentifier
        self.requiresRunning = requiresRunning
    }

    public func asDockActionItem() -> DockActionItem {
        DockActionItem(
            displayName: title,
            kind: kind,
            payload: payload,
            targetBundleIdentifier: targetBundleIdentifier,
            systemIconName: systemIconName
        )
    }
}

public enum CuratedMenuCatalog {
    public static func actions(forBundleID bundleID: String) -> [CuratedAppAction] {
        switch bundleID {
        case "com.apple.Safari":
            return [
                menu("safari.newWindow", "New Window", "macwindow.badge.plus", "File > New Window", bundleID),
                menu("safari.privateWindow", "New Private Window", "eye.slash.fill", "File > New Private Window", bundleID),
                menu("safari.newTab", "New Tab", "plus.square", "File > New Tab", bundleID)
            ]
        case "com.google.Chrome", "com.brave.Browser", "com.microsoft.edgemac":
            return [
                menu("chromium.newWindow", "New Window", "macwindow.badge.plus", "File > New Window", bundleID),
                menu("chromium.incognito", "New Incognito Window", "eye.slash.fill", "File > New Incognito Window", bundleID),
                menu("chromium.newTab", "New Tab", "plus.square", "File > New Tab", bundleID)
            ]
        case "company.thebrowser.Browser": // Arc
            return [
                menu("arc.newWindow", "New Window", "macwindow.badge.plus", "File > New Window", bundleID),
                menu("arc.incognito", "New Incognito Window", "eye.slash.fill", "File > New Incognito Window", bundleID),
                menu("arc.newTab", "New Tab", "plus.square", "File > New Tab", bundleID)
            ]
        case "org.mozilla.firefox":
            return [
                menu("firefox.newWindow", "New Window", "macwindow.badge.plus", "File > New Window", bundleID),
                menu("firefox.privateWindow", "New Private Window", "eye.slash.fill", "File > New Private Window", bundleID)
            ]
        case "com.mitchellh.ghostty", "com.apple.Terminal", "com.googlecode.iterm2":
            return [
                menu("term.newWindow", "New Window", "terminal.fill", "Shell > New Window", bundleID),
                menu("term.newTab", "New Tab", "plus.square", "Shell > New Tab", bundleID)
            ]
        case "com.microsoft.VSCode", "com.todesktop.230313mzl4w4u92": // VS Code & Cursor
            return [
                menu("ide.newWindow", "New Window", "macwindow.badge.plus", "File > New Window", bundleID)
            ]
        case "com.apple.dt.Xcode":
            return [
                menu("xcode.run", "Run", "play.fill", "Product > Run", bundleID, requiresRunning: true),
                menu("xcode.test", "Test", "checkmark.diamond.fill", "Product > Test", bundleID, requiresRunning: true),
                menu("xcode.clean", "Clean Build Folder", "sparkles", "Product > Clean Build Folder", bundleID, requiresRunning: true)
            ]
        case "com.apple.finder":
            return [
                menu("finder.newWindow", "New Finder Window", "folder.badge.plus", "File > New Finder Window", bundleID)
            ]
        case "com.anthropic.claudefordesktop":
            return [
                menu("claude.newChat", "New Conversation", "bubble.left.and.bubble.right.fill", "File > New Chat", bundleID)
            ]
        default:
            return []
        }
    }

    private static func menu(
        _ id: String,
        _ title: String,
        _ icon: String,
        _ path: String,
        _ bundleID: String,
        requiresRunning: Bool = false
    ) -> CuratedAppAction {
        CuratedAppAction(
            id: id,
            title: title,
            systemIconName: icon,
            kind: .menuClick,
            payload: path,
            targetBundleIdentifier: bundleID,
            requiresRunning: requiresRunning
        )
    }
}
