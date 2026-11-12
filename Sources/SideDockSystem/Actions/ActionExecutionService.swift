import AppKit
import ApplicationServices
import os.log
import SideDockCore

@MainActor
public final class ActionExecutionService {
    public static let shared = ActionExecutionService()
    private nonisolated static let logger = Logger(subsystem: "com.macstash.app", category: "actions")

    public var onTriggerLaunchpad: (() -> Void)?
    public var onTriggerWindowSwitcher: (() -> Void)?

    public init() {}

    public func execute(_ action: DockActionItem) {
        switch action.kind {
        case .systemCommand:
            guard let cmd = BuiltInSystemCommand(rawValue: action.payload) else { return }
            executeSystemCommand(cmd)
        case .appleScript:
            runAppleScript(action.payload)
        case .shellScript:
            runShellCommand(action.payload)
        case .menuClick:
            runMenuClick(bundleIdentifier: action.targetBundleIdentifier, menuPath: action.payload)
        case .url:
            if let url = URL(string: action.payload) {
                NSWorkspace.shared.open(url)
            }
        }
    }

    public func executeSystemCommand(_ command: BuiltInSystemCommand) {
        switch command {
        case .lockScreen:
            runProcess("/System/Library/CoreServices/Menu Extras/User.menu/Contents/Resources/CGSession", args: ["-suspend"])
        case .sleepDisplay:
            runProcess("/usr/bin/pmset", args: ["displaysleepnow"])
        case .missionControl:
            NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Mission Control.app"))
        case .appExpose:
            runAppleScript("tell application \"System Events\" to key code 125 using {control down}")
        case .showDesktop:
            runAppleScript("tell application \"System Events\" to key code 103")
        case .screenshotArea:
            runProcess("/usr/sbin/screencapture", args: ["-i", "-c"])
        case .emptyTrash:
            confirmAndEmptyTrash()
        case .toggleDarkMode:
            runAppleScript("tell application \"System Events\" to tell appearance preferences to set dark mode to not dark mode")
        case .openLaunchpad:
            onTriggerLaunchpad?()
        case .openWindowSwitcher:
            onTriggerWindowSwitcher?()
        case .toggleNativeDockAutoHide:
            toggleNativeDockAutoHide()
        }
    }

    public func setNativeDockAutoHide(_ enabled: Bool) {
        let flag = enabled ? "true" : "false"
        Task.detached(priority: .utility) {
            Self.runProcessSync("/usr/bin/defaults", args: ["write", "com.apple.dock", "autohide", "-bool", flag])
            Self.runProcessSync("/usr/bin/killall", args: ["Dock"])
        }
    }

    public func toggleNativeDockAutoHide() {
        Task.detached(priority: .utility) {
            let current = UserDefaults(suiteName: "com.apple.dock")?.bool(forKey: "autohide") ?? false
            let next = current ? "false" : "true"
            Self.runProcessSync("/usr/bin/defaults", args: ["write", "com.apple.dock", "autohide", "-bool", next])
            Self.runProcessSync("/usr/bin/killall", args: ["Dock"])
        }
    }

    public func confirmAndEmptyTrash() {
        let alert = NSAlert()
        alert.messageText = "Empty Trash?"
        alert.informativeText = "All items in the Trash will be permanently erased."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Empty Trash")
        alert.addButton(withTitle: "Cancel")
        if alert.runModal() == .alertFirstButtonReturn {
            runAppleScript("tell application \"Finder\" to empty the trash")
        }
    }

    private func runAppleScript(_ script: String) {
        let source = script
        Task.detached(priority: .userInitiated) {
            Self.runProcessSync("/usr/bin/osascript", args: ["-e", source])
        }
    }

    private func runShellCommand(_ command: String) {
        let trimmed = command.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        Task.detached(priority: .userInitiated) {
            Self.runProcessSync("/bin/zsh", args: ["-c", trimmed])
        }
    }

    private func runProcess(_ path: String, args: [String]) {
        Task.detached(priority: .userInitiated) {
            Self.runProcessSync(path, args: args)
        }
    }

    private nonisolated static func runProcessSync(_ path: String, args: [String]) {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: path)
        proc.arguments = args
        proc.standardOutput = FileHandle.nullDevice
        proc.standardError = FileHandle.nullDevice
        do {
            try proc.run()
            proc.waitUntilExit()
        } catch {
            logger.warning("Action process failed (\(path, privacy: .public)): \(error.localizedDescription, privacy: .public)")
        }
    }

    private func runMenuClick(bundleIdentifier: String?, menuPath: String) {
        guard AXIsProcessTrusted() else {
            Self.logger.warning("Menu click action requires Accessibility permission")
            return
        }
        let targetApp: NSRunningApplication?
        if let bid = bundleIdentifier, !bid.isEmpty {
            targetApp = NSRunningApplication.runningApplications(withBundleIdentifier: bid).first
        } else {
            targetApp = NSWorkspace.shared.frontmostApplication
        }
        guard let app = targetApp else { return }
        app.activate()

        let steps = menuPath.split(separator: ">").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        guard !steps.isEmpty else { return }

        let appAX = AXUIElementCreateApplication(app.processIdentifier)
        var menuBarVal: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appAX, kAXMenuBarAttribute as CFString, &menuBarVal) == .success,
              let menuBarCF = menuBarVal,
              CFGetTypeID(menuBarCF) == AXUIElementGetTypeID() else {
            return
        }

        var currentElement = unsafeBitCast(menuBarCF, to: AXUIElement.self)
        for (idx, step) in steps.enumerated() {
            guard let nextItem = findMenuChild(named: step, in: currentElement) else {
                Self.logger.debug("Menu item not found: \(step, privacy: .public)")
                return
            }
            if idx == steps.count - 1 {
                AXUIElementPerformAction(nextItem, kAXPressAction as CFString)
                return
            }
            var subMenuVal: CFTypeRef?
            if AXUIElementCopyAttributeValue(nextItem, kAXChildrenAttribute as CFString, &subMenuVal) == .success,
               let subList = subMenuVal as? [AXUIElement],
               let firstSub = subList.first {
                currentElement = firstSub
            } else {
                currentElement = nextItem
            }
        }
    }

    private func findMenuChild(named title: String, in parent: AXUIElement) -> AXUIElement? {
        var childrenVal: CFTypeRef?
        guard AXUIElementCopyAttributeValue(parent, kAXChildrenAttribute as CFString, &childrenVal) == .success,
              let children = childrenVal as? [AXUIElement] else {
            return nil
        }
        for child in children {
            var titleVal: CFTypeRef?
            if AXUIElementCopyAttributeValue(child, kAXTitleAttribute as CFString, &titleVal) == .success,
               let itemTitle = titleVal as? String,
               itemTitle.localizedCaseInsensitiveCompare(title) == .orderedSame {
                return child
            }
        }
        return nil
    }
}
