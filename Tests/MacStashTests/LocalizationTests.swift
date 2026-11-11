import Foundation
import MacStashCore

public enum LocalizationTests {
    public static func run() {
        testLanguageResolution()
        testLanguageSwitching()
        testCatalogSymmetryAndNonEmpty()
        testVietnameseDiacriticsInCatalog()
        testAllSettingsTabsLocalized()
        testFallbackBehavior()
    }

    private static func testLanguageResolution() {
        TestAssertion.assertEqual(
            AppLanguage.resolveEffectiveLanguage(from: "vi", preferredLanguages: ["en-US"]),
            "vi",
            "Explicit 'vi' resolves to 'vi' regardless of system locale"
        )
        TestAssertion.assertEqual(
            AppLanguage.resolveEffectiveLanguage(from: "en", preferredLanguages: ["vi-VN"]),
            "en",
            "Explicit 'en' resolves to 'en' regardless of system locale"
        )
        TestAssertion.assertEqual(
            AppLanguage.resolveEffectiveLanguage(from: "system", preferredLanguages: ["vi-VN", "en-US"]),
            "vi",
            "System with Vietnamese preferred resolves to 'vi'"
        )
        TestAssertion.assertEqual(
            AppLanguage.resolveEffectiveLanguage(from: "system", preferredLanguages: ["en-US", "vi-VN"]),
            "en",
            "System with English preferred resolves to 'en'"
        )
    }

    private static func testLanguageSwitching() {
        let service = LocalizationService()
        service.setLanguage(.vietnamese)
        TestAssertion.assertEqual(service.currentLanguage, .vietnamese, "Current language is Vietnamese")
        TestAssertion.assertEqual(service.effectiveLanguage, "vi", "Effective language is 'vi'")
        TestAssertion.assertEqual(service.localized("tab.general"), "Tổng quan", "Tab 'general' is localized in Vietnamese")

        service.setLanguage(.english)
        TestAssertion.assertEqual(service.currentLanguage, .english, "Current language is English")
        TestAssertion.assertEqual(service.effectiveLanguage, "en", "Effective language is 'en'")
        TestAssertion.assertEqual(service.localized("tab.general"), "General", "Tab 'general' is localized in English")
    }

    private static func testCatalogSymmetryAndNonEmpty() {
        guard let enDict = LocalizationService.catalog["en"],
              let viDict = LocalizationService.catalog["vi"] else {
            TestAssertion.assertTrue(false, "Catalogs for 'en' and 'vi' must exist")
            return
        }

        let enKeys = Set(enDict.keys)
        let viKeys = Set(viDict.keys)

        TestAssertion.assertTrue(enKeys.count >= 80, "English catalog has at least 80 keys (got \(enKeys.count))")
        TestAssertion.assertTrue(viKeys.count >= 80, "Vietnamese catalog has at least 80 keys (got \(viKeys.count))")
        TestAssertion.assertEqual(enKeys, viKeys, "Key symmetry between English and Vietnamese catalogs")

        for key in enKeys {
            let enVal = enDict[key] ?? ""
            let viVal = viDict[key] ?? ""
            TestAssertion.assertFalse(enVal.isEmpty, "English value for '\(key)' is non-empty")
            TestAssertion.assertFalse(viVal.isEmpty, "Vietnamese value for '\(key)' is non-empty")
        }
    }

    private static func testVietnameseDiacriticsInCatalog() {
        guard let viDict = LocalizationService.catalog["vi"] else { return }

        // Must not contain emojis
        for (key, val) in viDict {
            let hasEmoji = val.unicodeScalars.contains { scalar in
                scalar.properties.isEmoji && scalar.properties.isEmojiPresentation
            }
            TestAssertion.assertFalse(hasEmoji, "Vietnamese translation for '\(key)' contains zero emojis")
        }

        // Verify key Vietnamese terms have proper diacritics
        TestAssertion.assertEqual(viDict["tab.general"], "Tổng quan", "'tab.general' has proper diacritics")
        TestAssertion.assertEqual(viDict["tab.hotCorners"], "Góc nóng", "'tab.hotCorners' has proper diacritics")
        TestAssertion.assertEqual(viDict["tab.appearance"], "Giao diện", "'tab.appearance' has proper diacritics")
        TestAssertion.assertEqual(viDict["tab.displays"], "Màn hình", "'tab.displays' has proper diacritics")
        TestAssertion.assertEqual(viDict["tab.shortcuts"], "Phím tắt", "'tab.shortcuts' has proper diacritics")
        TestAssertion.assertEqual(viDict["tab.about"], "Thông tin & Nâng cao", "'tab.about' has proper diacritics")
        TestAssertion.assertEqual(viDict["general.masterControls"], "Điều khiển chính", "'general.masterControls' has proper diacritics")
        TestAssertion.assertEqual(viDict["general.systemPermissions"], "Quyền hệ thống", "'general.systemPermissions' has proper diacritics")
    }

    private static func testAllSettingsTabsLocalized() {
        let service = LocalizationService()
        service.setLanguage(.vietnamese)

        let requiredTabs = [
            "tab.general",
            "tab.hotCorners",
            "tab.sideDock",
            "tab.appearance",
            "tab.displays",
            "tab.pomodoro",
            "tab.shortcuts",
            "tab.about"
        ]

        for tabKey in requiredTabs {
            let viText = service.localized(tabKey)
            let enText = service.localized(tabKey, language: "en")
            TestAssertion.assertTrue(viText != enText, "Tab '\(tabKey)' differs between vi ('\(viText)') and en ('\(enText)')")
            TestAssertion.assertTrue(viText != tabKey, "Tab '\(tabKey)' is not untranslated key")
        }
    }

    private static func testFallbackBehavior() {
        let service = LocalizationService()
        let result = service.localized("non.existent.key")
        TestAssertion.assertEqual(result, "non.existent.key", "Missing key returns key itself as fallback")
    }
}
