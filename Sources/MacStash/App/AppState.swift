import SwiftUI
import Combine

/// Central observable state manager for MacStash v2
public final class AppState: ObservableObject {
    public static let shared = AppState()

    // Sub-managers
    public let audio = AudioManager.shared
    public let brightness = BrightnessManager.shared
    public let keyboard = KeyboardBrightnessManager.shared
    public let timer = FocusTimerManager.shared
    public let updater = AutoUpdateManager.shared
    public let appearance = AppearanceManager.shared
    public let profiles = AppProfileManager.shared
    public let haptics = HapticManager.shared
    public let sound = SoundEffectManager.shared
    public let appManager = InstalledAppsManager.shared

    // MARK: - User Settings (Persisted)

    @Published public var isEnabled: Bool {
        didSet { saveSettings() }
    }
    @Published public var isCornerDialsEnabled: Bool {
        didSet { saveSettings() }
    }
    @Published public var isEdgeSlidersEnabled: Bool {
        didSet { saveSettings() }
    }
    @Published public var isHiddenDockEnabled: Bool {
        didSet { saveSettings() }
    }
    @Published public var cornerSensitivityRadius: CGFloat {
        didSet { saveSettings() }
    }
    @Published public var cornerDwellDelay: TimeInterval {
        didSet { saveSettings() }
    }
    @Published public var hapticIntensity: HapticIntensity {
        didSet { saveSettings() }
    }
    @Published public var isSoundEnabled: Bool {
        didSet { saveSettings() }
    }
    @Published public var soundVolume: Float {
        didSet { saveSettings() }
    }
    @Published public var dockPosition: EdgePosition {
        didSet { saveSettings() }
    }
    @Published public var dockItems: [DockItem] {
        didSet { saveSettings() }
    }
    @Published public var appProfiles: [AppProfile] {
        didSet { saveSettings() }
    }
    @Published public var activeProfile: AppProfile

    // MARK: - Dynamic UI State (Transient)

    @Published public var activeCorner: CornerPosition? = nil
    @Published public var isDockExpanded: Bool = false
    @Published public var isRightSliderActive: Bool = false
    @Published public var isQuickLauncherPresented: Bool = false
    @Published public var isAudioDevicePickerPresented: Bool = false

    private var cancellables = Set<AnyCancellable>()
    private var lastValueNotch: Int = -1

