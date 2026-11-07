import Foundation
import CoreGraphics
import MacStashCore

public enum StashFeatureTests {
    public static func run() {
        testPowerAssertionService()
        testStashItemModel()
        testScratchpadStorage()
        testScratchpadCounters()
        testOuterLeftEdgeGeometry()
        testNewControlActions()
    }

    private static func testScratchpadCounters() {
        let sample = "Hello World! This is MacStash.\nSecond line with 6 words."
        let words = sample.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
        let chars = sample.count
        TestAssertion.assertEqual(words, 10, "Word count should be 10")
        TestAssertion.assertEqual(chars, 56, "Char count should be 56")
    }

    private static func testPowerAssertionService() {
        let service = PowerAssertionService()
        TestAssertion.assertFalse(service.isActive, "Service should start inactive")
        TestAssertion.assertEqual(service.durationMinutes, 0, "Initial duration should be 0")

        let activated = service.activate(minutes: 30)
        TestAssertion.assertTrue(activated, "PowerAssertionService should activate successfully")
        TestAssertion.assertTrue(service.isActive, "Service should be active")
        TestAssertion.assertEqual(service.durationMinutes, 30, "Duration should be 30m")
        TestAssertion.assertTrue(service.remainingSeconds > 0, "Remaining seconds should be positive")

        let ticked = service.tick()
        TestAssertion.assertTrue(ticked, "Service should tick while active")

        service.deactivate()
        TestAssertion.assertFalse(service.isActive, "Service should be inactive after deactivation")
        TestAssertion.assertEqual(service.durationMinutes, 0, "Duration should be reset to 0")

        let toggled = service.toggle()
        TestAssertion.assertTrue(toggled, "Toggle on should activate")
        TestAssertion.assertTrue(service.isActive, "Service should be active after toggle")
        TestAssertion.assertEqual(service.durationMinutes, -1, "Default toggle should be indefinite")

        service.deactivate()
    }

    private static func testStashItemModel() {
        let id = UUID()
        let item = StashItem(
            id: id,
            title: "sample.png",
            detailText: "/Users/test",
            itemType: .image,
            sourceURL: URL(fileURLWithPath: "/tmp/sample.png"),
            fileSizeBytes: 2048
        )

        TestAssertion.assertEqual(item.id, id, "ID matches")
        TestAssertion.assertEqual(item.title, "sample.png", "Title matches")
        TestAssertion.assertEqual(item.itemType, StashItemType.image, "Item type is image")
        TestAssertion.assertFalse(item.formattedSize.isEmpty, "Formatted size should not be empty")

        // JSON Encoding / Decoding roundtrip
        if let data = try? JSONEncoder().encode(item),
           let decoded = try? JSONDecoder().decode(StashItem.self, from: data) {
            TestAssertion.assertEqual(decoded.id, id, "Decoded ID matches")
            TestAssertion.assertEqual(decoded.title, "sample.png", "Decoded title matches")
            TestAssertion.assertEqual(decoded.fileSizeBytes, Int64(2048), "Decoded size matches")
        } else {
            TestAssertion.assertTrue(false, "StashItem JSON roundtrip failed")
        }
    }

    private static func testScratchpadStorage() {
        let suiteName = "com.macstash.scratchpad.test.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            TestAssertion.assertTrue(false, "UserDefaults suite creation failed")
            return
        }
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let storage = ScratchpadStorage(userDefaults: defaults)
        let initial = storage.load()
        TestAssertion.assertEqual(initial.text, "", "Initial scratchpad should be empty")

        storage.save(ScratchpadData(text: "Quick OTP: 123456", lastModified: Date()))
        let reloaded = storage.load()
        TestAssertion.assertEqual(reloaded.text, "Quick OTP: 123456", "Saved text reloaded correctly")

        storage.clear()
        let cleared = storage.load()
        TestAssertion.assertEqual(cleared.text, "", "Cleared text should be empty")
    }

    private static func testOuterLeftEdgeGeometry() {
        let screen1 = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        let screen2 = CGRect(x: 1920, y: 0, width: 1920, height: 1080)
        let allScreens = [screen1, screen2]

        // Screen 1's left edge is physical outer left edge
        TestAssertion.assertTrue(CornerGeometry.isOuterLeftEdge(screen: screen1, in: allScreens), "Screen1 left edge is outer")

        // Screen 2's left edge is adjacent to Screen 1's right edge
        TestAssertion.assertFalse(CornerGeometry.isOuterLeftEdge(screen: screen2, in: allScreens), "Screen2 left edge is internal seam")

        // Screen 2's right edge is physical outer right edge
        TestAssertion.assertTrue(CornerGeometry.isOuterRightEdge(screen: screen2, in: allScreens), "Screen2 right edge is outer")
    }

    private static func testNewControlActions() {
        let actions = ControlAction.allCases
        TestAssertion.assertTrue(actions.contains(.keepAwake), "allCases contains keepAwake")
        TestAssertion.assertTrue(actions.contains(.stashShelf), "allCases contains stashShelf")
        TestAssertion.assertTrue(actions.contains(.scratchpad), "allCases contains scratchpad")

        for action in [ControlAction.keepAwake, .stashShelf, .scratchpad] {
            TestAssertion.assertFalse(action.displayName.isEmpty, "\(action) has non-empty displayName")
            TestAssertion.assertFalse(action.shortTitle.isEmpty, "\(action) has non-empty shortTitle")
            TestAssertion.assertFalse(action.systemImageName.isEmpty, "\(action) has non-empty systemImageName")
            TestAssertion.assertFalse(action.localizedDisplayName(using: "en").isEmpty, "\(action) has English name")
            TestAssertion.assertFalse(action.localizedDisplayName(using: "vi").isEmpty, "\(action) has Vietnamese name")
        }
    }
}
