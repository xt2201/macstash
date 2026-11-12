import Foundation

public enum CodeHygieneTests {
    public static func run() {
        testNoForbiddenCallsInSources()
        testAppStateGetValueIsPureRead()
        testZeroEmojisAcrossRepoMarkdownAndCode()
        testMinimumOSAlignment()
        testHarnessFilesExistAndValid()
    }

    private static func findRepoRoot() -> URL? {
        var current = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        for _ in 0..<5 {
            if FileManager.default.fileExists(atPath: current.appendingPathComponent("Package.swift").path) {
                return current
            }
            current = current.deletingLastPathComponent()
        }
        return nil
    }

    private static func stripLineComment(from line: String) -> String {
        var inString = false
        var escaped = false
        var previous: Character?
        for (index, ch) in line.enumerated() {
            if escaped {
                escaped = false
                previous = ch
                continue
            }
            if ch == "\\" && inString {
                escaped = true
                previous = ch
                continue
            }
            if ch == "\"" {
                inString.toggle()
            } else if !inString && ch == "/" && previous == "/" {
                let cutIndex = line.index(line.startIndex, offsetBy: max(0, index - 1))
                return String(line[..<cutIndex])
            }
            previous = ch
        }
        return line
    }

    private static func testNoForbiddenCallsInSources() {
        guard let root = findRepoRoot() else {
            TestAssertion.assertTrue(false, "Could not locate repository root")
            return
        }

        let sourcesURL = root.appendingPathComponent("Sources")
        guard let enumerator = FileManager.default.enumerator(
            at: sourcesURL,
            includingPropertiesForKeys: [.isRegularFileKey]
        ) else {
            TestAssertion.assertTrue(false, "Failed to enumerate Sources directory")
            return
        }

        var printOffenders: [String] = []
        var nsLogOffenders: [String] = []
        var tryBangOffenders: [String] = []
        var asBangOffenders: [String] = []
        var fatalOffenders: [String] = []

        for case let fileURL as URL in enumerator where fileURL.pathExtension == "swift" {
            guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else { continue }
            let fileName = fileURL.lastPathComponent
            let lines = content.components(separatedBy: .newlines)

            for (idx, rawLine) in lines.enumerated() {
                let code = stripLineComment(from: rawLine)
                let lineRef = "\(fileName):\(idx + 1)"

                if code.contains("NSLog(") {
                    nsLogOffenders.append(lineRef)
                }
                if code.range(of: #"\bprint\s*\("#, options: .regularExpression) != nil {
                    printOffenders.append(lineRef)
                }
                if code.contains("try!") {
                    tryBangOffenders.append(lineRef)
                }
                if code.range(of: #"\bas!"#, options: .regularExpression) != nil {
                    asBangOffenders.append(lineRef)
                }
                if code.contains("fatalError(") && !code.contains("not been implemented") {
                    fatalOffenders.append(lineRef)
                }
            }
        }

        TestAssertion.assertTrue(printOffenders.isEmpty, "Zero print() calls in Sources/ (found: \(printOffenders.joined(separator: ", ")))")
        TestAssertion.assertTrue(nsLogOffenders.isEmpty, "Zero NSLog() calls in Sources/ (found: \(nsLogOffenders.joined(separator: ", ")))")
        TestAssertion.assertTrue(tryBangOffenders.isEmpty, "Zero try! calls in Sources/ (found: \(tryBangOffenders.joined(separator: ", ")))")
        TestAssertion.assertTrue(asBangOffenders.isEmpty, "Zero as! force casts in Sources/ (found: \(asBangOffenders.joined(separator: ", ")))")
        TestAssertion.assertTrue(fatalOffenders.isEmpty, "Zero runtime fatalError() calls outside unavailable initializers (found: \(fatalOffenders.joined(separator: ", ")))")
    }