    private init() {
        let defaults = UserDefaults.standard

        self.isEnabled = defaults.object(forKey: "stash_isEnabled") as? Bool ?? true
        self.isCornerDialsEnabled = defaults.object(forKey: "stash_cornersEnabled") as? Bool ?? true
        self.isEdgeSlidersEnabled = defaults.object(forKey: "stash_slidersEnabled") as? Bool ?? true
        self.isHiddenDockEnabled = defaults.object(forKey: "stash_dockEnabled") as? Bool ?? true

        // Corner sensitivity (tight hot zone: default 8px)
        self.cornerSensitivityRadius = defaults.object(forKey: "stash_sensitivity") as? CGFloat ?? 8.0
        self.cornerDwellDelay = defaults.object(forKey: "stash_dwellDelay") as? TimeInterval ?? 0.08

        let hapticRaw = defaults.string(forKey: "stash_hapticIntensity") ?? HapticIntensity.medium.rawValue
        self.hapticIntensity = HapticIntensity(rawValue: hapticRaw) ?? .medium

        self.isSoundEnabled = defaults.object(forKey: "stash_soundEnabled") as? Bool ?? true
        self.soundVolume = defaults.object(forKey: "stash_soundVolume") as? Float ?? 0.6

        let dockPosRaw = defaults.string(forKey: "stash_dockPosition") ?? EdgePosition.left.rawValue
        self.dockPosition = EdgePosition(rawValue: dockPosRaw) ?? .left

        // Load dock items or use starter apps
        if let data = defaults.data(forKey: "stash_dockItems"),
           let decoded = try? JSONDecoder().decode([DockItem].self, from: data) {
            self.dockItems = decoded
        } else {
            self.dockItems = InstalledAppsManager.defaultDockItems
        }

        // Load profiles
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
            DispatchQueue.main.async {
                self.activeProfile = matching
            }
        } else if let def = appProfiles.first(where: { $0.bundleIdentifier == nil }) {
            DispatchQueue.main.async {
                self.activeProfile = def
            }
        }
    }

    // MARK: - Action Resolvers & Handlers

    public func action(for corner: CornerPosition) -> ControlAction {
        activeProfile.cornerActions[corner] ?? .none
    }

    public func getValue(for action: ControlAction) -> Float {
        switch action {
        case .volume:
            return audio.isMuted ? 0.0 : audio.volume
        case .brightness:
            return brightness.brightness
        case .keyboardBrightness:
            return keyboard.brightness
        case .timer:
            return Float(timer.progress)
        case .none:
            return 0.0
        }
    }

    public func setValue(for action: ControlAction, value: Float) {
        let clamped = max(0.0, min(1.0, value))
        switch action {
        case .volume:
            audio.setVolume(clamped)
        case .brightness:
            brightness.setBrightness(clamped)
        case .keyboardBrightness:
            keyboard.setBrightness(clamped)
        case .timer:
            timer.setFraction(Double(clamped))
        case .none:
            break
        }

        // Trigger detent tick for every 3% step
        let notch = Int(clamped * 33.3)
        if notch != lastValueNotch {
            lastValueNotch = notch
            haptics.performDetentTick(intensity: hapticIntensity)
            sound.playTick(enabled: isSoundEnabled, volume: soundVolume)
        }
    }

    public func adjustValue(for action: ControlAction, delta: Float) {
        let current = getValue(for: action)
        setValue(for: action, value: current + delta)
    }

    public func toggleAction(_ action: ControlAction) {
        switch action {
        case .volume:
            // Center tap opens Audio Device switcher or toggles mute
            isAudioDevicePickerPresented.toggle()
            haptics.performBoundaryClick(intensity: hapticIntensity)
            sound.playAccent(enabled: isSoundEnabled)
        case .timer:
            // Toggle play/pause
            timer.togglePlayPause()
            haptics.performBoundaryClick(intensity: hapticIntensity)
            sound.playAccent(enabled: isSoundEnabled)
        case .brightness:
            let cur = brightness.brightness
            setValue(for: .brightness, value: cur > 0.5 ? 0.2 : 0.8)
            haptics.performBoundaryClick(intensity: hapticIntensity)
            sound.playAccent(enabled: isSoundEnabled)
        case .keyboardBrightness:
            let cur = keyboard.brightness
            setValue(for: .keyboardBrightness, value: cur > 0.5 ? 0.0 : 0.6)
            haptics.performBoundaryClick(intensity: hapticIntensity)
            sound.playAccent(enabled: isSoundEnabled)
        case .none:
            break
        }
    }

    // MARK: - Persistence

    public func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(isEnabled, forKey: "stash_isEnabled")
        defaults.set(isCornerDialsEnabled, forKey: "stash_cornersEnabled")
        defaults.set(isEdgeSlidersEnabled, forKey: "stash_slidersEnabled")
        defaults.set(isHiddenDockEnabled, forKey: "stash_dockEnabled")
        defaults.set(cornerSensitivityRadius, forKey: "stash_sensitivity")
        defaults.set(cornerDwellDelay, forKey: "stash_dwellDelay")
        defaults.set(hapticIntensity.rawValue, forKey: "stash_hapticIntensity")
        defaults.set(isSoundEnabled, forKey: "stash_soundEnabled")
        defaults.set(soundVolume, forKey: "stash_soundVolume")
        defaults.set(dockPosition.rawValue, forKey: "stash_dockPosition")

        if let encodedDock = try? JSONEncoder().encode(dockItems) {
            defaults.set(encodedDock, forKey: "stash_dockItems")
        }
        if let encodedProfiles = try? JSONEncoder().encode(appProfiles) {
            defaults.set(encodedProfiles, forKey: "stash_appProfiles")
        }
    }
}
