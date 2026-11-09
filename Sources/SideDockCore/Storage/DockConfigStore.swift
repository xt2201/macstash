import Foundation

public struct SideDockFileConfig: Codable, Equatable, Sendable {
    public var version: Int
    public var activeProfileId: UUID
    public var profiles: [DockProfile]
    public var isDockVisible: Bool
    public var firstLaunchCompleted: Bool

    public init(
        version: Int = 1,
        activeProfileId: UUID? = nil,
        profiles: [DockProfile] = DockProfile.defaultProfiles(),
        isDockVisible: Bool = true,
        firstLaunchCompleted: Bool = false
    ) {
        self.version = version
        self.profiles = profiles.isEmpty ? DockProfile.defaultProfiles() : profiles
        self.activeProfileId = activeProfileId ?? self.profiles.first?.id ?? UUID()
        self.isDockVisible = isDockVisible
        self.firstLaunchCompleted = firstLaunchCompleted
    }
}

public final class DockConfigStore: @unchecked Sendable {
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
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
            self.fileURL = dir.appendingPathComponent("sidedock_config.json")
        }

        // Initialize cache
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
                cfg.profiles[i].layoutConfig.tileSpacing = 10.0
                cfg.profiles[i].layoutConfig.bottomOffset = 8.0
                cfg.profiles[i].layoutConfig.autoHide = false
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
            NSLog("[SideDockConfigStore] Failed to write config atomically: %@", error.localizedDescription)
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

            // Perform schema migration if version mismatch
            if loaded.version < 1 {
                loaded.version = 1
                writeToDiskAtomic(loaded)
            }
            return loaded
        } catch {
            NSLog("[SideDockConfigStore] Config file corrupted: %@. Isolating and resetting defaults.", error.localizedDescription)
            isolateCorruptedFile()
            let fallback = SideDockFileConfig()
            writeToDiskAtomic(fallback)
            return fallback
        }
    }

    private func isolateCorruptedFile() {
        let timestamp = Int(Date().timeIntervalSince1970)
        let corruptedURL = fileURL.deletingLastPathComponent()
            .appendingPathComponent("sidedock_config.corrupted.\(timestamp).json")
        try? fileManager.moveItem(at: fileURL, to: corruptedURL)
    }
}
