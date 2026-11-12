import SwiftUI
import Combine
import CoreGraphics
import MacStashCore
import SideDockCore
import SideDockWidgets
import SideDockUI
import SideDockSystem

@MainActor
public final class AppState: ObservableObject {
    public static let shared = AppState()

    // Domain & Hardware Services
    public let audio = AudioManager.shared
    public let nowPlaying = NowPlayingManager.shared
    public let keyboard = KeyboardBrightnessManager.shared
    public let keepAwake = KeepAwakeManager.shared
    public let stashShelf = StashShelfManager.shared
    public let scratchpad = ScratchpadManager.shared
    public let updater = AutoUpdateManager.shared
    public let profiles = AppProfileManager.shared
    public let haptics = HapticManager.shared
    public let sound = SoundEffectManager.shared
    public let sideDock = SideDockManager.shared

    public let persistence = SettingsPersistenceService()
    public let brightnessService = CompositeBrightnessService()
    public let pomodoroEngine = PomodoroEngine()
    public let notificationService = SystemNotificationService()

    // MARK: - Persisted Settings

    private var isSyncingSettings: Bool = false

    @Published public var settings: AppSettings {
        didSet {
            scheduleSaveSettings()
            let lang = AppLanguage(rawValue: settings.language) ?? .system
            LocalizationService.shared.setLanguage(lang)
            let newEffective = LocalizationService.shared.effectiveLanguage
            if effectiveLanguage != newEffective {
                effectiveLanguage = newEffective
            }
            applyPomodoroSettings()
            syncMirroredProperties(from: oldValue)
        }
    }

    private func syncMirroredProperties(from old: AppSettings) {
        guard !isSyncingSettings else { return }
        isSyncingSettings = true
        defer { isSyncingSettings = false }

        if isEnabled != settings.isEnabled { isEnabled = settings.isEnabled }
        if isCornerDialsEnabled != settings.isCornerDialsEnabled { isCornerDialsEnabled = settings.isCornerDialsEnabled }
        if isEdgeSlidersEnabled != settings.isEdgeSlidersEnabled { isEdgeSlidersEnabled = settings.isEdgeSlidersEnabled }
        if edgeBarShowMediaControls != settings.edgeBarShowMediaControls { edgeBarShowMediaControls = settings.edgeBarShowMediaControls }
        if edgeBarVisualizerEnabled != settings.edgeBarVisualizerEnabled { edgeBarVisualizerEnabled = settings.edgeBarVisualizerEnabled }
        if onlyOuterCorners != settings.onlyOuterCorners { onlyOuterCorners = settings.onlyOuterCorners }
        if cornerDisplayTarget != settings.cornerDisplayTarget { cornerDisplayTarget = settings.cornerDisplayTarget }
        if scrollAdjustmentEnabled != settings.scrollAdjustmentEnabled { scrollAdjustmentEnabled = settings.scrollAdjustmentEnabled }
        if cornerSensitivityRadius != settings.cornerSensitivityPoints { cornerSensitivityRadius = settings.cornerSensitivityPoints }
        if cornerDwellDelay != settings.cornerDwellDelaySeconds { cornerDwellDelay = settings.cornerDwellDelaySeconds }
        if edgeSliderPlacement != settings.edgeSliderPlacement { edgeSliderPlacement = settings.edgeSliderPlacement }
        if edgeSliderPosition != settings.edgeSliderPosition { edgeSliderPosition = settings.edgeSliderPosition }
        if drawerEdgePosition != settings.drawerEdgePosition { drawerEdgePosition = settings.drawerEdgePosition }
        if isSoundEnabled != settings.isSoundEnabled { isSoundEnabled = settings.isSoundEnabled }
        if soundVolume != settings.soundVolume { soundVolume = settings.soundVolume }
        let parsedHaptic = HapticIntensity(rawValue: settings.hapticIntensity.capitalized) ?? .medium
        if hapticIntensity != parsedHaptic { hapticIntensity = parsedHaptic }

        let overlayLayoutChanged = old.dialRadiusPoints != settings.dialRadiusPoints
            || old.isEdgeSlidersEnabled != settings.isEdgeSlidersEnabled
            || old.isStashShelfEnabled != settings.isStashShelfEnabled
            || old.isScratchpadEnabled != settings.isScratchpadEnabled
            || old.onlyOuterCorners != settings.onlyOuterCorners
            || old.edgeSliderPlacement != settings.edgeSliderPlacement
            || old.edgeSliderPosition != settings.edgeSliderPosition
            || old.drawerEdgePosition != settings.drawerEdgePosition

        if overlayLayoutChanged {
            ScreenManager.shared.reconfigureOverlays()
        }
    }

