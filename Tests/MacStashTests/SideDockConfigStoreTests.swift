import Foundation
import SideDockCore

public enum SideDockConfigStoreTests {
    public static func run() {
        testDefaultConfigGeneration()
        testPersistenceAndReload()
        testResetLayoutPreservesItems()
        testCorruptionRecovery()
    }

    private static func makeTempConfigURL() -> URL {
        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("SideDockTest_\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        return tempDir.appendingPathComponent("sidedock_test_config.json")
    }

    private static func testDefaultConfigGeneration() {
        let url = makeTempConfigURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        let store = DockConfigStore(customFileURL: url)
        let config = store.config

        TestAssertion.assertTrue(!config.profiles.isEmpty, "Default configuration creates profiles")
        TestAssertion.assertEqual(config.profiles.count, 3, "Default config provides 3 starting profiles (Default, Work, Focus)")
        TestAssertion.assertTrue(config.profiles[0].items.count >= 5, "Default profile contains starting widgets and apps")
    }

    private static func testPersistenceAndReload() {
        let url = makeTempConfigURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        let store1 = DockConfigStore(customFileURL: url)
        store1.updateConfig(immediate: true) { cfg in
            cfg.isDockVisible = false
            cfg.profiles[0].name = "RenamedProfile"
        }

        let store2 = DockConfigStore(customFileURL: url)
        TestAssertion.assertEqual(store2.config.isDockVisible, false, "Reloaded config preserves visibility")
        TestAssertion.assertEqual(store2.config.profiles[0].name, "RenamedProfile", "Reloaded config preserves profile name")
    }

    private static func testResetLayoutPreservesItems() {
        let url = makeTempConfigURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        let store = DockConfigStore(customFileURL: url)
        let originalItemCount = store.config.profiles[0].items.count

        // Alter placement and scale
        store.updateConfig(immediate: true) { cfg in
            cfg.profiles[0].layoutConfig.placement = .floating
            cfg.profiles[0].layoutConfig.scale = 1.4
            cfg.profiles[0].layoutConfig.bottomOffset = 45.0
        }

        // Trigger Reset Layout
        store.resetLayout()

        let resetConfig = store.config
        TestAssertion.assertEqual(resetConfig.profiles[0].layoutConfig.placement, .fixedBottom, "Reset layout restores fixedBottom")
        TestAssertion.assertEqual(resetConfig.profiles[0].layoutConfig.scale, 1.0, "Reset layout restores scale to 1.0")
        TestAssertion.assertEqual(resetConfig.profiles[0].layoutConfig.bottomOffset, 8.0, "Reset layout restores default bottom offset")
        TestAssertion.assertEqual(resetConfig.profiles[0].items.count, originalItemCount, "Reset layout does NOT delete widgets or items")
    }

    private static func testCorruptionRecovery() {
        let url = makeTempConfigURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        // Write garbage bytes
        try? "INVALID_CORRUPTED_JSON_DATA".data(using: .utf8)?.write(to: url)

        let store = DockConfigStore(customFileURL: url)
        let config = store.config

        TestAssertion.assertTrue(!config.profiles.isEmpty, "Store gracefully recovers from corrupted file with fresh default config")
    }
}
