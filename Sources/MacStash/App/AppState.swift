import SwiftUI
import Combine
import CoreGraphics
import MacStashCore

@MainActor
public final class AppState: ObservableObject {
    public static let shared = AppState()

    // Domain & Hardware Services
    public let audio = AudioManager.shared
    public let keyboard = KeyboardBrightnessManager.shared
    public let updater = AutoUpdateManager.shared
    public let profiles = AppProfileManager.shared
    public let haptics = HapticManager.shared
    public let sound = SoundEffectManager.shared

    public let persistence = SettingsPersistenceService()
    public let brightnessService = CompositeBrightnessService()
    public let pomodoroEngine = PomodoroEngine()
    public let notificationService = SystemNotificationService()

    // MARK: - Persisted Settings

    @Published public var settings: AppSettings {
        didSet {
            persistence.saveSettings(settings)
            let lang = AppLanguage(rawValue: settings.language) ?? .system
            LocalizationService.shared.setLanguage(lang)
            let newEffective = LocalizationService.shared.effectiveLanguage
            if effectiveLanguage != newEffective {
                effectiveLanguage = newEffective
            }
        }
    }

    @Published public var effectiveLanguage: String = "en"

    public nonisolated func localized(_ key: String) -> String {
        LocalizationService.shared.localized(key)
    }

    @Published public var isEnabled: Bool = true {
        didSet { settings.isEnabled = isEnabled }
    }
    @Published public var isCornerDialsEnabled: Bool = true {
        didSet { settings.isCornerDialsEnabled = isCornerDialsEnabled }
    }
    @Published public var isEdgeSlidersEnabled: Bool = true {
        didSet { settings.isEdgeSlidersEnabled = isEdgeSlidersEnabled }
    }
    @Published public var cornerSensitivityRadius: CGFloat = Defaults.HotCorner.defaultHitZoneSizePoints {
        didSet { settings.cornerSensitivityPoints = cornerSensitivityRadius }
    }
    @Published public var cornerDwellDelay: TimeInterval = Defaults.HotCorner.defaultDwellDelaySeconds {
        didSet { settings.cornerDwellDelaySeconds = cornerDwellDelay }
    }
    @Published public var isSoundEnabled: Bool = true {
        didSet { settings.isSoundEnabled = isSoundEnabled }
    }
    @Published public var soundVolume: Float = Defaults.Audio.defaultSoundVolume {
        didSet { settings.soundVolume = soundVolume }
    }
    @Published public var hapticIntensity: HapticIntensity = .medium {
        didSet { settings.hapticIntensity = hapticIntensity.rawValue.lowercased() }
    }

    @Published public var appProfiles: [AppProfile]
    @Published public var activeProfile: AppProfile

    // MARK: - Dynamic UI State

    @Published public var activeCorner: CornerPosition? = nil
    @Published public var activeDisplayID: CGDirectDisplayID = 0
    @Published public var isRightSliderActive: Bool = false
    @Published public var isAudioDevicePickerPresented: Bool = false

    // Pomodoro dynamic published properties
    @Published public var pomodoroRemainingSeconds: TimeInterval = TimeInterval(Defaults.Pomodoro.defaultFocusDurationSeconds)
    @Published public var pomodoroProgress: Double = 1.0
    @Published public var isPomodoroRunning: Bool = false

    private var cancellables = Set<AnyCancellable>()
    private var pomodoroTimer: Timer?
    private var lastValueNotch: Int = -1

