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

    public var isPaused: Bool {
        if case .paused = self { return true }
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

    public var configuredFocusDuration: TimeInterval = TimeInterval(Defaults.Pomodoro.defaultFocusDurationSeconds)
    public var configuredShortBreakDuration: TimeInterval = TimeInterval(Defaults.Pomodoro.defaultShortBreakDurationSeconds)
    public var configuredLongBreakDuration: TimeInterval = TimeInterval(Defaults.Pomodoro.defaultLongBreakDurationSeconds)
    public var roundsBeforeLongBreak: Int = Defaults.Pomodoro.defaultRoundsBeforeLongBreak
    public var autoStartBreaks: Bool = false

    private let clock: ClockProtocol

    public init(clock: ClockProtocol = SystemClock()) {
        self.clock = clock
    }

    public var totalDurationSeconds: TimeInterval {
        switch state {
        case .idle:
            return durationForCurrentMode()
        case .running(_, _, let total), .paused(_, let total), .completed(let total):
            return total
        }
    }

    public var remainingSeconds: TimeInterval {
        switch state {
        case .idle:
            return durationForCurrentMode()
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

    public var nextSuggestedMode: PomodoroMode {
        switch mode {
        case .focus:
            let nextRounds = completedRounds + (state == .completed(totalDurationSeconds: totalDurationSeconds) ? 0 : 1)
            let isLong = (roundsBeforeLongBreak > 0) && (nextRounds % roundsBeforeLongBreak == 0)
            return isLong ? .longBreak : .shortBreak
        case .shortBreak, .longBreak:
            return .focus
        }
    }

    public func durationForCurrentMode() -> TimeInterval {
        switch mode {
        case .focus: return configuredFocusDuration
        case .shortBreak: return configuredShortBreakDuration
        case .longBreak: return configuredLongBreakDuration
        }
    }

    public func configure(
        focusDurationSeconds: TimeInterval? = nil,
        shortBreakDurationSeconds: TimeInterval? = nil,
        longBreakDurationSeconds: TimeInterval? = nil,
        roundsBeforeLongBreak: Int? = nil,
        autoStartBreaks: Bool? = nil
    ) {
        if let f = focusDurationSeconds, f > 0 {
            self.configuredFocusDuration = f
        }
        if let s = shortBreakDurationSeconds, s > 0 {
            self.configuredShortBreakDuration = s
        }
        if let l = longBreakDurationSeconds, l > 0 {
            self.configuredLongBreakDuration = l
        }
        if let r = roundsBeforeLongBreak, r > 0 {
            self.roundsBeforeLongBreak = r
        }
        if let a = autoStartBreaks {
            self.autoStartBreaks = a
        }
    }

    public func setMode(_ newMode: PomodoroMode) {
        self.mode = newMode
        self.state = .idle
    }

    public func start(durationSeconds: TimeInterval? = nil, mode: PomodoroMode? = nil) {
        if let mode = mode {
            self.mode = mode
        }
        let requested = durationSeconds ?? durationForCurrentMode()
        let duration = max(1.0, requested)
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
        switch state {
        case .paused(let remaining, let total):
            guard remaining > 0 else {
                completeSession()
                return
            }
            let now = clock.now()
            let monoNow = clock.monotonicTime()
            let targetEnd = now.addingTimeInterval(remaining)
            let monoEnd = monoNow + remaining

            state = .running(targetEndDate: targetEnd, monotonicEnd: monoEnd, totalDurationSeconds: total)

        case .idle, .completed:
            // Recover from idle/completed by launching current mode
            start(durationSeconds: durationForCurrentMode(), mode: mode)

        case .running:
            break
        }
    }

    public func toggle() {
        if state.isRunning {
            pause()
        } else {
            resume()
        }
    }

    public func reset(toDurationSeconds duration: TimeInterval? = nil) {
        if let duration = duration, duration > 0 {
            switch mode {
            case .focus:
                configuredFocusDuration = duration
            case .shortBreak:
                configuredShortBreakDuration = duration
            case .longBreak:
                configuredLongBreakDuration = duration
            }
        }
        state = .idle
    }

    public func resetRounds() {
        completedRounds = 0
    }

    @discardableResult
    public func skipToNextMode() -> PomodoroMode {
        switch mode {
        case .focus:
            completedRounds += 1
            let isLong = (roundsBeforeLongBreak > 0) && (completedRounds % roundsBeforeLongBreak == 0)
            mode = isLong ? .longBreak : .shortBreak
        case .shortBreak, .longBreak:
            mode = .focus
        }
        state = .idle
        return mode
    }

    public func tick() -> (remaining: TimeInterval, progress: Double, didJustComplete: Bool, completedMode: PomodoroMode?) {
        guard case .running = state else {
            return (remainingSeconds, progress, false, nil)
        }

        let remaining = remainingSeconds
        if remaining <= 0.01 {
            let finishedMode = mode
            completeSession()

            let isLong = (roundsBeforeLongBreak > 0) && (completedRounds % roundsBeforeLongBreak == 0)
            let nextMode = (finishedMode == .focus) ? (isLong ? PomodoroMode.longBreak : PomodoroMode.shortBreak) : PomodoroMode.focus

            if autoStartBreaks {
                mode = nextMode
                start(durationSeconds: durationForCurrentMode(), mode: nextMode)
            } else {
                mode = nextMode
            }

            return (0.0, 0.0, true, finishedMode)
        }

        return (remaining, progress, false, nil)
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
