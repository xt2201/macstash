import Foundation
import CoreGraphics

public struct AppSettings: Codable, Equatable, Sendable {
    public var schemaVersion: Int
    public var isEnabled: Bool
    public var isCornerDialsEnabled: Bool
    public var isEdgeSlidersEnabled: Bool

    // Hot Corners
    public var cornerSensitivityPoints: CGFloat
    public var cornerDwellDelaySeconds: TimeInterval
    public var cornerHideDelaySeconds: TimeInterval
    public var suppressWhenMousePressed: Bool
    public var suppressInFullscreen: Bool
    public var onlyOuterCorners: Bool
    public var scrollAdjustmentEnabled: Bool
    public var excludedBundleIDs: [String]
    public var cornerEnabled: [CornerPosition: Bool]
    public var cornerActions: [CornerPosition: ControlAction]

    // General & MenuBar
    public var launchAtLogin: Bool
    public var showMenuBarIcon: Bool
    public var language: String

    // Appearance
    public var dialRadiusPoints: CGFloat
    public var dialOpacity: Double
    public var appearanceTheme: String
    public var animationSpeedMultiplier: Double
    public var respectReduceMotion: Bool

    // Displays
    public var displayBrightnessProfiles: [String: DisplayBrightnessProfile]
    public var brightnessStepFraction: Float
    public var minBrightnessClamp: Float
    public var maxBrightnessClamp: Float

    // Pomodoro
    public var pomodoroFocusDurationMinutes: Int
    public var pomodoroShortBreakMinutes: Int
    public var pomodoroLongBreakMinutes: Int
    public var pomodoroRoundsBeforeLongBreak: Int
    public var pomodoroAutoStartBreaks: Bool
    public var pomodoroSoundEnabled: Bool

    // Audio & Feedback
    public var isSoundEnabled: Bool
    public var soundVolume: Float
    public var hapticFeedbackEnabled: Bool
    public var hapticIntensity: String

    // Shortcuts
    public var globalToggleDialsShortcut: String

    // Advanced
    public var debugLoggingEnabled: Bool

