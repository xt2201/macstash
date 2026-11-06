import Foundation
import CoreGraphics

public struct AppSettings: Codable, Equatable, Sendable {
    public var schemaVersion: Int
    public var isEnabled: Bool
    public var isCornerDialsEnabled: Bool
    public var isEdgeSlidersEnabled: Bool
    public var isHiddenDockEnabled: Bool

    public var cornerSensitivityPoints: CGFloat
    public var cornerDwellDelaySeconds: TimeInterval
    public var cornerHideDelaySeconds: TimeInterval

    public var suppressWhenMousePressed: Bool
    public var suppressInFullscreen: Bool
    public var excludedBundleIDs: [String]

    public var isSoundEnabled: Bool
    public var soundVolume: Float
    public var launchAtLogin: Bool

    public init(
        schemaVersion: Int = Defaults.schemaVersion,
        isEnabled: Bool = true,
        isCornerDialsEnabled: Bool = true,
        isEdgeSlidersEnabled: Bool = true,
        isHiddenDockEnabled: Bool = true,
        cornerSensitivityPoints: CGFloat = Defaults.HotCorner.defaultHitZoneSizePoints,
        cornerDwellDelaySeconds: TimeInterval = Defaults.HotCorner.defaultDwellDelaySeconds,
        cornerHideDelaySeconds: TimeInterval = Defaults.HotCorner.defaultHideDelaySeconds,
        suppressWhenMousePressed: Bool = true,
        suppressInFullscreen: Bool = true,
        excludedBundleIDs: [String] = [],
        isSoundEnabled: Bool = true,
        soundVolume: Float = Defaults.Audio.defaultSoundVolume,
        launchAtLogin: Bool = false
    ) {
        self.schemaVersion = schemaVersion
        self.isEnabled = isEnabled
        self.isCornerDialsEnabled = isCornerDialsEnabled
        self.isEdgeSlidersEnabled = isEdgeSlidersEnabled
        self.isHiddenDockEnabled = isHiddenDockEnabled
        self.cornerSensitivityPoints = max(Defaults.HotCorner.minHitZoneSizePoints, min(Defaults.HotCorner.maxHitZoneSizePoints, cornerSensitivityPoints))
        self.cornerDwellDelaySeconds = max(Defaults.HotCorner.minDwellDelaySeconds, min(Defaults.HotCorner.maxDwellDelaySeconds, cornerDwellDelaySeconds))
        self.cornerHideDelaySeconds = max(Defaults.HotCorner.minHideDelaySeconds, min(Defaults.HotCorner.maxHideDelaySeconds, cornerHideDelaySeconds))
        self.suppressWhenMousePressed = suppressWhenMousePressed
        self.suppressInFullscreen = suppressInFullscreen
        self.excludedBundleIDs = excludedBundleIDs
        self.isSoundEnabled = isSoundEnabled
        self.soundVolume = max(0.0, min(1.0, soundVolume))
        self.launchAtLogin = launchAtLogin
    }

    public static var defaultSettings: AppSettings {
        AppSettings()
    }
}

public final class SettingsPersistenceService: @unchecked Sendable {
    private let userDefaults: UserDefaults

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    public func loadSettings() -> AppSettings {
        guard let data = userDefaults.data(forKey: "com.macstash.settings.v1") else {
            return .defaultSettings
        }

        do {
            let decoder = JSONDecoder()
            var settings = try decoder.decode(AppSettings.self, from: data)
            settings = migrateIfNeeded(settings)
            return settings
        } catch {
            AppLogger.settings.error("Failed to decode settings; resetting to defaults: \(error.localizedDescription)")
            return .defaultSettings
        }
    }

    public func saveSettings(_ settings: AppSettings) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(settings)
            userDefaults.set(data, forKey: "com.macstash.settings.v1")
        } catch {
            AppLogger.settings.error("Failed to encode settings: \(error.localizedDescription)")
        }
    }

    public func exportJSON(settings: AppSettings) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(settings)
    }

    public func importJSON(data: Data) throws -> AppSettings {
        let decoder = JSONDecoder()
        var settings = try decoder.decode(AppSettings.self, from: data)
        settings = migrateIfNeeded(settings)
        saveSettings(settings)
        return settings
    }

    private func migrateIfNeeded(_ settings: AppSettings) -> AppSettings {
        var migrated = settings
        // Example: schemaVersion upgrade migration logic
        if migrated.schemaVersion < Defaults.schemaVersion {
            migrated.schemaVersion = Defaults.schemaVersion
        }
        // Ensure values stay clamped within valid range
        migrated.cornerSensitivityPoints = max(Defaults.HotCorner.minHitZoneSizePoints, min(Defaults.HotCorner.maxHitZoneSizePoints, migrated.cornerSensitivityPoints))
        migrated.cornerDwellDelaySeconds = max(Defaults.HotCorner.minDwellDelaySeconds, min(Defaults.HotCorner.maxDwellDelaySeconds, migrated.cornerDwellDelaySeconds))
        migrated.cornerHideDelaySeconds = max(Defaults.HotCorner.minHideDelaySeconds, min(Defaults.HotCorner.maxHideDelaySeconds, migrated.cornerHideDelaySeconds))
        return migrated
    }
}