    private static func testAppStateGetValueIsPureRead() {
        guard let root = findRepoRoot() else { return }
        let appStateURL = root.appendingPathComponent("Sources/MacStash/App/AppState.swift")
        guard let content = try? String(contentsOf: appStateURL, encoding: .utf8) else {
            TestAssertion.assertTrue(false, "AppState.swift must be readable")
            return
        }
        guard let startRange = content.range(of: "public func getValue(for action: ControlAction"),
              let endRange = content.range(of: "public func setValue(for action: ControlAction", range: startRange.upperBound..<content.endIndex) else {
            TestAssertion.assertTrue(false, "Could not locate AppState.getValue method body")
            return
        }
        let body = String(content[startRange.lowerBound..<endRange.lowerBound])
        TestAssertion.assertFalse(body.contains("updateBrightnessFromHardware"), "AppState.getValue must not mutate @Published via updateBrightnessFromHardware")
        TestAssertion.assertFalse(body.contains("syncHardwareBrightness"), "AppState.getValue must not mutate @Published via syncHardwareBrightness")
        TestAssertion.assertFalse(body.contains("updateVolumeFromHardware"), "AppState.getValue must not mutate @Published via updateVolumeFromHardware")
        TestAssertion.assertFalse(body.contains("objectWillChange"), "AppState.getValue must never fire objectWillChange inside View.body")
    }

    private static func testZeroEmojisAcrossRepoMarkdownAndCode() {
        guard let root = findRepoRoot() else { return }

        var offenders: [String] = []
        let checkDirectories = ["Sources", "Tests", "Docs"]
        for dir in checkDirectories {
            let dirURL = root.appendingPathComponent(dir)
            guard let enumerator = FileManager.default.enumerator(at: dirURL, includingPropertiesForKeys: nil) else { continue }
            for case let fileURL as URL in enumerator {
                let ext = fileURL.pathExtension
                guard ext == "swift" || ext == "md" else { continue }
                guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else { continue }
                let hasEmoji = content.unicodeScalars.contains { scalar in
                    scalar.properties.isEmoji && scalar.properties.isEmojiPresentation
                }
                if hasEmoji {
                    offenders.append(fileURL.lastPathComponent)
                }
            }
        }

        let rootDocs = [
            "AGENTS.md", "CLAUDE.md", "README.md", "CHANGELOG.md",
            "DECISIONS.md", "PROGRESS.md", "BACKLOG.md", "ASSETS.md"
        ]
        for file in rootDocs {
            let fileURL = root.appendingPathComponent(file)
            guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else { continue }
            let hasEmoji = content.unicodeScalars.contains { scalar in
                scalar.properties.isEmoji && scalar.properties.isEmojiPresentation
            }
            if hasEmoji {
                offenders.append(file)
            }
        }

        TestAssertion.assertTrue(offenders.isEmpty, "Zero emojis across Sources, Tests, Docs, and root Markdown files (found: \(offenders.joined(separator: ", ")))")
    }

    private static func testMinimumOSAlignment() {
        guard let root = findRepoRoot() else { return }
        let plistPath = root.appendingPathComponent("Scripts/Info.plist").path
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: plistPath)),
              let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] else {
            TestAssertion.assertTrue(false, "Scripts/Info.plist must be readable for OS alignment check")
            return
        }

        let minOS = plist["LSMinimumSystemVersion"] as? String
        TestAssertion.assertEqual(minOS, "14.0", "Scripts/Info.plist LSMinimumSystemVersion aligns with Package.swift macOS 14.0")
    }

    private static func testHarnessFilesExistAndValid() {
        guard let root = findRepoRoot() else { return }
        let requiredFiles = [
            "AGENTS.md",
            "CLAUDE.md",
            "Docs/Agent/UI_DESIGN_SYSTEM.md",
            "Docs/Agent/ARCHITECTURE_AND_RELEASE.md"
        ]

        for relPath in requiredFiles {
            let path = root.appendingPathComponent(relPath).path
            let exists = FileManager.default.fileExists(atPath: path)
            TestAssertion.assertTrue(exists, "Harness file exists: \(relPath)")
        }

        if let agentsText = try? String(contentsOf: root.appendingPathComponent("AGENTS.md"), encoding: .utf8) {
            TestAssertion.assertTrue(agentsText.contains("### 1.1"), "AGENTS.md contains concrete Section 1.1 standards")
            TestAssertion.assertTrue(agentsText.contains("### 1.2"), "AGENTS.md contains concrete Section 1.2 business logic invariants")
            TestAssertion.assertTrue(agentsText.contains("### 1.3"), "AGENTS.md contains concrete Section 1.3 UI/UX philosophy")
            TestAssertion.assertFalse(agentsText.contains("scripts/build_dmg.sh"), "AGENTS.md uses exact case-sensitive 'Scripts/' paths")
        }
    }
}
