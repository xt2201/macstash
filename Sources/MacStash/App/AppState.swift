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
            applyPomodoroSettings()
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
    @Published public var onlyOuterCorners: Bool = false {
        didSet { settings.onlyOuterCorners = onlyOuterCorners }
    }
    @Published public var scrollAdjustmentEnabled: Bool = true {
        didSet { settings.scrollAdjustmentEnabled = scrollAdjustmentEnabled }
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
    @Published public var isPomodoroPaused: Bool = false
    @Published public var pomodoroMode: PomodoroMode = .focus
    @Published public var pomodoroCompletedRounds: Int = 0
    @Published public var pomodoroTotalRounds: Int = Defaults.Pomodoro.defaultRoundsBeforeLongBreak

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
        self.onlyOuterCorners = loaded.onlyOuterCorners
        self.scrollAdjustmentEnabled = loaded.scrollAdjustmentEnabled
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

        applyPomodoroSettings()
        restorePomodoroSnapshot()
        syncPomodoroProperties()

        for (_, profile) in loaded.displayBrightnessProfiles {
            brightnessService.setProfile(profile)
        }

        setupSubscribers()
        setupPomodoroTimer()
        setupSystemWakeObserver()
    }

    private func setupSubscribers() {
        profiles.$currentBundleId
            .sink { [weak self] bundleId in
                self?.evaluateActiveProfile(bundleId: bundleId)
            }
            .store(in: &cancellables)

        keyboard.objectWillChange
            .sink { [weak self] in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        audio.objectWillChange
            .sink { [weak self] in
                self?.objectWillChange.send()
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

    private func setupSystemWakeObserver() {
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.screensDidWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.tickPomodoro()
            }
        }
    }

    public func applyPomodoroSettings() {
        pomodoroEngine.configure(
            focusDurationSeconds: TimeInterval(settings.pomodoroFocusDurationMinutes * 60),
            shortBreakDurationSeconds: TimeInterval(settings.pomodoroShortBreakMinutes * 60),
            longBreakDurationSeconds: TimeInterval(settings.pomodoroLongBreakMinutes * 60),
            roundsBeforeLongBreak: settings.pomodoroRoundsBeforeLongBreak,
            autoStartBreaks: settings.pomodoroAutoStartBreaks
        )
        self.pomodoroTotalRounds = settings.pomodoroRoundsBeforeLongBreak
        if case .idle = pomodoroEngine.state {
            syncPomodoroProperties()
        }
    }

    public func syncPomodoroProperties() {
        pomodoroRemainingSeconds = pomodoroEngine.remainingSeconds
        pomodoroProgress = pomodoroEngine.progress
        isPomodoroRunning = pomodoroEngine.state.isRunning
        isPomodoroPaused = pomodoroEngine.state.isPaused
        pomodoroMode = pomodoroEngine.mode
        pomodoroCompletedRounds = pomodoroEngine.completedRounds
        pomodoroTotalRounds = pomodoroEngine.roundsBeforeLongBreak
    }

    public func savePomodoroSnapshot() {
        let snap = pomodoroEngine.createSnapshot()
        if let encoded = try? JSONEncoder().encode(snap) {
            UserDefaults.standard.set(encoded, forKey: "stash_pomodoroSnapshot")
        }
    }

    public func restorePomodoroSnapshot() {
        if let data = UserDefaults.standard.data(forKey: "stash_pomodoroSnapshot"),
           let snapshot = try? JSONDecoder().decode(PomodoroSnapshot.self, from: data) {
            _ = pomodoroEngine.restore(from: snapshot)
        }
    }

    public func togglePomodoro() {
        if pomodoroEngine.state.isRunning {
            pomodoroEngine.pause()
        } else {
            pomodoroEngine.resume()
        }
        syncPomodoroProperties()
        savePomodoroSnapshot()
        haptics.performBoundaryClick()
        sound.playAccent(enabled: isSoundEnabled)
    }

    public func resetPomodoro(toDurationSeconds duration: TimeInterval? = nil) {
        pomodoroEngine.reset(toDurationSeconds: duration)
        syncPomodoroProperties()
        savePomodoroSnapshot()
        haptics.performBoundaryClick()
        sound.playAccent(enabled: isSoundEnabled)
    }

    public func skipPomodoroMode() {
        pomodoroEngine.skipToNextMode()
        syncPomodoroProperties()
        savePomodoroSnapshot()
        haptics.performBoundaryClick()
        sound.playAccent(enabled: isSoundEnabled)
    }

    public func setPomodoroMode(_ mode: PomodoroMode) {
        pomodoroEngine.setMode(mode)
        syncPomodoroProperties()
        savePomodoroSnapshot()
    }

    public func updateDisplayProfile(_ profile: DisplayBrightnessProfile) {
        brightnessService.setProfile(profile)
        settings.displayBrightnessProfiles[profile.displayUUID] = profile
    }

    private func tickPomodoro() {
        guard pomodoroEngine.state.isRunning else {
            isPomodoroRunning = false
            return
        }
        let tickResult = pomodoroEngine.tick()
        syncPomodoroProperties()

        if tickResult.didJustComplete {
            if settings.pomodoroSoundEnabled {
                sound.playChime(enabled: isSoundEnabled)
                haptics.performBoundaryClick()
            }
            NSApp.requestUserAttention(.criticalRequest)
            savePomodoroSnapshot()

            let completedMode = tickResult.completedMode ?? .focus
            let titleKey: String
            let bodyKey: String
            switch completedMode {
            case .focus:
                titleKey = "pomodoro.notifyBreakTitle"
                bodyKey = "pomodoro.notifyBreakBody"
            case .shortBreak, .longBreak:
                titleKey = "pomodoro.notifyFocusTitle"
                bodyKey = "pomodoro.notifyFocusBody"
            }

            let title = localized(titleKey)
            let body = localized(bodyKey)

            Task {
                await notificationService.deliverNotification(
                    title: title,
                    body: body,
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
            if pomodoroEngine.state.isRunning || isPomodoroPaused {
                return pomodoroProgress
            } else {
                let mins: Double
                switch pomodoroEngine.mode {
                case .focus:
                    mins = Double(settings.pomodoroFocusDurationMinutes)
                case .shortBreak:
                    mins = Double(settings.pomodoroShortBreakMinutes)
                case .longBreak:
                    mins = Double(settings.pomodoroLongBreakMinutes)
                }
                return max(0.02, min(1.0, mins / 60.0))
            }
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
                updateDisplayProfile(profile)
                Task {
                    _ = await brightnessService.setBrightness(clamped, for: display)
                }
            }
        case .keyboardBrightness:
            keyboard.setBrightness(clamped)
        case .timer:
            // When timer is not running, dial adjusts session duration (1 to 60 mins)
            if !pomodoroEngine.state.isRunning {
                let mins = max(1, min(60, Int(round(Double(clamped) * 60.0))))
                let dur = TimeInterval(mins * 60)
                switch pomodoroEngine.mode {
                case .focus:
                    settings.pomodoroFocusDurationMinutes = mins
                case .shortBreak:
                    settings.pomodoroShortBreakMinutes = mins
                case .longBreak:
                    settings.pomodoroLongBreakMinutes = mins
                }
                pomodoroEngine.reset(toDurationSeconds: dur)
                syncPomodoroProperties()
                savePomodoroSnapshot()
            }
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
            togglePomodoro()
        case .brightness:
            let targetID = displayID != 0 ? displayID : (activeDisplayID != 0 ? activeDisplayID : CGMainDisplayID())
            let cur = getValue(for: .brightness, displayID: targetID)
            setValue(for: .brightness, value: cur > 0.5 ? 0.2 : 0.8, displayID: targetID)
            haptics.performBoundaryClick()
            sound.playAccent(enabled: isSoundEnabled)
        case .keyboardBrightness:
            let next = KeyboardBrightnessPolicy.toggle(current: keyboard.brightness)
            setValue(for: .keyboardBrightness, value: Double(next))
            haptics.performBoundaryClick()
            sound.playAccent(enabled: isSoundEnabled)
        case .none:
            break
        }
    }

    public var formattedTimerTime: String {
        let total = max(0, Int(round(pomodoroRemainingSeconds)))
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
        self.onlyOuterCorners = fresh.onlyOuterCorners
        self.scrollAdjustmentEnabled = fresh.scrollAdjustmentEnabled
        self.cornerSensitivityRadius = fresh.cornerSensitivityPoints
        self.cornerDwellDelay = fresh.cornerDwellDelaySeconds
        self.isSoundEnabled = fresh.isSoundEnabled
        self.soundVolume = fresh.soundVolume
        self.hapticIntensity = HapticIntensity(rawValue: fresh.hapticIntensity.capitalized) ?? .medium
    }
}
