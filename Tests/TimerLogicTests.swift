import Foundation

func testTimerLogic() {
    print("Running Timer Logic Tests...")

    // 25 mins Pomodoro
    let totalSecs = 25 * 60
    var remaining = totalSecs

    func formatted(secs: Int) -> String {
        let mins = secs / 60
        let s = secs % 60
        return String(format: "%02d:%02d", mins, s)
    }

    assert(formatted(secs: remaining) == "25:00", "Initial formatted time must be 25:00")

    remaining -= 90 // 1m 30s elapsed
    assert(formatted(secs: remaining) == "23:30", "After 90s, must be 23:30")

    let progress = Double(remaining) / Double(totalSecs)
    assert(progress < 1.0 && progress > 0.0, "Progress must be between 0 and 1")

    // Mapping fraction 0.5 -> 30 mins
    let fraction = 0.5
    let mappedMins = max(1, Int(round(fraction * 60.0)))
    assert(mappedMins == 30, "0.5 fraction must map to 30 mins")

    print("  Timer duration, countdown formatting & progress mapping verified.")
}

testTimerLogic()
