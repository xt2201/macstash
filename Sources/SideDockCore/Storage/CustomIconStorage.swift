import Foundation
import os.log

/// Copies user-selected custom icon files into Application Support so paths remain stable.
public struct CustomIconStorage: Sendable {
    private static let logger = Logger(subsystem: "com.macstash.app", category: "sidedock")

    public static func customIconsDirectory(fileManager: FileManager = .default) -> URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
        let dir = appSupport.appendingPathComponent("MacStash/SideDock/CustomIcons", isDirectory: true)
        do {
            try fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        } catch {
            logger.warning("Failed to create CustomIcons directory: \(error.localizedDescription, privacy: .public)")
        }
        return dir
    }

    public static func importCustomIcon(from sourceURL: URL, itemID: UUID, fileManager: FileManager = .default) -> String? {
        let dir = customIconsDirectory(fileManager: fileManager)
        let ext = sourceURL.pathExtension.isEmpty ? "png" : sourceURL.pathExtension
        let destURL = dir.appendingPathComponent("\(itemID.uuidString).\(ext)")
        do {
            if fileManager.fileExists(atPath: destURL.path) {
                try fileManager.removeItem(at: destURL)
            }
            try fileManager.copyItem(at: sourceURL, to: destURL)
            return destURL.path
        } catch {
            logger.error("Failed to copy custom icon from \(sourceURL.path, privacy: .public): \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    public static func removeCustomIcon(at path: String?, fileManager: FileManager = .default) {
        guard let path = path, !path.isEmpty, fileManager.fileExists(atPath: path) else { return }
        do {
            try fileManager.removeItem(atPath: path)
        } catch {
            logger.debug("Failed to delete custom icon at \(path, privacy: .public): \(error.localizedDescription, privacy: .public)")
        }
    }
}