    private init() {
        let loaded = persistence.loadSettings()
        self.settings = loaded

        let lang = AppLanguage(rawValue: loaded.language) ?? .system
        LocalizationService.shared.setLanguage(lang)
        self.effectiveLanguage = LocalizationService.shared.effectiveLanguage

        self.isEnabled = loaded.isEnabled
        self.isCornerDialsEnabled = loaded.isCornerDialsEnabled
        self.isEdgeSlidersEnabled = loaded.isEdgeSlidersEnabled
        self.cornerSensitivityRadius = loaded.cornerSensitivityPoints
        self.cornerDwellDelay = loaded.cornerDwellDelaySeconds
        self.isSoundEnabled = loaded.isSoundEnabled
        self.soundVolume = loaded.soundVolume
        self.hapticIntensity = HapticIntensity(rawValue: loaded.hapticIntensity.capitalized) ?? .medium

        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: "stash_appProfiles"),
           let decoded = try? JSONDecoder().decode([AppProfile].self, from: data),
           !decoded.isEmpty {
            self.appProfiles = decoded
            self.activeProfile = decoded.first(where: { $0.bundleIdentifier == nil }) ?? .defaultProfile
        } else {
            let defaultProf = AppProfile.defaultProfile
            self.appProfiles = [defaultProf]
            self.activeProfile = defaultProf
        }

