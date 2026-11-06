import Foundation

public protocol ClockProtocol: Sendable {
    func now() -> Date
    func monotonicTime() -> TimeInterval
}

public struct SystemClock: ClockProtocol {
    public init() {}
    public func now() -> Date { Date() }
    public func monotonicTime() -> TimeInterval { ProcessInfo.processInfo.systemUptime }
}

public enum PomodoroMode: String, Codable, Sendable {
    case focus
    case shortBreak
    case longBreak

    public var displayName: String {
        switch self {
        case .focus: return "Focus Session"
        case .shortBreak: return "Short Break"
        case .longBreak: return "Long Break"
        }
    }
}

public enum PomodoroState: Equatable, Sendable {
    case idle
    case running(targetEndDate: Date, monotonicEnd: TimeInterval, totalDurationSeconds: TimeInterval)
    case paused(remainingSeconds: TimeInterval, totalDurationSeconds: TimeInterval)
    case completed(totalDurationSeconds: TimeInterval)

    public var isRunning: Bool {
        if case .running = self { return true }
        return false
    }
}

public struct PomodoroSnapshot: Codable, Equatable, Sendable {
    public let mode: PomodoroMode
    public let isRunning: Bool
    public let targetEndDate: Date?
    public let remainingSeconds: TimeInterval
    public let totalDurationSeconds: TimeInterval
    public let completedRounds: Int

    public init(
        mode: PomodoroMode,
        isRunning: Bool,
        targetEndDate: Date?,
        remainingSeconds: TimeInterval,
        totalDurationSeconds: TimeInterval,
        completedRounds: Int
    ) {
        self.mode = mode
        self.isRunning = isRunning
        self.targetEndDate = targetEndDate
        self.remainingSeconds = remainingSeconds
        self.totalDurationSeconds = totalDurationSeconds
        self.completedRounds = completedRounds
    }
}

public final class PomodoroEngine {
    public private(set) var mode: PomodoroMode = .focus
    public private(set) var state: PomodoroState = .idle
    public private(set) var completedRounds: Int = 0

    private let clock: ClockProtocol

    public init(clock: ClockProtocol = SystemClock()) {
        self.clock = clock
    }

    public var totalDurationSeconds: TimeInterval {
        switch state {
        case .idle:
            return TimeInterval(Defaults.Pomodoro.defaultFocusDurationSeconds)
        case .running(_, _, let total), .paused(_, let total), .completed(let total):
            return total
        }
    }

    public var remainingSeconds: TimeInterval {
        switch state {
        case .idle:
            return TimeInterval(Defaults.Pomodoro.defaultFocusDurationSeconds)
        case .running(let targetEndDate, let monotonicEnd, _):
            let monotonicRemaining = monotonicEnd - clock.monotonicTime()
            let wallClockRemaining = targetEndDate.timeIntervalSince(clock.now())
            // Prefer monotonic, fallback to wall clock if waking from system sleep
            if monotonicRemaining > 0 && wallClockRemaining > 0 {
                return min(monotonicRemaining, wallClockRemaining)
            }
            return max(0, min(monotonicRemaining, wallClockRemaining))
        case .paused(let remaining, _):
            return remaining
        case .completed:
            return 0
        }
    }

    public var progress: Double {
        let total = totalDurationSeconds
        guard total > 0 else { return 0.0 }
        return max(0.0, min(1.0, remainingSeconds / total))
    }

    public func start(durationSeconds: TimeInterval, mode: PomodoroMode = .focus) {
        let duration = max(60.0, durationSeconds)
        self.mode = mode
        let now = clock.now()
        let monoNow = clock.monotonicTime()
        let targetEnd = now.addingTimeInterval(duration)
        let monoEnd = monoNow + duration

        state = .running(targetEndDate: targetEnd, monotonicEnd: monoEnd, totalDurationSeconds: duration)
    }

    public func pause() {
        guard case .running = state else { return }
        let remaining = remainingSeconds
        state = .paused(remainingSeconds: remaining, totalDurationSeconds: totalDurationSeconds)
    }

    public func resume() {
        guard case .paused(let remaining, let total) = state else { return }
        guard remaining > 0 else {
            completeSession()
            return
        }
        let now = clock.now()
        let monoNow = clock.monotonicTime()
        let targetEnd = now.addingTimeInterval(remaining)
        let monoEnd = monoNow + remaining

        state = .running(targetEndDate: targetEnd, monotonicEnd: monoEnd, totalDurationSeconds: total)
    }

    public func reset(toDurationSeconds duration: TimeInterval? = nil) {
        let dur = duration ?? totalDurationSeconds
        state = .idle
        _ = dur
    }

    public func tick() -> (remaining: TimeInterval, progress: Double, didJustComplete: Bool) {
        guard case .running = state else {
            return (remainingSeconds, progress, false)
        }

        let remaining = remainingSeconds
        if remaining <= 0.01 {
            completeSession()
            return (0.0, 0.0, true)
        }

        return (remaining, progress, false)
    }

    private func completeSession() {
        let total = totalDurationSeconds
        state = .completed(totalDurationSeconds: total)
        if mode == .focus {
            completedRounds += 1
        }
    }

    public func createSnapshot() -> PomodoroSnapshot {
        let isRunning: Bool
        let targetEnd: Date?
        switch state {
        case .running(let end, _, _):
            isRunning = true
            targetEnd = end
        case .paused:
            isRunning = false
            targetEnd = nil
        case .idle, .completed:
            isRunning = false
            targetEnd = nil
        }

        return PomodoroSnapshot(
            mode: mode,
            isRunning: isRunning,
            targetEndDate: targetEnd,
            remainingSeconds: remainingSeconds,
            totalDurationSeconds: totalDurationSeconds,
            completedRounds: completedRounds
        )
    }

    public func restore(from snapshot: PomodoroSnapshot) -> Bool {
        self.mode = snapshot.mode
        self.completedRounds = snapshot.completedRounds

        if snapshot.isRunning, let targetEnd = snapshot.targetEndDate {
            let remaining = targetEnd.timeIntervalSince(clock.now())
            if remaining <= 0 {
                // Expired while app was closed or system was asleep
                completeSession()
                return true
            } else {
                let monoNow = clock.monotonicTime()
                let monoEnd = monoNow + remaining
                state = .running(targetEndDate: targetEnd, monotonicEnd: monoEnd, totalDurationSeconds: snapshot.totalDurationSeconds)
                return false
            }
        } else if snapshot.remainingSeconds > 0 && snapshot.remainingSeconds < snapshot.totalDurationSeconds {
            state = .paused(remainingSeconds: snapshot.remainingSeconds, totalDurationSeconds: snapshot.totalDurationSeconds)
            return false
        } else {
            state = .idle
            return false
        }
    }
}
