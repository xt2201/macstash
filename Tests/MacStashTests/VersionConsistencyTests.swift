import Foundation
import MacStashCore

public enum VersionConsistencyTests {
    public static func run() {
        testVersionFileExistsAndValid()
        testInfoPlistMatchesVersion()
        testChangelogMatchesVersion()
        testWhatsNewDocsMatchVersion()
        testAppcastMatchesVersion()
        testDynamicLocalizationVersion()
        testNoStaleHardcodedVersionsInCatalog()
    }

    private static func findRepoRoot() -> URL? {
        var current = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        for _ in 0..<5 {
            let versionPath = current.appendingPathComponent("VERSION")
            if FileManager.default.fileExists(atPath: versionPath.path) {
                return current
            }
            current = current.deletingLastPathComponent()
        }
        return nil
    }

    private static func currentRepoVersion() -> String? {
        guard let root = findRepoRoot() else { return nil }
        let path = root.appendingPathComponent("VERSION").path
        guard let content = try? String(contentsOfFile: path, encoding: .utf8) else { return nil }
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func testVersionFileExistsAndValid() {
        guard let version = currentRepoVersion() else {
            TestAssertion.assertTrue(false, "VERSION file must exist at repo root and be readable")
            return
        }

        let parts = version.split(separator: ".")
        TestAssertion.assertTrue(parts.count >= 2, "VERSION '\(version)' is semver format (at least major.minor)")
    }

    private static func testInfoPlistMatchesVersion() {
        guard let root = findRepoRoot(), let version = currentRepoVersion() else { return }
        let plistPath = root.appendingPathComponent("Scripts/Info.plist").path

        guard let data = try? Data(contentsOf: URL(fileURLWithPath: plistPath)),
              let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] else {
            TestAssertion.assertTrue(false, "Scripts/Info.plist must be valid property list")
            return
        }

        let shortVersion = plist["CFBundleShortVersionString"] as? String
        TestAssertion.assertEqual(shortVersion, version, "Scripts/Info.plist CFBundleShortVersionString matches VERSION")

        let buildVersion = plist["CFBundleVersion"] as? String
        let expectedBuild = version.replacingOccurrences(of: ".", with: "")
        TestAssertion.assertEqual(buildVersion, expectedBuild, "Scripts/Info.plist CFBundleVersion matches '\(expectedBuild)'")
    }

    private static func testChangelogMatchesVersion() {
        guard let root = findRepoRoot(), let version = currentRepoVersion() else { return }
        let changelogPath = root.appendingPathComponent("CHANGELOG.md").path

        guard let content = try? String(contentsOfFile: changelogPath, encoding: .utf8) else {
            TestAssertion.assertTrue(false, "CHANGELOG.md must exist and be readable")
            return
        }

        let expectedHeader = "## [\(version)]"
        TestAssertion.assertTrue(content.contains(expectedHeader), "CHANGELOG.md contains release entry '\(expectedHeader)'")
    }

    private static func testWhatsNewDocsMatchVersion() {
        guard let root = findRepoRoot(), let version = currentRepoVersion() else { return }
        let enPath = root.appendingPathComponent("Docs/Guide/en/08_whats_new.md").path
        let viPath = root.appendingPathComponent("Docs/Guide/vi/08_whats_new.md").path

        let enContent = (try? String(contentsOfFile: enPath, encoding: .utf8)) ?? ""
        let viContent = (try? String(contentsOfFile: viPath, encoding: .utf8)) ?? ""

        TestAssertion.assertTrue(enContent.contains("Version \(version)"), "en/08_whats_new.md contains 'Version \(version)'")
        TestAssertion.assertTrue(viContent.contains("Phiên Bản \(version)") || viContent.contains("Phiên bản \(version)"), "vi/08_whats_new.md contains 'Phiên Bản \(version)'")
    }

    private static func testAppcastMatchesVersion() {
        guard let root = findRepoRoot(), let version = currentRepoVersion() else { return }
        let appcastPath = root.appendingPathComponent("appcast.xml").path

        guard let content = try? String(contentsOfFile: appcastPath, encoding: .utf8) else {
            TestAssertion.assertTrue(false, "appcast.xml must exist and be readable")
            return
        }

        let expectedTag = "<sparkle:shortVersionString>\(version)</sparkle:shortVersionString>"
        TestAssertion.assertTrue(content.contains(expectedTag), "appcast.xml contains latest sparkle item '\(expectedTag)'")
    }

    private static func testDynamicLocalizationVersion() {
        guard let version = currentRepoVersion() else { return }
        let enString = LocalizationService.shared.localized("about.version", language: "en")
        let viString = LocalizationService.shared.localized("about.version", language: "vi")

        TestAssertion.assertTrue(enString.contains(version), "English about.version contains active version '\(version)' (got: '\(enString)')")
        TestAssertion.assertTrue(viString.contains(version), "Vietnamese about.version contains active version '\(version)' (got: '\(viString)')")
        TestAssertion.assertFalse(enString.contains("2.1.1"), "English about.version does not contain stale '2.1.1'")
        TestAssertion.assertFalse(viString.contains("2.1.1"), "Vietnamese about.version does not contain stale '2.1.1'")
    }

    private static func testNoStaleHardcodedVersionsInCatalog() {
        guard let root = findRepoRoot() else { return }
        let xcstringsPath = root.appendingPathComponent("Sources/MacStash/Resources/Localizable.xcstrings").path

        guard let content = try? String(contentsOfFile: xcstringsPath, encoding: .utf8) else { return }
        TestAssertion.assertFalse(content.contains("Version 2.1.1"), "Localizable.xcstrings does not contain hardcoded 'Version 2.1.1'")
        TestAssertion.assertFalse(content.contains("Phiên bản 2.1.1"), "Localizable.xcstrings does not contain hardcoded 'Phiên bản 2.1.1'")
    }
}
