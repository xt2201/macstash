import Foundation
import MacStashCore

private final class MockClock: ClockProtocol, @unchecked Sendable {
    var currentDate: Date
    var currentMonotonic: TimeInterval

    init(startDate: Date = Date(timeIntervalSince1970: 1700000000), startMonotonic: TimeInterval = 1000.0) {
        self.currentDate = startDate
        self.currentMonotonic = startMonotonic
    }

    func now() -> Date {
        currentDate
    }

    func monotonicTime() -> TimeInterval {
        currentMonotonic
    }

    func advance(by seconds: TimeInterval) {
        currentDate = currentDate.addingTimeInterval(seconds)
        currentMonotonic += seconds
    }
}

public enum PomodoroEngineTests {
    public static func run() {
        testStartAndProgressWithMonotonicClock()
        testPauseAndResumeFreezesTime()
        testSnapshotRestoreAfterSleepWake()
        testResumeFromIdleStartsSession()
        testResetRespectsCustomDurationAndSettings()
        testPomodoroCycleAndBreakTransitions()
        testAutoStartBreaksConfiguration()
        testSkipToNextMode()
        testPomodoroStateIsPausedProperty()
        testDurationScrubbingPreservesExactMinutesWithoutJump()
    }

    private static func testStartAndProgressWithMonotonicClock() {
        let mockClock = MockClock()
        let engine = PomodoroEngine(clock: mockClock)

        engine.start(durationSeconds: 1500)
        TestAssertion.assertTrue(engine.state.isRunning)
        TestAssertion.assertEqual(engine.totalDurationSeconds, TimeInterval(1500))
        TestAssertion.assertEqual(engine.remainingSeconds, TimeInterval(1500))
        TestAssertion.assertEqual(engine.progress, Double(1.0))

        mockClock.advance(by: 300)
        let tick1 = engine.tick()
        TestAssertion.assertEqual(tick1.remaining, TimeInterval(1200))
        TestAssertion.assertEqual(tick1.progress, Double(0.8))
        TestAssertion.assertFalse(tick1.didJustComplete)

        mockClock.advance(by: 1200)
        let tick2 = engine.tick()
        TestAssertion.assertEqual(tick2.remaining, TimeInterval(0.0))
        TestAssertion.assertEqual(tick2.progress, Double(0.0))
        TestAssertion.assertTrue(tick2.didJustComplete)
        TestAssertion.assertEqual(engine.completedRounds, 1)

        let tick3 = engine.tick()
        TestAssertion.assertFalse(tick3.didJustComplete)
    }

    private static func testPauseAndResumeFreezesTime() {
        let mockClock = MockClock()
        let engine = PomodoroEngine(clock: mockClock)

        engine.start(durationSeconds: 1000)
        mockClock.advance(by: 200)
        _ = engine.tick()
        TestAssertion.assertEqual(engine.remainingSeconds, TimeInterval(800))

        engine.pause()
        TestAssertion.assertFalse(engine.state.isRunning)

        mockClock.advance(by: 500)
        TestAssertion.assertEqual(engine.remainingSeconds, TimeInterval(800))

        engine.resume()
        TestAssertion.assertTrue(engine.state.isRunning)
        mockClock.advance(by: 100)
        _ = engine.tick()
        TestAssertion.assertEqual(engine.remainingSeconds, TimeInterval(700))
    }

    private static func testSnapshotRestoreAfterSleepWake() {
        let mockClock = MockClock()
        let engine = PomodoroEngine(clock: mockClock)

        engine.start(durationSeconds: 600)
        mockClock.advance(by: 100)
        _ = engine.tick()

        let snapshot = engine.createSnapshot()

        mockClock.advance(by: 600)

        let newEngine = PomodoroEngine(clock: mockClock)
        let expired = newEngine.restore(from: snapshot)

        TestAssertion.assertTrue(expired, "Should report expired when waking past targetEndDate")
        TestAssertion.assertEqual(newEngine.remainingSeconds, TimeInterval(0))
    }

    private static func testResumeFromIdleStartsSession() {
        let mockClock = MockClock()
        let engine = PomodoroEngine(clock: mockClock)

        // Initial state is idle
        TestAssertion.assertFalse(engine.state.isRunning)
        TestAssertion.assertEqual(engine.remainingSeconds, TimeInterval(Defaults.Pomodoro.defaultFocusDurationSeconds))

        // Calling resume from idle must start the timer
        engine.resume()
        TestAssertion.assertTrue(engine.state.isRunning, "resume() from idle starts the session")
        TestAssertion.assertEqual(engine.totalDurationSeconds, TimeInterval(Defaults.Pomodoro.defaultFocusDurationSeconds))

        // Calling toggle when running pauses
        engine.toggle()
        TestAssertion.assertFalse(engine.state.isRunning, "toggle() while running pauses")

        // Calling toggle when paused resumes
        engine.toggle()
        TestAssertion.assertTrue(engine.state.isRunning, "toggle() while paused resumes")
    }

    private static func testResetRespectsCustomDurationAndSettings() {
        let mockClock = MockClock()
        let engine = PomodoroEngine(clock: mockClock)

        // Configure 45 min focus
        engine.configure(focusDurationSeconds: 2700, shortBreakDurationSeconds: 600)
        TestAssertion.assertEqual(engine.remainingSeconds, TimeInterval(2700))

        engine.start()
        TestAssertion.assertTrue(engine.state.isRunning)
        TestAssertion.assertEqual(engine.totalDurationSeconds, TimeInterval(2700))

        mockClock.advance(by: 300)
        _ = engine.tick()

        // Reset to custom duration
        engine.reset(toDurationSeconds: 1800)
        TestAssertion.assertFalse(engine.state.isRunning)
        TestAssertion.assertEqual(engine.remainingSeconds, TimeInterval(1800))
    }

