import Foundation
import os.log

public struct SideDockFileConfig: Codable, Equatable, Sendable {
    public var version: Int
    public var activeProfileId: UUID
    public var profiles: [DockProfile]
    public var isDockVisible: Bool
    public var firstLaunchCompleted: Bool
    public var launchpadLayout: LaunchpadLayoutConfig
    public var launchpadShortcut: String
    public var windowSwitcherEnabled: Bool
    public var windowSwitcherShortcut: String
    public var windowSwitcherInterceptCmdTab: Bool

    public init(
        version: Int = 2,
        activeProfileId: UUID? = nil,
        profiles: [DockProfile] = DockProfile.defaultProfiles(),
        isDockVisible: Bool = true,
        firstLaunchCompleted: Bool = false,
        launchpadLayout: LaunchpadLayoutConfig = LaunchpadLayoutConfig(),
        launchpadShortcut: String = "ctrl+opt+l",
        windowSwitcherEnabled: Bool = true,
        windowSwitcherShortcut: String = "opt+tab",
        windowSwitcherInterceptCmdTab: Bool = false
    ) {
        self.version = version
        self.profiles = profiles.isEmpty ? DockProfile.defaultProfiles() : profiles
        self.activeProfileId = activeProfileId ?? self.profiles.first?.id ?? UUID()
        self.isDockVisible = isDockVisible
        self.firstLaunchCompleted = firstLaunchCompleted
        self.launchpadLayout = launchpadLayout
        self.launchpadShortcut = launchpadShortcut
        self.windowSwitcherEnabled = windowSwitcherEnabled
        self.windowSwitcherShortcut = windowSwitcherShortcut
        self.windowSwitcherInterceptCmdTab = windowSwitcherInterceptCmdTab
    }

    private enum CodingKeys: String, CodingKey {
        case version, activeProfileId, profiles, isDockVisible, firstLaunchCompleted
        case launchpadLayout, launchpadShortcut, windowSwitcherEnabled
        case windowSwitcherShortcut, windowSwitcherInterceptCmdTab
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let profiles = try c.decodeIfPresent([DockProfile].self, forKey: .profiles) ?? DockProfile.defaultProfiles()
        self.init(
            version: try c.decodeIfPresent(Int.self, forKey: .version) ?? 1,
            activeProfileId: try c.decodeIfPresent(UUID.self, forKey: .activeProfileId),
            profiles: profiles,
            isDockVisible: try c.decodeIfPresent(Bool.self, forKey: .isDockVisible) ?? true,
            firstLaunchCompleted: try c.decodeIfPresent(Bool.self, forKey: .firstLaunchCompleted) ?? false,
            launchpadLayout: try c.decodeIfPresent(LaunchpadLayoutConfig.self, forKey: .launchpadLayout) ?? LaunchpadLayoutConfig(),
            launchpadShortcut: try c.decodeIfPresent(String.self, forKey: .launchpadShortcut) ?? "ctrl+opt+l",
            windowSwitcherEnabled: try c.decodeIfPresent(Bool.self, forKey: .windowSwitcherEnabled) ?? true,
            windowSwitcherShortcut: try c.decodeIfPresent(String.self, forKey: .windowSwitcherShortcut) ?? "opt+tab",
            windowSwitcherInterceptCmdTab: try c.decodeIfPresent(Bool.self, forKey: .windowSwitcherInterceptCmdTab) ?? false
        )
    }
}

public final class DockConfigStore: @unchecked Sendable {
    private static let logger = Logger(subsystem: "com.macstash.app", category: "sidedock")
    private let fileURL: URL
    private let fileManager: FileManager
    private let lock = NSLock()
    private var cachedConfig: SideDockFileConfig
    private var pendingSaveWorkItem: DispatchWorkItem?
    private let saveQueue = DispatchQueue(label: "com.macstash.sidedock.configstore", qos: .utility)

    public init(customFileURL: URL? = nil, fileManager: FileManager = .default) {
        self.fileManager = fileManager
        if let custom = customFileURL {
            self.fileURL = custom
        } else {
            let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
                ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
            let dir = appSupport.appendingPathComponent("MacStash/SideDock", isDirectory: true)
            do {
                try fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
            } catch {
                Self.logger.warning("Failed to create SideDock config directory: \(error.localizedDescription, privacy: .public)")
            }
            self.fileURL = dir.appendingPathComponent("sidedock_config.json")
        }

        self.cachedConfig = SideDockFileConfig()
        self.cachedConfig = loadConfigFromDisk()
    }