    public init(
        schemaVersion: Int = Defaults.schemaVersion,
        isEnabled: Bool = true,
        isCornerDialsEnabled: Bool = true,
        isEdgeSlidersEnabled: Bool = true,
        cornerSensitivityPoints: CGFloat = Defaults.HotCorner.defaultHitZoneSizePoints,
        cornerDwellDelaySeconds: TimeInterval = Defaults.HotCorner.defaultDwellDelaySeconds,
        cornerHideDelaySeconds: TimeInterval = Defaults.HotCorner.defaultHideDelaySeconds,
        suppressWhenMousePressed: Bool = true,
        suppressInFullscreen: Bool = true,
        onlyOuterCorners: Bool = false,
        scrollAdjustmentEnabled: Bool = true,
        excludedBundleIDs: [String] = [],
        cornerEnabled: [CornerPosition: Bool] = [
            .topLeft: true,
            .topRight: true,
            .bottomLeft: true,
            .bottomRight: true
        ],
        cornerActions: [CornerPosition: ControlAction] = [
            .bottomRight: .volume,
            .topRight: .brightness,
            .bottomLeft: .timer,
            .topLeft: .keyboardBrightness
        ],
        launchAtLogin: Bool = false,
        showMenuBarIcon: Bool = true,
        language: String = "system",
        dialRadiusPoints: CGFloat = Defaults.HotCorner.defaultDialRadiusPoints,
        dialOpacity: Double = 0.95,
        appearanceTheme: String = "system",
        animationSpeedMultiplier: Double = 1.0,
        respectReduceMotion: Bool = true,
        displayBrightnessProfiles: [String: DisplayBrightnessProfile] = [:],
        brightnessStepFraction: Float = Defaults.Brightness.stepFraction,
        minBrightnessClamp: Float = Defaults.Brightness.minLevel,
        maxBrightnessClamp: Float = Defaults.Brightness.maxLevel,
        pomodoroFocusDurationMinutes: Int = 25,
        pomodoroShortBreakMinutes: Int = 5,
        pomodoroLongBreakMinutes: Int = 15,
        pomodoroRoundsBeforeLongBreak: Int = Defaults.Pomodoro.defaultRoundsBeforeLongBreak,
        pomodoroAutoStartBreaks: Bool = false,
        pomodoroSoundEnabled: Bool = true,
        isSoundEnabled: Bool = true,
        soundVolume: Float = Defaults.Audio.defaultSoundVolume,
        hapticFeedbackEnabled: Bool = true,
        hapticIntensity: String = "medium",
        globalToggleDialsShortcut: String = "Option+S",
        debugLoggingEnabled: Bool = false
    ) {
        self.schemaVersion = schemaVersion
        self.isEnabled = isEnabled
        self.isCornerDialsEnabled = isCornerDialsEnabled
        self.isEdgeSlidersEnabled = isEdgeSlidersEnabled
        self.cornerSensitivityPoints = max(Defaults.HotCorner.minHitZoneSizePoints, min(Defaults.HotCorner.maxHitZoneSizePoints, cornerSensitivityPoints))
        self.cornerDwellDelaySeconds = max(Defaults.HotCorner.minDwellDelaySeconds, min(Defaults.HotCorner.maxDwellDelaySeconds, cornerDwellDelaySeconds))
        self.cornerHideDelaySeconds = max(Defaults.HotCorner.minHideDelaySeconds, min(Defaults.HotCorner.maxHideDelaySeconds, cornerHideDelaySeconds))
        self.suppressWhenMousePressed = suppressWhenMousePressed
        self.suppressInFullscreen = suppressInFullscreen
        self.onlyOuterCorners = onlyOuterCorners
        self.scrollAdjustmentEnabled = scrollAdjustmentEnabled
        self.excludedBundleIDs = excludedBundleIDs
        self.cornerEnabled = cornerEnabled
        self.cornerActions = cornerActions
        self.launchAtLogin = launchAtLogin
        self.showMenuBarIcon = showMenuBarIcon
        self.language = language
        self.dialRadiusPoints = max(100.0, min(250.0, dialRadiusPoints))
        self.dialOpacity = max(0.2, min(1.0, dialOpacity))
        self.appearanceTheme = appearanceTheme
        self.animationSpeedMultiplier = max(0.5, min(2.0, animationSpeedMultiplier))
        self.respectReduceMotion = respectReduceMotion
        self.displayBrightnessProfiles = displayBrightnessProfiles
        self.brightnessStepFraction = max(0.01, min(0.25, brightnessStepFraction))
        self.minBrightnessClamp = max(0.0, min(0.5, minBrightnessClamp))
        self.maxBrightnessClamp = max(0.5, min(1.0, maxBrightnessClamp))
        self.pomodoroFocusDurationMinutes = max(1, min(120, pomodoroFocusDurationMinutes))
        self.pomodoroShortBreakMinutes = max(1, min(60, pomodoroShortBreakMinutes))
        self.pomodoroLongBreakMinutes = max(1, min(90, pomodoroLongBreakMinutes))
        self.pomodoroRoundsBeforeLongBreak = max(1, min(12, pomodoroRoundsBeforeLongBreak))
        self.pomodoroAutoStartBreaks = pomodoroAutoStartBreaks
        self.pomodoroSoundEnabled = pomodoroSoundEnabled
        self.isSoundEnabled = isSoundEnabled
        self.soundVolume = max(0.0, min(1.0, soundVolume))
        self.hapticFeedbackEnabled = hapticFeedbackEnabled
        self.hapticIntensity = hapticIntensity
        self.globalToggleDialsShortcut = globalToggleDialsShortcut
        self.debugLoggingEnabled = debugLoggingEnabled
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let def = AppSettings.defaultSettings

        let schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? def.schemaVersion
        let isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? def.isEnabled
        let isCornerDialsEnabled = try container.decodeIfPresent(Bool.self, forKey: .isCornerDialsEnabled) ?? def.isCornerDialsEnabled
        let isEdgeSlidersEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEdgeSlidersEnabled) ?? def.isEdgeSlidersEnabled
        let cornerSensitivityPoints = try container.decodeIfPresent(CGFloat.self, forKey: .cornerSensitivityPoints) ?? def.cornerSensitivityPoints
        let cornerDwellDelaySeconds = try container.decodeIfPresent(TimeInterval.self, forKey: .cornerDwellDelaySeconds) ?? def.cornerDwellDelaySeconds
        let cornerHideDelaySeconds = try container.decodeIfPresent(TimeInterval.self, forKey: .cornerHideDelaySeconds) ?? def.cornerHideDelaySeconds
        let suppressWhenMousePressed = try container.decodeIfPresent(Bool.self, forKey: .suppressWhenMousePressed) ?? def.suppressWhenMousePressed
        let suppressInFullscreen = try container.decodeIfPresent(Bool.self, forKey: .suppressInFullscreen) ?? def.suppressInFullscreen
        let onlyOuterCorners = try container.decodeIfPresent(Bool.self, forKey: .onlyOuterCorners) ?? false
        let scrollAdjustmentEnabled = try container.decodeIfPresent(Bool.self, forKey: .scrollAdjustmentEnabled) ?? def.scrollAdjustmentEnabled
        let excludedBundleIDs = try container.decodeIfPresent([String].self, forKey: .excludedBundleIDs) ?? def.excludedBundleIDs
        let cornerEnabled = try container.decodeIfPresent([CornerPosition: Bool].self, forKey: .cornerEnabled) ?? def.cornerEnabled
        let cornerActions = try container.decodeIfPresent([CornerPosition: ControlAction].self, forKey: .cornerActions) ?? def.cornerActions
        let launchAtLogin = try container.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? def.launchAtLogin
        let showMenuBarIcon = try container.decodeIfPresent(Bool.self, forKey: .showMenuBarIcon) ?? def.showMenuBarIcon
        let language = try container.decodeIfPresent(String.self, forKey: .language) ?? def.language
        let dialRadiusPoints = try container.decodeIfPresent(CGFloat.self, forKey: .dialRadiusPoints) ?? def.dialRadiusPoints
        let dialOpacity = try container.decodeIfPresent(Double.self, forKey: .dialOpacity) ?? def.dialOpacity
        let appearanceTheme = try container.decodeIfPresent(String.self, forKey: .appearanceTheme) ?? def.appearanceTheme
        let animationSpeedMultiplier = try container.decodeIfPresent(Double.self, forKey: .animationSpeedMultiplier) ?? def.animationSpeedMultiplier
        let respectReduceMotion = try container.decodeIfPresent(Bool.self, forKey: .respectReduceMotion) ?? def.respectReduceMotion
        let displayBrightnessProfiles = try container.decodeIfPresent([String: DisplayBrightnessProfile].self, forKey: .displayBrightnessProfiles) ?? def.displayBrightnessProfiles
        let brightnessStepFraction = try container.decodeIfPresent(Float.self, forKey: .brightnessStepFraction) ?? def.brightnessStepFraction
        let minBrightnessClamp = try container.decodeIfPresent(Float.self, forKey: .minBrightnessClamp) ?? def.minBrightnessClamp
        let maxBrightnessClamp = try container.decodeIfPresent(Float.self, forKey: .maxBrightnessClamp) ?? def.maxBrightnessClamp
        let pomodoroFocusDurationMinutes = try container.decodeIfPresent(Int.self, forKey: .pomodoroFocusDurationMinutes) ?? def.pomodoroFocusDurationMinutes
        let pomodoroShortBreakMinutes = try container.decodeIfPresent(Int.self, forKey: .pomodoroShortBreakMinutes) ?? def.pomodoroShortBreakMinutes
        let pomodoroLongBreakMinutes = try container.decodeIfPresent(Int.self, forKey: .pomodoroLongBreakMinutes) ?? def.pomodoroLongBreakMinutes
        let pomodoroRoundsBeforeLongBreak = try container.decodeIfPresent(Int.self, forKey: .pomodoroRoundsBeforeLongBreak) ?? def.pomodoroRoundsBeforeLongBreak
        let pomodoroAutoStartBreaks = try container.decodeIfPresent(Bool.self, forKey: .pomodoroAutoStartBreaks) ?? def.pomodoroAutoStartBreaks
        let pomodoroSoundEnabled = try container.decodeIfPresent(Bool.self, forKey: .pomodoroSoundEnabled) ?? def.pomodoroSoundEnabled
        let isSoundEnabled = try container.decodeIfPresent(Bool.self, forKey: .isSoundEnabled) ?? def.isSoundEnabled
        let soundVolume = try container.decodeIfPresent(Float.self, forKey: .soundVolume) ?? def.soundVolume
        let hapticFeedbackEnabled = try container.decodeIfPresent(Bool.self, forKey: .hapticFeedbackEnabled) ?? def.hapticFeedbackEnabled
        let hapticIntensity = try container.decodeIfPresent(String.self, forKey: .hapticIntensity) ?? def.hapticIntensity
        let globalToggleDialsShortcut = try container.decodeIfPresent(String.self, forKey: .globalToggleDialsShortcut) ?? def.globalToggleDialsShortcut
        let debugLoggingEnabled = try container.decodeIfPresent(Bool.self, forKey: .debugLoggingEnabled) ?? def.debugLoggingEnabled