    private static func testPomodoroCycleAndBreakTransitions() {
        let mockClock = MockClock()
        let engine = PomodoroEngine(clock: mockClock)

        engine.configure(
            focusDurationSeconds: 1500,
            shortBreakDurationSeconds: 300,
            longBreakDurationSeconds: 900,
            roundsBeforeLongBreak: 2,
            autoStartBreaks: false
        )

        // Round 1 Focus
        engine.start()
        mockClock.advance(by: 1500)
        let tick1 = engine.tick()
        TestAssertion.assertTrue(tick1.didJustComplete)
        TestAssertion.assertEqual(engine.completedRounds, 1)
        TestAssertion.assertEqual(engine.mode, .shortBreak, "Next mode after focus round 1 is shortBreak")
        TestAssertion.assertFalse(engine.state.isRunning, "Without autoStartBreaks, timer waits for user")
        TestAssertion.assertEqual(engine.durationForCurrentMode(), TimeInterval(300))

        // Start Short Break
        engine.resume()
        TestAssertion.assertTrue(engine.state.isRunning)
        mockClock.advance(by: 300)
        let tickBreak = engine.tick()
        TestAssertion.assertTrue(tickBreak.didJustComplete)
        TestAssertion.assertEqual(engine.mode, .focus, "Next mode after break is focus")

        // Round 2 Focus (should trigger longBreak after completion because roundsBeforeLongBreak = 2)
        engine.resume()
        mockClock.advance(by: 1500)
        let tick2 = engine.tick()
        TestAssertion.assertTrue(tick2.didJustComplete)
        TestAssertion.assertEqual(engine.completedRounds, 2)
        TestAssertion.assertEqual(engine.mode, .longBreak, "Round 2 completed triggers longBreak")
        TestAssertion.assertEqual(engine.durationForCurrentMode(), TimeInterval(900))
    }

    private static func testAutoStartBreaksConfiguration() {
        let mockClock = MockClock()
        let engine = PomodoroEngine(clock: mockClock)

        engine.configure(
            focusDurationSeconds: 1200,
            shortBreakDurationSeconds: 300,
            roundsBeforeLongBreak: 4,
            autoStartBreaks: true
        )

        engine.start()
        mockClock.advance(by: 1200)
        let tick = engine.tick()
        TestAssertion.assertTrue(tick.didJustComplete)
        TestAssertion.assertTrue(engine.state.isRunning, "Auto-start breaks should immediately start running break")
        TestAssertion.assertEqual(engine.mode, .shortBreak)
        TestAssertion.assertEqual(engine.totalDurationSeconds, TimeInterval(300))
    }

    private static func testSkipToNextMode() {
        let mockClock = MockClock()
        let engine = PomodoroEngine(clock: mockClock)
        engine.configure(roundsBeforeLongBreak: 3)

        TestAssertion.assertEqual(engine.mode, .focus)
        let mode1 = engine.skipToNextMode()
        TestAssertion.assertEqual(mode1, .shortBreak)
        TestAssertion.assertEqual(engine.completedRounds, 1)

        let mode2 = engine.skipToNextMode()
        TestAssertion.assertEqual(mode2, .focus)
        TestAssertion.assertEqual(engine.completedRounds, 1)
    }

    private static func testPomodoroStateIsPausedProperty() {
        let mockClock = MockClock()
        let engine = PomodoroEngine(clock: mockClock)

        TestAssertion.assertFalse(engine.state.isPaused)
        TestAssertion.assertFalse(engine.state.isRunning)

        engine.start(durationSeconds: 1500)
        TestAssertion.assertTrue(engine.state.isRunning)
        TestAssertion.assertFalse(engine.state.isPaused)

        engine.pause()
        TestAssertion.assertFalse(engine.state.isRunning)
        TestAssertion.assertTrue(engine.state.isPaused)

        engine.resume()
        TestAssertion.assertTrue(engine.state.isRunning)
        TestAssertion.assertFalse(engine.state.isPaused)

        engine.reset()
        TestAssertion.assertFalse(engine.state.isRunning)
        TestAssertion.assertFalse(engine.state.isPaused)
    }

    private static func testDurationScrubbingPreservesExactMinutesWithoutJump() {
        let mockClock = MockClock()
        let engine = PomodoroEngine(clock: mockClock)

        // Simulate user dragging dial to 15 minutes
        let mins15: TimeInterval = 15 * 60
        engine.reset(toDurationSeconds: mins15)
        TestAssertion.assertEqual(engine.durationForCurrentMode(), mins15)
        TestAssertion.assertEqual(engine.remainingSeconds, mins15)
        TestAssertion.assertEqual(engine.totalDurationSeconds, mins15)

        // Starting from this duration should start at exactly 15 minutes
        engine.start()
        TestAssertion.assertTrue(engine.state.isRunning)
        TestAssertion.assertEqual(engine.totalDurationSeconds, mins15)
        TestAssertion.assertEqual(engine.remainingSeconds, mins15)

        // Simulate user dragging dial to 45 minutes when idle
        engine.reset(toDurationSeconds: 45 * 60)
        TestAssertion.assertEqual(engine.durationForCurrentMode(), TimeInterval(45 * 60))
        TestAssertion.assertEqual(engine.remainingSeconds, TimeInterval(45 * 60))
    }
}
