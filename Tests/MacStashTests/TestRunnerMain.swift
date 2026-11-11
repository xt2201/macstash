import Foundation

@main
enum TestRunnerMain {
    @MainActor
    static func main() {
        let startTime = ProcessInfo.processInfo.systemUptime
        print("Running MacStash Domain Unit Tests...")

        print("[TEST] Running CornerGeometryTests...")
        CornerGeometryTests.run()

        print("[TEST] Running OverlayStateMachineTests...")
        OverlayStateMachineTests.run()

        print("[TEST] Running PomodoroEngineTests...")
        PomodoroEngineTests.run()

        print("[TEST] Running BrightnessPolicyTests...")
        BrightnessPolicyTests.run()

        print("[TEST] Running SettingsPersistenceTests...")
        SettingsPersistenceTests.run()

        print("[TEST] Running DocumentationIntegrityTests...")
        DocumentationIntegrityTests.run()

        print("[TEST] Running LocalizationTests...")
        LocalizationTests.run()

        print("[TEST] Running StashFeatureTests...")
        StashFeatureTests.run()

        print("[TEST] Running VersionConsistencyTests...")
        VersionConsistencyTests.run()

        print("[TEST] Running SideDockLayoutEngineTests...")
        SideDockLayoutEngineTests.run()

        print("[TEST] Running SideDockConfigStoreTests...")
        SideDockConfigStoreTests.run()

        print("[TEST] Running SideDockWidgetTests...")
        SideDockWidgetTests.run()

        print("[TEST] Running CodeHygieneTests...")
        CodeHygieneTests.run()

        let elapsed = ProcessInfo.processInfo.systemUptime - startTime
        let total = TestAssertion.passCount + TestAssertion.failCount

        print("--------------------------------------------------")
        print("Test Results: \(TestAssertion.passCount) passed, \(TestAssertion.failCount) failed of \(total) assertions in \(String(format: "%.3f", elapsed))s")

        if TestAssertion.failCount > 0 {
            exit(1)
        } else {
            print("All domain tests completed successfully.")
            exit(0)
        }
    }
}
