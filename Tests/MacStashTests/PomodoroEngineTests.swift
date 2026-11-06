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
}
