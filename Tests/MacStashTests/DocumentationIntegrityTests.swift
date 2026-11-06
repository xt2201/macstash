import Foundation

public enum DocumentationIntegrityTests {
    public static func run() {
        testDocumentationDirectoriesExist()
        testBilingualFileSymmetry()
        testSettingsCoverage()
        testShortcutsCoverage()
        testZeroEmojisInGuide()
    }

    private static func findRepoRoot() -> URL? {
        var current = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        for _ in 0..<5 {
            let guidePath = current.appendingPathComponent("Docs/Guide")
            if FileManager.default.fileExists(atPath: guidePath.path) {
                return current
            }
            current = current.deletingLastPathComponent()
        }
        return nil
    }

    private static func testDocumentationDirectoriesExist() {
        guard let root = findRepoRoot() else {
            TestAssertion.assertTrue(false, "Could not locate repo root directory")
            return
        }

        let enDir = root.appendingPathComponent("Docs/Guide/en")
        let viDir = root.appendingPathComponent("Docs/Guide/vi")

        var isDir: ObjCBool = false
        TestAssertion.assertTrue(FileManager.default.fileExists(atPath: enDir.path, isDirectory: &isDir) && isDir.boolValue, "Docs/Guide/en exists")
        TestAssertion.assertTrue(FileManager.default.fileExists(atPath: viDir.path, isDirectory: &isDir) && isDir.boolValue, "Docs/Guide/vi exists")
    }

    private static func testBilingualFileSymmetry() {
        guard let root = findRepoRoot() else { return }

        let enDir = root.appendingPathComponent("Docs/Guide/en")
        let viDir = root.appendingPathComponent("Docs/Guide/vi")

        guard let enFiles = try? FileManager.default.contentsOfDirectory(atPath: enDir.path),
              let viFiles = try? FileManager.default.contentsOfDirectory(atPath: viDir.path) else {
            TestAssertion.assertTrue(false, "Failed to read Docs/Guide directory contents")
            return
        }

        let enMd = enFiles.filter { $0.hasSuffix(".md") }.sorted()
        let viMd = viFiles.filter { $0.hasSuffix(".md") }.sorted()

        TestAssertion.assertTrue(enMd.count >= 8, "English documentation has at least 8 articles (got \(enMd.count))")
        TestAssertion.assertTrue(viMd.count >= 8, "Vietnamese documentation has at least 8 articles (got \(viMd.count))")
        TestAssertion.assertEqual(enMd, viMd, "English and Vietnamese documentation file lists are identical")

        for filename in enMd {
            let enPath = enDir.appendingPathComponent(filename).path
            let viPath = viDir.appendingPathComponent(filename).path

            let enAttr = try? FileManager.default.attributesOfItem(atPath: enPath)
            let viAttr = try? FileManager.default.attributesOfItem(atPath: viPath)

            let enSize = (enAttr?[.size] as? NSNumber)?.intValue ?? 0
            let viSize = (viAttr?[.size] as? NSNumber)?.intValue ?? 0

            TestAssertion.assertTrue(enSize > 100, "English article \(filename) is non-empty (>100 bytes)")
            TestAssertion.assertTrue(viSize > 100, "Vietnamese article \(filename) is non-empty (>100 bytes)")
        }
    }

    private static func testSettingsCoverage() {
        guard let root = findRepoRoot() else { return }

        let enSettingsPath = root.appendingPathComponent("Docs/Guide/en/05_settings.md")
        let viSettingsPath = root.appendingPathComponent("Docs/Guide/vi/05_settings.md")

        guard let enContent = try? String(contentsOf: enSettingsPath, encoding: .utf8),
              let viContent = try? String(contentsOf: viSettingsPath, encoding: .utf8) else {
            TestAssertion.assertTrue(false, "Failed to read 05_settings.md")
            return
        }

        let requiredEnTabs = [
            "General",
            "Hot Corners",
            "Appearance",
            "Displays",
            "Pomodoro",
            "Shortcuts",
            "About"
        ]

        for tab in requiredEnTabs {
            TestAssertion.assertTrue(enContent.contains(tab), "English settings guide covers '\(tab)' tab")
            TestAssertion.assertTrue(viContent.contains(tab), "Vietnamese settings guide covers '\(tab)' tab")
        }
    }

    private static func testShortcutsCoverage() {
        guard let root = findRepoRoot() else { return }

        let enShortcutsPath = root.appendingPathComponent("Docs/Guide/en/06_shortcuts.md")
        guard let enContent = try? String(contentsOf: enShortcutsPath, encoding: .utf8) else {
            TestAssertion.assertTrue(false, "Failed to read 06_shortcuts.md")
            return
        }

        let requiredShortcuts = [
            "Command+,",
            "Command+W",
            "Command+?",
            "Command+Q"
        ]

        for shortcut in requiredShortcuts {
            TestAssertion.assertTrue(enContent.contains(shortcut), "Shortcuts guide covers '\(shortcut)'")
        }
    }

    private static func testZeroEmojisInGuide() {
        guard let root = findRepoRoot() else { return }
        let guideRoot = root.appendingPathComponent("Docs/Guide")

        guard let enumerator = FileManager.default.enumerator(at: guideRoot, includingPropertiesForKeys: nil) else {
            TestAssertion.assertTrue(false, "Failed to enumerate Docs/Guide")
            return
        }

        for case let fileURL as URL in enumerator where fileURL.pathExtension == "md" {
            guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else { continue }
            let hasEmoji = content.unicodeScalars.contains { scalar in
                scalar.properties.isEmoji && scalar.properties.isEmojiPresentation
            }
            TestAssertion.assertFalse(hasEmoji, "Guide file \(fileURL.lastPathComponent) contains zero emojis")
        }
    }
}