    public var resolvedColorScheme: ColorScheme? {
        switch settings.appearanceTheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    public var effectiveHapticIntensity: HapticIntensity {
        settings.hapticFeedbackEnabled ? hapticIntensity : .off
    }

    public var hasDrawerFeatureActive: Bool {
        settings.isStashShelfEnabled || settings.isScratchpadEnabled
            || settings.cornerActions.values.contains(.stashShelf)
            || settings.cornerActions.values.contains(.scratchpad)
            || activeProfile.cornerActions.values.contains(.stashShelf)
            || activeProfile.cornerActions.values.contains(.scratchpad)
            || activeProfile.leftEdgeAction == .stashShelf
            || activeProfile.leftEdgeAction == .scratchpad
            || activeProfile.rightEdgeAction == .stashShelf
            || activeProfile.rightEdgeAction == .scratchpad
            || stashShelf.isShelfOpen
            || scratchpad.isScratchpadOpen
    }

    private func scheduleSaveSettings() {
        settingsSaveWorkItem?.cancel()
        let item = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.persistence.saveSettings(self.settings)
        }
        settingsSaveWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: item)
    }

    @Published public var effectiveLanguage: String = "en"

    public nonisolated func localized(_ key: String) -> String {
        LocalizationService.shared.localized(key)
    }

    @Published public var isEnabled: Bool = true {
        didSet { if !isSyncingSettings { settings.isEnabled = isEnabled } }
    }
    @Published public var isCornerDialsEnabled: Bool = true {
        didSet { if !isSyncingSettings { settings.isCornerDialsEnabled = isCornerDialsEnabled } }
    }
    @Published public var isEdgeSlidersEnabled: Bool = true {
        didSet {
            if !isSyncingSettings {
                settings.isEdgeSlidersEnabled = isEdgeSlidersEnabled
                if isEdgeSlidersEnabled && edgeSliderPlacement == .none {
                    edgeSliderPlacement = .both
                }
            }
        }
    }
    @Published public var edgeBarShowMediaControls: Bool = true {
        didSet { if !isSyncingSettings { settings.edgeBarShowMediaControls = edgeBarShowMediaControls } }
    }
    @Published public var edgeBarVisualizerEnabled: Bool = true {
        didSet { if !isSyncingSettings { settings.edgeBarVisualizerEnabled = edgeBarVisualizerEnabled } }
    }
    @Published public var onlyOuterCorners: Bool = false {
        didSet { if !isSyncingSettings { settings.onlyOuterCorners = onlyOuterCorners } }
    }
    @Published public var cornerDisplayTarget: HotCornerDisplayTarget = .builtIn {
        didSet { if !isSyncingSettings { settings.cornerDisplayTarget = cornerDisplayTarget } }
    }
    @Published public var scrollAdjustmentEnabled: Bool = true {
        didSet { if !isSyncingSettings { settings.scrollAdjustmentEnabled = scrollAdjustmentEnabled } }
    }
    @Published public var cornerSensitivityRadius: CGFloat = Defaults.HotCorner.defaultHitZoneSizePoints {
        didSet { if !isSyncingSettings { settings.cornerSensitivityPoints = cornerSensitivityRadius } }
    }
    @Published public var cornerDwellDelay: TimeInterval = Defaults.HotCorner.defaultDwellDelaySeconds {
        didSet { if !isSyncingSettings { settings.cornerDwellDelaySeconds = cornerDwellDelay } }
    }
    @Published public var edgeSliderPlacement: EdgeSliderPlacement = .both {
        didSet {
            if !isSyncingSettings {
                settings.edgeSliderPlacement = edgeSliderPlacement
            }
        }
    }
    @Published public var edgeSliderPosition: EdgePosition = Defaults.EdgeSliders.defaultPosition {
        didSet {
            if !isSyncingSettings {
                settings.edgeSliderPosition = edgeSliderPosition
            }
        }
    }
    @Published public var drawerEdgePosition: EdgePosition = Defaults.LeftEdgeDrawer.defaultPosition {
        didSet {
            if !isSyncingSettings {
                settings.drawerEdgePosition = drawerEdgePosition
            }
        }
    }
    @Published public var isSoundEnabled: Bool = true {
        didSet { if !isSyncingSettings { settings.isSoundEnabled = isSoundEnabled } }
    }
    @Published public var soundVolume: Float = Defaults.Audio.defaultSoundVolume {
        didSet { if !isSyncingSettings { settings.soundVolume = soundVolume } }
    }
    @Published public var hapticIntensity: HapticIntensity = .medium {
        didSet { if !isSyncingSettings { settings.hapticIntensity = hapticIntensity.rawValue.lowercased() } }
    }

    @Published public var appProfiles: [AppProfile]
    @Published public var activeProfile: AppProfile

    // MARK: - Dynamic UI State

    @Published public var activeCorner: CornerPosition? = nil
    @Published public var activeDisplayID: CGDirectDisplayID = 0
    @Published public var isLeftSliderActive: Bool = false
    @Published public var isRightSliderActive: Bool = false
    @Published public var liveLeftSliderValue: Float? = nil
    @Published public var liveRightSliderValue: Float? = nil
    public var liveEdgeSliderValue: Float? {
        get { liveRightSliderValue ?? liveLeftSliderValue }
        set {
            liveRightSliderValue = newValue
            liveLeftSliderValue = newValue
        }
    }
    @Published public var isAudioDevicePickerPresented: Bool = false
    @Published public var isCursorPalettePresented: Bool = false
    @Published public var requestedSettingsTab: String? = nil

    private var cachedDisplays: [DisplayInfo] = []
    private var settingsSaveWorkItem: DispatchWorkItem?

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
    private var hardwareSyncTimer: Timer?
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
        self.edgeBarShowMediaControls = loaded.edgeBarShowMediaControls
        self.edgeBarVisualizerEnabled = loaded.edgeBarVisualizerEnabled
        self.onlyOuterCorners = loaded.onlyOuterCorners
        self.cornerDisplayTarget = loaded.cornerDisplayTarget
        self.scrollAdjustmentEnabled = loaded.scrollAdjustmentEnabled
        self.cornerSensitivityRadius = loaded.cornerSensitivityPoints
        self.cornerDwellDelay = loaded.cornerDwellDelaySeconds
        self.isSoundEnabled = loaded.isSoundEnabled
        self.soundVolume = loaded.soundVolume
        self.edgeSliderPlacement = loaded.edgeSliderPlacement
        self.edgeSliderPosition = loaded.edgeSliderPosition
        self.drawerEdgePosition = loaded.drawerEdgePosition
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
        self.cachedDisplays = brightnessService.queryConnectedDisplays()

        setupSubscribers()
        setupPomodoroTimer()
        setupSystemWakeObserver()
        setupHardwareSyncTimer()

        sideDock.onOpenSettings = { [weak self] in
            self?.requestedSettingsTab = "Second Dock"
        }
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
        let target = bundleId.lowercased()
        if let matching = appProfiles.first(where: { ($0.bundleIdentifier?.lowercased() == target) && $0.isEnabled }) {
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
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.cachedDisplays = self.brightnessService.queryConnectedDisplays()
            }
        }
    }

    public func connectedDisplays(forceRefresh: Bool = false) -> [DisplayInfo] {
        if forceRefresh || cachedDisplays.isEmpty {
            cachedDisplays = brightnessService.queryConnectedDisplays()
        }
        return cachedDisplays
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
        haptics.performBoundaryClick(intensity: effectiveHapticIntensity)
        sound.playAccent(enabled: isSoundEnabled)
    }

    public func resetPomodoro(toDurationSeconds duration: TimeInterval? = nil) {
        pomodoroEngine.reset(toDurationSeconds: duration)
        syncPomodoroProperties()
        savePomodoroSnapshot()
        haptics.performBoundaryClick(intensity: effectiveHapticIntensity)
        sound.playAccent(enabled: isSoundEnabled)
    }

    public func resetPomodoroRounds() {
        pomodoroEngine.resetRounds()
        syncPomodoroProperties()
        savePomodoroSnapshot()
    }

    public func skipPomodoroMode() {
        pomodoroEngine.skipToNextMode()
        syncPomodoroProperties()
        savePomodoroSnapshot()
        haptics.performBoundaryClick(intensity: effectiveHapticIntensity)
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
                haptics.performBoundaryClick(intensity: effectiveHapticIntensity)
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

    private func setupHardwareSyncTimer() {
        hardwareSyncTimer?.invalidate()
        let t = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.syncHardwareState(force: false)
            }
        }
        RunLoop.main.add(t, forMode: .common)
        self.hardwareSyncTimer = t
    }

    public func syncHardwareState(force: Bool = false) {
        audio.updateVolumeFromHardware(force: force)
        keyboard.updateBrightnessFromHardware()
        let displays = connectedDisplays()
        for d in displays {
            let old = brightnessService.profile(for: d.uuid)?.brightnessLevel
            let live = brightnessService.syncHardwareBrightness(for: d)
            if let old = old, abs(old - live) > 0.005 {
                objectWillChange.send()
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
            let displays = connectedDisplays()
            if let display = displays.first(where: { $0.id == targetID }) {
                return Double(brightnessService.readBrightnessLevel(for: display))
            }
            return Double(Defaults.Brightness.defaultLevel)
        case .keyboardBrightness:
            return Double(keyboard.currentHardwareBrightness() ?? keyboard.brightness)
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
        case .keepAwake:
            return keepAwake.dialProgress
        case .stashShelf:
            return min(1.0, Double(stashShelf.items.count) / 10.0)
        case .scratchpad:
            return scratchpad.text.isEmpty ? 0.0 : 1.0
        case .mediaPlayback:
            return Double(nowPlaying.progressFraction)
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
            let bounded = BrightnessPolicy.clamp(clamped, min: settings.minBrightnessClamp, max: settings.maxBrightnessClamp)
            let targetID = displayID != 0 ? displayID : (activeDisplayID != 0 ? activeDisplayID : CGMainDisplayID())
            let displays = connectedDisplays()
            if let display = displays.first(where: { $0.id == targetID }) {
                var profile = brightnessService.profile(for: display.uuid) ?? DisplayBrightnessProfile(
                    displayUUID: display.uuid,
                    displayName: display.name,
                    brightnessLevel: bounded,
                    isBuiltIn: display.isBuiltIn
                )
                profile.brightnessLevel = bounded
                updateDisplayProfile(profile)
                Task {
                    _ = await brightnessService.setBrightness(bounded, for: display)
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
        case .keepAwake:
            keepAwake.setFromDialProgress(Double(clamped))
        case .mediaPlayback:
            nowPlaying.seekToProgress(fraction: Double(clamped))
        case .stashShelf, .scratchpad, .none:
            break
        }

        let notch = Int(clamped * 33.3)
        if notch != lastValueNotch {
            lastValueNotch = notch
            haptics.performDetentTick(intensity: effectiveHapticIntensity)
            sound.playTick(enabled: isSoundEnabled, volume: soundVolume)
        }
    }

    public func toggleAction(_ action: ControlAction, displayID: CGDirectDisplayID = 0) {
        switch action {
        case .volume:
            audio.toggleMute()
            haptics.performBoundaryClick(intensity: effectiveHapticIntensity)
            sound.playAccent(enabled: isSoundEnabled)
        case .timer:
            togglePomodoro()
        case .brightness:
            let targetID = displayID != 0 ? displayID : (activeDisplayID != 0 ? activeDisplayID : CGMainDisplayID())
            let cur = getValue(for: .brightness, displayID: targetID)
            setValue(for: .brightness, value: cur > 0.5 ? max(0.2, Double(settings.minBrightnessClamp)) : min(0.8, Double(settings.maxBrightnessClamp)), displayID: targetID)
            haptics.performBoundaryClick(intensity: effectiveHapticIntensity)
            sound.playAccent(enabled: isSoundEnabled)
        case .keyboardBrightness:
            let current = Float(getValue(for: .keyboardBrightness))
            let next = KeyboardBrightnessPolicy.toggle(current: current)
            setValue(for: .keyboardBrightness, value: Double(next))
            haptics.performBoundaryClick(intensity: effectiveHapticIntensity)
            sound.playAccent(enabled: isSoundEnabled)
        case .keepAwake:
            keepAwake.toggle(defaultMinutes: settings.keepAwakeDefaultMinutes)
            haptics.performBoundaryClick(intensity: effectiveHapticIntensity)
            sound.playAccent(enabled: isSoundEnabled)
        case .stashShelf:
            if !settings.isStashShelfEnabled {
                settings.isStashShelfEnabled = true
                ScreenManager.shared.reconfigureOverlays()
            }
            stashShelf.isShelfOpen.toggle()
            if stashShelf.isShelfOpen {
                scratchpad.isScratchpadOpen = false
            }
            haptics.performBoundaryClick(intensity: effectiveHapticIntensity)
            sound.playAccent(enabled: isSoundEnabled)
        case .scratchpad:
            if !settings.isScratchpadEnabled {
                settings.isScratchpadEnabled = true
                ScreenManager.shared.reconfigureOverlays()
            }
            scratchpad.isScratchpadOpen.toggle()
            if scratchpad.isScratchpadOpen {
                stashShelf.closeShelf()
            }
            haptics.performBoundaryClick(intensity: effectiveHapticIntensity)
            sound.playAccent(enabled: isSoundEnabled)
        case .mediaPlayback:
            nowPlaying.togglePlayPause()
            haptics.performBoundaryClick(intensity: effectiveHapticIntensity)
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
        let defaultProf = AppProfile.defaultProfile
        self.appProfiles = [defaultProf]
        self.activeProfile = defaultProf
        UserDefaults.standard.removeObject(forKey: "stash_appProfiles")
        self.settings = fresh
        ScreenManager.shared.reconfigureOverlays()
    }
}
