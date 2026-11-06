import Foundation
import CoreGraphics
import MacStashCore

public enum SettingsPersistenceTests {
    public static func run() {
        testSerializationRoundtrip()
        testExportAndImportJSON()
        testCorruptedJSONRejection()
    }

    private static func testSerializationRoundtrip() {
        var settings = AppSettings.defaultSettings
        settings.cornerSensitivityPoints = 12.0
        settings.cornerDwellDelaySeconds = 0.35
        settings.isSoundEnabled = false

        let suiteName = "com.macstash.test.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            TestAssertion.assertTrue(false, "UserDefaults suite creation failed")
            return
        }
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let service = SettingsPersistenceService(userDefaults: defaults)
        service.saveSettings(settings)

        let loaded = service.loadSettings()
        TestAssertion.assertEqual(loaded.cornerSensitivityPoints, CGFloat(12.0))
        TestAssertion.assertEqual(loaded.cornerDwellDelaySeconds, TimeInterval(0.35))
        TestAssertion.assertEqual(loaded.isSoundEnabled, false)
    }

    private static func testExportAndImportJSON() {
        var settings = AppSettings.defaultSettings
        settings.excludedBundleIDs = ["com.apple.dt.Xcode", "com.google.Chrome"]

        let service = SettingsPersistenceService()
        do {
            let data = try service.exportJSON(settings: settings)
            TestAssertion.assertFalse(data.isEmpty)

            let imported = try service.importJSON(data: data)
            TestAssertion.assertEqual(imported.excludedBundleIDs, ["com.apple.dt.Xcode", "com.google.Chrome"])
        } catch {
            TestAssertion.assertTrue(false, "Export/Import failed: \(error.localizedDescription)")
        }
    }

    private static func testCorruptedJSONRejection() {
        let service = SettingsPersistenceService()
        let corruptedData = Data("invalid json content".utf8)
        TestAssertion.assertThrows({
            try service.importJSON(data: corruptedData)
        })
    }
}