        self.init(
            schemaVersion: schemaVersion,
            isEnabled: isEnabled,
            isCornerDialsEnabled: isCornerDialsEnabled,
            isEdgeSlidersEnabled: isEdgeSlidersEnabled,
            cornerSensitivityPoints: cornerSensitivityPoints,
            cornerDwellDelaySeconds: cornerDwellDelaySeconds,
            cornerHideDelaySeconds: cornerHideDelaySeconds,
            suppressWhenMousePressed: suppressWhenMousePressed,
            suppressInFullscreen: suppressInFullscreen,
            onlyOuterCorners: onlyOuterCorners,
            scrollAdjustmentEnabled: scrollAdjustmentEnabled,
            excludedBundleIDs: excludedBundleIDs,
            cornerEnabled: cornerEnabled,
            cornerActions: cornerActions,
            launchAtLogin: launchAtLogin,
            showMenuBarIcon: showMenuBarIcon,
            language: language,
            dialRadiusPoints: dialRadiusPoints,
            dialOpacity: dialOpacity,
            appearanceTheme: appearanceTheme,
            animationSpeedMultiplier: animationSpeedMultiplier,
            respectReduceMotion: respectReduceMotion,
            displayBrightnessProfiles: displayBrightnessProfiles,
            brightnessStepFraction: brightnessStepFraction,
            minBrightnessClamp: minBrightnessClamp,
            maxBrightnessClamp: maxBrightnessClamp,
            pomodoroFocusDurationMinutes: pomodoroFocusDurationMinutes,
            pomodoroShortBreakMinutes: pomodoroShortBreakMinutes,
            pomodoroLongBreakMinutes: pomodoroLongBreakMinutes,
            pomodoroRoundsBeforeLongBreak: pomodoroRoundsBeforeLongBreak,
            pomodoroAutoStartBreaks: pomodoroAutoStartBreaks,
            pomodoroSoundEnabled: pomodoroSoundEnabled,
            isSoundEnabled: isSoundEnabled,
            soundVolume: soundVolume,
            hapticFeedbackEnabled: hapticFeedbackEnabled,
            hapticIntensity: hapticIntensity,
            globalToggleDialsShortcut: globalToggleDialsShortcut,
            debugLoggingEnabled: debugLoggingEnabled
        )
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