        setupSubscribers()
        setupPomodoroTimer()
    }

    private func setupSubscribers() {
        profiles.$currentBundleId
            .sink { [weak self] bundleId in
                self?.evaluateActiveProfile(bundleId: bundleId)
            }
            .store(in: &cancellables)
    }

    private func evaluateActiveProfile(bundleId: String) {
        if let matching = appProfiles.first(where: { $0.bundleIdentifier == bundleId && $0.isEnabled }) {
            self.activeProfile = matching
        } else if let def = appProfiles.first(where: { $0.bundleIdentifier == nil }) {
            self.activeProfile = def
        }
    }

    private func setupPomodoroTimer() {
        pomodoroTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.tickPomodoro()
            }
        }
        if let t = pomodoroTimer {
            RunLoop.main.add(t, forMode: .common)
        }
    }

    private func tickPomodoro() {
        guard pomodoroEngine.state.isRunning else {
            isPomodoroRunning = false
            return
        }
        let tickResult = pomodoroEngine.tick()
        pomodoroRemainingSeconds = tickResult.remaining
        pomodoroProgress = tickResult.progress
        isPomodoroRunning = pomodoroEngine.state.isRunning

        if tickResult.didJustComplete {
            sound.playAccent(enabled: isSoundEnabled)
            haptics.performBoundaryClick()
            Task {
                await notificationService.deliverNotification(
                    title: "Pomodoro Completed",
                    body: "Time for a break!",
                    sound: settings.pomodoroSoundEnabled
                )
            }
        }
    }

    // MARK: - Action Mapping

    public func action(for corner: CornerPosition) -> ControlAction {
        if let isEnabled = settings.cornerEnabled[corner], !isEnabled {
            return .none
        }
        if let profileAction = activeProfile.cornerActions[corner] {
            return profileAction
        }
        return settings.cornerActions[corner] ?? .none
    }

    public func getValue(for action: ControlAction, displayID: CGDirectDisplayID = 0) -> Double {
        switch action {
        case .volume:
            return Double(audio.volume)
        case .brightness:
            let targetID = displayID != 0 ? displayID : (activeDisplayID != 0 ? activeDisplayID : CGMainDisplayID())
            let displays = brightnessService.queryConnectedDisplays()
            if let display = displays.first(where: { $0.id == targetID }) {
                if let profile = brightnessService.profile(for: display.uuid) {
                    return Double(profile.brightnessLevel)
                }
            }
            return Double(Defaults.Brightness.defaultLevel)
        case .keyboardBrightness:
            return Double(keyboard.brightness)
        case .timer:
            return pomodoroProgress
        case .none:
            return 0.0
        }
    }

    public func setValue(for action: ControlAction, value: Double, displayID: CGDirectDisplayID = 0) {
        let clamped = Float(max(0.0, min(1.0, value)))
        switch action {
        case .volume:
            audio.setVolume(clamped)
        case .brightness:
            let targetID = displayID != 0 ? displayID : (activeDisplayID != 0 ? activeDisplayID : CGMainDisplayID())
            let displays = brightnessService.queryConnectedDisplays()
            if let display = displays.first(where: { $0.id == targetID }) {
                var profile = brightnessService.profile(for: display.uuid) ?? DisplayBrightnessProfile(
                    displayUUID: display.uuid,
                    displayName: display.name,
                    brightnessLevel: clamped,
                    isBuiltIn: display.isBuiltIn
                )
                profile.brightnessLevel = clamped
                brightnessService.setProfile(profile)
                Task {
                    _ = await brightnessService.setBrightness(clamped, for: display)
                }
            }
        case .keyboardBrightness:
            keyboard.setBrightness(clamped)
        case .timer:
            let mins = max(1, Int(round(Double(clamped) * 60.0)))
            pomodoroEngine.start(durationSeconds: TimeInterval(mins * 60))
            pomodoroRemainingSeconds = pomodoroEngine.remainingSeconds
            pomodoroProgress = pomodoroEngine.progress
            isPomodoroRunning = pomodoroEngine.state.isRunning
        case .none:
            break
        }

        let notch = Int(clamped * 33.3)
        if notch != lastValueNotch {
            lastValueNotch = notch
            haptics.performDetentTick()
            sound.playTick(enabled: isSoundEnabled, volume: soundVolume)
        }
    }

    public func toggleAction(_ action: ControlAction, displayID: CGDirectDisplayID = 0) {
        switch action {
        case .volume:
            isAudioDevicePickerPresented.toggle()
            haptics.performBoundaryClick()
            sound.playAccent(enabled: isSoundEnabled)
        case .timer:
            if pomodoroEngine.state.isRunning {
                pomodoroEngine.pause()
            } else {
                pomodoroEngine.resume()
            }
            pomodoroRemainingSeconds = pomodoroEngine.remainingSeconds
            pomodoroProgress = pomodoroEngine.progress
            isPomodoroRunning = pomodoroEngine.state.isRunning
            haptics.performBoundaryClick()
            sound.playAccent(enabled: isSoundEnabled)
        case .brightness:
            let targetID = displayID != 0 ? displayID : (activeDisplayID != 0 ? activeDisplayID : CGMainDisplayID())
            let cur = getValue(for: .brightness, displayID: targetID)
            setValue(for: .brightness, value: cur > 0.5 ? 0.2 : 0.8, displayID: targetID)
            haptics.performBoundaryClick()
            sound.playAccent(enabled: isSoundEnabled)
        case .keyboardBrightness:
            let cur = keyboard.brightness
            setValue(for: .keyboardBrightness, value: cur > 0.5 ? 0.0 : 0.6)
            haptics.performBoundaryClick()
            sound.playAccent(enabled: isSoundEnabled)
        case .none:
            break
        }
    }

    public var formattedTimerTime: String {
        let total = Int(pomodoroRemainingSeconds)
        let mins = total / 60
        let secs = total % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    public func saveSettings() {
        persistence.saveSettings(settings)
        let defaults = UserDefaults.standard
        if let encodedProfiles = try? JSONEncoder().encode(appProfiles) {
            defaults.set(encodedProfiles, forKey: "stash_appProfiles")
        }
    }

    public func resetToDefaults() {
        let fresh = persistence.resetToDefaults()
        self.settings = fresh
        self.isEnabled = fresh.isEnabled
        self.isCornerDialsEnabled = fresh.isCornerDialsEnabled
        self.isEdgeSlidersEnabled = fresh.isEdgeSlidersEnabled
        self.cornerSensitivityRadius = fresh.cornerSensitivityPoints
        self.cornerDwellDelay = fresh.cornerDwellDelaySeconds
        self.isSoundEnabled = fresh.isSoundEnabled
        self.soundVolume = fresh.soundVolume
        self.hapticIntensity = HapticIntensity(rawValue: fresh.hapticIntensity.capitalized) ?? .medium
    }
}
