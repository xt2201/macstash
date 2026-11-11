import Foundation
import Combine
import MacStashCore

/// Manages the Keep Awake (Caffeine) power assertion, countdown and display label.
@MainActor
public final class KeepAwakeManager: ObservableObject {
    public static let shared = KeepAwakeManager()

    public let service = PowerAssertionService()

    @Published public private(set) var isActive: Bool = false
    @Published public private(set) var remainingSeconds: TimeInterval = 0
    @Published public private(set) var durationMinutes: Int = 0
    @Published public private(set) var formattedRemaining: String = "OFF"

    private var countdownTimer: Timer?

    private init() {}

    public func activate(minutes: Int) {
        if service.activate(minutes: minutes) {
            startTimer()
            syncState()
            AppLogger.lifecycle.info("KeepAwake activated for \(minutes) minutes")
        }
    }

    public func deactivate() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        service.deactivate()
        syncState()
        AppLogger.lifecycle.info("KeepAwake deactivated")
    }

    public func toggle(defaultMinutes: Int = Defaults.KeepAwake.defaultDurationMinutes) {
        if isActive {
            deactivate()
        } else {
            activate(minutes: defaultMinutes)
        }
    }

    /// Maps dial progress to presets: <0.1 off, 15m, 30m, 60m, 120m, >=0.9 indefinite.
    public func setFromDialProgress(_ progress: Double) {
        let p = max(0.0, min(1.0, progress))
        let target: Int
        switch p {
        case ..<0.1: target = 0
        case ..<0.3: target = 15
        case ..<0.5: target = 30
        case ..<0.7: target = 60
        case ..<0.9: target = 120
        default: target = -1
        }
        if target == 0 {
            if isActive { deactivate() }
        } else if !isActive || durationMinutes != target {
            activate(minutes: target)
        }
    }

    public var dialProgress: Double {
        guard isActive else { return 0.0 }
        if durationMinutes < 0 { return 1.0 }
        switch durationMinutes {
        case 1...15: return 0.2
        case 16...30: return 0.4
        case 31...60: return 0.6
        case 61...120: return 0.8
        default: return 1.0
        }
    }

    private func startTimer() {
        countdownTimer?.invalidate()
        let t = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.handleTick() }
        }
        RunLoop.main.add(t, forMode: .common)
        countdownTimer = t
    }

    private func handleTick() {
        if !service.tick() {
            countdownTimer?.invalidate()
            countdownTimer = nil
        }
        syncState()
    }

    private func syncState() {
        isActive = service.isActive
        durationMinutes = service.durationMinutes
        remainingSeconds = service.remainingSeconds

        if !service.isActive {
            formattedRemaining = "OFF"
        } else if service.durationMinutes < 0 {
            formattedRemaining = "∞"
        } else {
            let total = Int(max(0, service.remainingSeconds))
            let h = total / 3600, m = (total % 3600) / 60, s = total % 60
            if h > 0 {
                formattedRemaining = String(format: "%dh %02dm", h, m)
            } else if m > 0 {
                formattedRemaining = String(format: "%dm %02ds", m, s)
            } else {
                formattedRemaining = String(format: "%02ds", s)
            }
        }
    }
}