    public func resetToDefaults() -> AppSettings {
        let fresh = AppSettings.defaultSettings
        saveSettings(fresh)
        return fresh
    }

    private func migrateIfNeeded(_ settings: AppSettings) -> AppSettings {
        var migrated = settings
        if migrated.schemaVersion < Defaults.schemaVersion {
            migrated.schemaVersion = Defaults.schemaVersion
        }
        migrated.cornerSensitivityPoints = max(Defaults.HotCorner.minHitZoneSizePoints, min(Defaults.HotCorner.maxHitZoneSizePoints, migrated.cornerSensitivityPoints))
        migrated.cornerDwellDelaySeconds = max(Defaults.HotCorner.minDwellDelaySeconds, min(Defaults.HotCorner.maxDwellDelaySeconds, migrated.cornerDwellDelaySeconds))
        migrated.cornerHideDelaySeconds = max(Defaults.HotCorner.minHideDelaySeconds, min(Defaults.HotCorner.maxHideDelaySeconds, migrated.cornerHideDelaySeconds))
        migrated.dialRadiusPoints = max(100.0, min(250.0, migrated.dialRadiusPoints))
        migrated.dialOpacity = max(0.2, min(1.0, migrated.dialOpacity))
        migrated.soundVolume = max(0.0, min(1.0, migrated.soundVolume))
        migrated.brightnessStepFraction = max(0.01, min(0.25, migrated.brightnessStepFraction))
        migrated.minBrightnessClamp = max(0.0, min(0.5, migrated.minBrightnessClamp))
        migrated.maxBrightnessClamp = max(0.5, min(1.0, migrated.maxBrightnessClamp))
        migrated.pomodoroFocusDurationMinutes = max(1, min(120, migrated.pomodoroFocusDurationMinutes))
        migrated.pomodoroShortBreakMinutes = max(1, min(60, migrated.pomodoroShortBreakMinutes))
        migrated.pomodoroLongBreakMinutes = max(1, min(90, migrated.pomodoroLongBreakMinutes))
        return migrated
    }
}
