import AppKit
import Foundation
import UniformTypeIdentifiers

public struct DockItem: Identifiable, Codable, Equatable, Hashable {
    public var id: UUID
    public var name: String
    public var bundleIdentifier: String
    public var appPath: String

    public init(id: UUID = UUID(), name: String, bundleIdentifier: String, appPath: String) {
        self.id = id
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.appPath = appPath
    }

    /// Retrieve the application icon from macOS Workspace
    public var icon: NSImage {
        if FileManager.default.fileExists(atPath: appPath) {
            return NSWorkspace.shared.icon(forFile: appPath)
        }
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) {
            return NSWorkspace.shared.icon(forFile: url.path)
        }
        return NSWorkspace.shared.icon(for: .application)
    }

    /// Launch or activate the application
    public func launch() {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) {
            let config = NSWorkspace.OpenConfiguration()
            config.activates = true
            NSWorkspace.shared.openApplication(at: url, configuration: config, completionHandler: nil)
        } else if FileManager.default.fileExists(atPath: appPath) {
            let url = URL(fileURLWithPath: appPath)
            let config = NSWorkspace.OpenConfiguration()
            config.activates = true
            NSWorkspace.shared.openApplication(at: url, configuration: config, completionHandler: nil)
        }
    }

    public static func == (lhs: DockItem, rhs: DockItem) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
