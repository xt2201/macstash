import Foundation
import AppKit
import Combine

/// Manages 0-60 min Focus / Pomodoro Quick Timer aligned with Stash
public final class FocusTimerManager: ObservableObject {
    public static let shared = FocusTimerManager()

    @Published public private(set) var totalSeconds: Int = 1500 // 25 mins default
    @Published public private(set) var remainingSeconds: Int = 1500
    @Published public private(set) var isRunning: Bool = false

    public var progress: Double {
        guard totalSeconds > 0 else { return 0.0 }
        return Double(remainingSeconds) / Double(totalSeconds)
    }

    public var formattedTime: String {
        let mins = remainingSeconds / 60
        let secs = remainingSeconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    public var displayMinutes: Int {
        remainingSeconds / 60
    }

    private var timer: Timer?

    private init() {}

    /// Set timer duration in minutes (clamped between 1 and 60)
    public func setMinutes(_ mins: Int) {
        let clamped = max(1, min(60, mins))
        let secs = clamped * 60
        self.totalSeconds = secs
        self.remainingSeconds = secs
        if isRunning {
            pause()
        }
    }

    /// Set duration by fraction 0.0 to 1.0 (maps to 1 to 60 mins)
    public func setFraction(_ fraction: Double) {
        let mins = max(1, Int(round(fraction * 60.0)))
        setMinutes(mins)
    }

    public func togglePlayPause() {
        if isRunning {
            pause()
        } else {
            start()
        }
    }

    public func start() {
        guard remainingSeconds > 0 else {
            remainingSeconds = totalSeconds
            return
        }
        isRunning = true
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    public func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    public func reset() {
        pause()
        remainingSeconds = totalSeconds
    }

    private func tick() {
        if remainingSeconds > 1 {
            remainingSeconds -= 1
        } else {
            remainingSeconds = 0
            pause()
            notifyTimerFinished()
        }
    }

    private func notifyTimerFinished() {
        NSSound(named: "Glass")?.play()

        // macOS System Alert
        let notification = NSUserNotification()
        notification.title = "MacStash Focus Timer"
        notification.informativeText = "Time is up! Great job focusing."
        notification.soundName = NSUserNotificationDefaultSoundName
        NSUserNotificationCenter.default.deliver(notification)
    }
}