    public var config: SideDockFileConfig {
        lock.lock()
        defer { lock.unlock() }
        return cachedConfig
    }

    public func activeProfile() -> DockProfile {
        lock.lock()
        defer { lock.unlock() }
        if let found = cachedConfig.profiles.first(where: { $0.id == cachedConfig.activeProfileId }) {
            return found
        }
        return cachedConfig.profiles.first ?? DockProfile.defaultProfiles()[0]
    }

    public func updateConfig(immediate: Bool = false, _ update: (inout SideDockFileConfig) -> Void) {
        lock.lock()
        update(&cachedConfig)
        let configToSave = cachedConfig
        lock.unlock()

        if immediate {
            saveQueue.sync {
                self.writeToDiskAtomic(configToSave)
            }
        } else {
            scheduleDebouncedSave(configToSave)
        }
    }

    public func resetLayout() {
        updateConfig(immediate: true) { cfg in
            for i in 0..<cfg.profiles.count {
                cfg.profiles[i].layoutConfig.placement = .fixedBottom
                cfg.profiles[i].layoutConfig.floatingX = 200.0
                cfg.profiles[i].layoutConfig.floatingY = 100.0
                cfg.profiles[i].layoutConfig.scale = 1.0
                cfg.profiles[i].layoutConfig.baseTileSize = 46.0
                cfg.profiles[i].layoutConfig.tileSpacing = 10.0
                cfg.profiles[i].layoutConfig.bottomOffset = 8.0
                cfg.profiles[i].layoutConfig.autoHide = false
                cfg.profiles[i].layoutConfig.magnificationEnabled = true
                cfg.profiles[i].layoutConfig.magnificationScale = 1.45
            }
        }
    }

    // MARK: - Disk I/O & Migration

    private func scheduleDebouncedSave(_ configToSave: SideDockFileConfig) {
        lock.lock()
        pendingSaveWorkItem?.cancel()
        let item = DispatchWorkItem { [weak self] in
            self?.writeToDiskAtomic(configToSave)
        }
        pendingSaveWorkItem = item
        lock.unlock()

        saveQueue.asyncAfter(deadline: .now() + 1.0, execute: item)
    }

    private func writeToDiskAtomic(_ cfg: SideDockFileConfig) {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(cfg)

            let dir = fileURL.deletingLastPathComponent()
            try fileManager.createDirectory(at: dir, withIntermediateDirectories: true)

            let tempURL = dir.appendingPathComponent("sidedock_config.tmp.\(UUID().uuidString)")
            try data.write(to: tempURL, options: .atomic)
            _ = try fileManager.replaceItemAt(fileURL, withItemAt: tempURL)
        } catch {
            Self.logger.error("Failed to write config atomically: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func loadConfigFromDisk() -> SideDockFileConfig {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            let defaults = SideDockFileConfig()
            writeToDiskAtomic(defaults)
            return defaults
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            var loaded = try decoder.decode(SideDockFileConfig.self, from: data)

            if loaded.version < 2 {
                loaded = migrateToV2(loaded)
                writeToDiskAtomic(loaded)
                Self.logger.info("Migrated SideDock config schema to v2")
            }
            return loaded
        } catch {
            Self.logger.error("Config file corrupted: \(error.localizedDescription, privacy: .public). Isolating and resetting defaults.")
            isolateCorruptedFile()
            let fallback = SideDockFileConfig()
            writeToDiskAtomic(fallback)
            return fallback
        }
    }

    private func migrateToV2(_ old: SideDockFileConfig) -> SideDockFileConfig {
        var migrated = old
        migrated.version = 2
        if migrated.launchpadShortcut.isEmpty {
            migrated.launchpadShortcut = "ctrl+opt+l"
        }
        if migrated.windowSwitcherShortcut.isEmpty {
            migrated.windowSwitcherShortcut = "opt+tab"
        }
        return migrated
    }

    private func isolateCorruptedFile() {
        let timestamp = Int(Date().timeIntervalSince1970)
        let corruptedURL = fileURL.deletingLastPathComponent()
            .appendingPathComponent("sidedock_config.corrupted.\(timestamp).json")
        do {
            try fileManager.moveItem(at: fileURL, to: corruptedURL)
        } catch {
            Self.logger.warning("Failed to isolate corrupted config: \(error.localizedDescription, privacy: .public)")
        }
    }
}
