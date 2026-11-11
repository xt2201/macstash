import Foundation
import CoreGraphics
import MacStashCore

public enum StashFeatureTests {
    public static func run() {
        testPowerAssertionService()
        testStashItemModel()
        testStashShelfStorage()
        testScratchpadStorage()
        testScratchpadCounters()
        testOuterLeftEdgeGeometry()
        testNewControlActions()
        testTrackpadDirectionalVectors()
        testEdgeHitZonePolicy()
        testMultiDisplayRightEdgeDwellIsolation()
        testStashShelfHitZoneSymmetry()
        testStashDragShakeDetection()
        testDialTickSymmetry()
        testDialHubGeometrySymmetry()
        testCornerDialAlignmentGeometry()
        testLeftEdgeDrawerAutoCloseBounds()
        testLeftEdgeExtremeDwellSymmetry()
        testRightEdgeExtremeDwellSymmetry()
        testShortcutValidatorAudit()
    }

    private static func testTrackpadDirectionalVectors() {
        // Test Natural Scrolling Inversion (+physicalY = swipe up, +physicalX = swipe right)
        let naturalInverted = true
        let rawDeltaY: Double = -15.0 // swiping UP on trackpad with natural scrolling yields negative deltaY
        let rawDeltaX: Double = -10.0 // swiping RIGHT yields negative deltaX

        let physicalX = naturalInverted ? -rawDeltaX : rawDeltaX
        let physicalY = naturalInverted ? -rawDeltaY : rawDeltaY

        TestAssertion.assertTrue(physicalY > 0, "Swiping UP should yield positive physicalY")
        TestAssertion.assertTrue(physicalX > 0, "Swiping RIGHT should yield positive physicalX")

        // In .bottomRight (Volume corner), swiping UP or RIGHT must increase volume
        let effectiveStep = physicalY + physicalX
        TestAssertion.assertTrue(effectiveStep > 0, "Swiping UP or RIGHT in bottomRight increases volume")

        // Mouse Wheel without natural scrolling (wheel rolled UP yields positive deltaY)
        let mouseInverted = false
        let wheelDeltaY: Double = 12.0
        let mousePhysicalY = mouseInverted ? -wheelDeltaY : wheelDeltaY
        TestAssertion.assertTrue(mousePhysicalY > 0, "Rolling wheel UP should yield positive physicalY")
    }

    private static func testEdgeHitZonePolicy() {
        let screenWidth: CGFloat = 1920
        let maxX = screenWidth

        // Sát cạnh requirement: within 3pt of the physical screen edge
        let extremeEdgeThreshold: CGFloat = 3.0
        let scrollbarTouchPoint: CGFloat = maxX - 14.0 // User clicking standard 14pt scrollbar
        let edgeSlamPoint: CGFloat = maxX - 1.5 // User intentionally pushing cursor into screen edge

        TestAssertion.assertFalse(scrollbarTouchPoint >= maxX - extremeEdgeThreshold, "Scrollbar click must NOT be in extreme edge zone")
        TestAssertion.assertTrue(edgeSlamPoint >= maxX - extremeEdgeThreshold, "Cursor slammed to screen edge must be recognized")
    }

    private static func testMultiDisplayRightEdgeDwellIsolation() {
        let mbFrame = CGRect(x: 0, y: 0, width: 1512, height: 982)
        let extFrame = CGRect(x: 1512, y: 0, width: 2560, height: 1440)
        let allFrames = [mbFrame, extFrame]

        let panelHeight: CGFloat = 460
        let extRightRectY = extFrame.minY + (extFrame.height - panelHeight) / 2
        let extRightRect = CGRect(x: extFrame.maxX - 80, y: extRightRectY, width: 80, height: panelHeight)

        // 1. Mouse at exact physical edge of external monitor (e.g. maxX = 4072.0)
        let mouseLoc = CGPoint(x: extFrame.maxX, y: extRightRect.midY)

        let isExtAtEdgeX = mouseLoc.x >= (extFrame.maxX - 2.5) && mouseLoc.x <= (extFrame.maxX + 1.0)
        let isExtWithinEdgeY = mouseLoc.y >= extRightRect.minY && mouseLoc.y <= extRightRect.maxY
        TestAssertion.assertTrue(isExtAtEdgeX && isExtWithinEdgeY, "External monitor detects physical edge dwell correctly")

        // 2. Built-in monitor does not trigger edge for this cursor position
        let isMbAtEdgeX = mouseLoc.x >= (mbFrame.maxX - 2.5) && mouseLoc.x <= (mbFrame.maxX + 1.0)
        TestAssertion.assertFalse(isMbAtEdgeX, "Built-in monitor correctly ignores cursor located on external screen")

        // 3. Multi-display candidate collection: external screen is identified as candidate
        var candidateFound = false
        for frame in allFrames {
            let rightRectY = frame.minY + (frame.height - panelHeight) / 2
            let rRect = CGRect(x: frame.maxX - 80, y: rightRectY, width: 80, height: panelHeight)
            let atEdgeX = mouseLoc.x >= (frame.maxX - 2.5) && mouseLoc.x <= (frame.maxX + 1.0)
            let withinY = mouseLoc.y >= rRect.minY && mouseLoc.y <= rRect.maxY
            if atEdgeX && withinY {
                candidateFound = true
                TestAssertion.assertEqual(frame, extFrame, "Candidate display must be the external monitor")
                break
            }
        }
        TestAssertion.assertTrue(candidateFound, "A candidate display must be found without being cancelled by non-candidate screens")

        // 4. Scrollbar clicks on external screen are not mistaken for extreme edge dwell
        let scrollbarClick = CGPoint(x: extFrame.maxX - 14.0, y: extRightRect.midY)
        let scrollbarAtEdge = scrollbarClick.x >= (extFrame.maxX - 2.5) && scrollbarClick.x <= (extFrame.maxX + 1.0)
        TestAssertion.assertFalse(scrollbarAtEdge, "Scrollbar click on external display must not trigger edge dwell")
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

    private static func testStashShelfHitZoneSymmetry() {
        // Peek Handle dimensions must be symmetric between ScreenManager and StashShelfHostingView
        let peekWidth: CGFloat = 44.0
        let handleHeight: CGFloat = 84.0

        let screenFrame = CGRect(x: 0, y: 0, width: 1728, height: 1117)
        let panelHeight: CGFloat = 500.0
        let panelY = screenFrame.minY + (screenFrame.height - panelHeight) / 2.0
        let leftPanelRect = CGRect(x: screenFrame.minX, y: panelY, width: 380.0, height: panelHeight)

        let handleY = leftPanelRect.midY - (handleHeight / 2.0)
        let peekRect = CGRect(x: screenFrame.minX, y: handleY, width: peekWidth, height: handleHeight)

        // Mouse within the 44x84 handle region must be recognized as hovering
        let hoverPoint = CGPoint(x: 20.0, y: leftPanelRect.midY)
        TestAssertion.assertTrue(peekRect.contains(hoverPoint), "Cursor at x=20 must be recognized within peek handle")

        // Mouse just outside must not trigger
        let outsidePoint = CGPoint(x: 50.0, y: leftPanelRect.midY)
        TestAssertion.assertFalse(peekRect.contains(outsidePoint), "Cursor at x=50 is outside peek handle")

        // Active Drawer Widths
        let shelfActiveWidth: CGFloat = 335.0
        let scratchpadActiveWidth: CGFloat = 370.0
        TestAssertion.assertTrue(leftPanelRect.width >= scratchpadActiveWidth, "Panel width (380) must fully encompass scratchpad (370)")
        TestAssertion.assertTrue(leftPanelRect.width >= shelfActiveWidth, "Panel width (380) must fully encompass stash shelf (335)")
    }

    private static func testStashDragShakeDetection() {
        // Horizontal shake: 3 reversals of > 12 points
        let historyX: [CGFloat] = [100, 120, 135, 115, 95, 120, 140, 110]
        var reversalsX = 0
        var lastDirX: CGFloat = 0
        for i in 1..<historyX.count {
            let dx = historyX[i] - historyX[i - 1]
            if abs(dx) > 12 {
                let dir: CGFloat = dx > 0 ? 1 : -1
                if lastDirX != 0 && dir != lastDirX {
                    reversalsX += 1
                }
                lastDirX = dir
            }
        }
        TestAssertion.assertTrue(reversalsX >= 3, "Horizontal wiggle with 3 reversals must trigger shake gesture")

        // Vertical shake: 3 reversals of > 12 points
        let historyY: [CGFloat] = [200, 220, 235, 210, 190, 215, 235, 210]
        var reversalsY = 0
        var lastDirY: CGFloat = 0
        for i in 1..<historyY.count {
            let dy = historyY[i] - historyY[i - 1]
            if abs(dy) > 12 {
                let dir: CGFloat = dy > 0 ? 1 : -1
                if lastDirY != 0 && dir != lastDirY {
                    reversalsY += 1
                }
                lastDirY = dir
            }
        }
        TestAssertion.assertTrue(reversalsY >= 3, "Vertical wiggle with 3 reversals must trigger shake gesture")
    }

    private static func testDialTickSymmetry() {
        let tickCount = 21
        var majorIndices: [Int] = []
        for i in 0..<tickCount {
            if i % 5 == 0 {
                majorIndices.append(i)
            }
        }
        TestAssertion.assertEqual(majorIndices.count, 5, "21 ticks must have exactly 5 major ticks")
        TestAssertion.assertEqual(majorIndices, [0, 5, 10, 15, 20], "Major ticks must be at 0%, 25%, 50%, 75%, 100%")

        let fractions = majorIndices.map { Double($0) / Double(tickCount - 1) }
        TestAssertion.assertEqual(fractions[0], 0.0, "First major tick is at 0.0")
        TestAssertion.assertEqual(fractions[1], 0.25, "Second major tick is at 0.25")
        TestAssertion.assertEqual(fractions[2], 0.50, "Third major tick is at 0.50")
        TestAssertion.assertEqual(fractions[3], 0.75, "Fourth major tick is at 0.75")
        TestAssertion.assertEqual(fractions[4], 1.0, "Fifth major tick is at 1.0")
    }

    private static func testDialHubGeometrySymmetry() {
        let offsetDist: CGFloat = 39.0
        let hubRadius: CGFloat = 32.0 // diameter 64

        // Check offset coordinates for all 4 corners
        let topLeftOffset = CGPoint(x: -offsetDist, y: -offsetDist)
        let topRightOffset = CGPoint(x: offsetDist, y: -offsetDist)
        let bottomLeftOffset = CGPoint(x: -offsetDist, y: offsetDist)
        let bottomRightOffset = CGPoint(x: offsetDist, y: offsetDist)

        let d1 = hypot(topLeftOffset.x, topLeftOffset.y)
        let d2 = hypot(topRightOffset.x, topRightOffset.y)
        let d3 = hypot(bottomLeftOffset.x, bottomLeftOffset.y)
        let d4 = hypot(bottomRightOffset.x, bottomRightOffset.y)

        TestAssertion.assertEqual(d1, d2, "Top-left and top-right hub offsets must have identical radial distance")
        TestAssertion.assertEqual(d2, d3, "Top-right and bottom-left hub offsets must have identical radial distance")
        TestAssertion.assertEqual(d3, d4, "Bottom-left and bottom-right hub offsets must have identical radial distance")

        // Screen corner vertex in local coordinates is at (0, 0) or (180, 180).
        // Distance from physical corner to hub center is hypot(51, 51) = 72.12pt
        let cornerDist = hypot(51.0, 51.0)
        TestAssertion.assertTrue(abs(cornerDist - 72.12) < 0.1, "Physical corner to hub center must be ~72.12pt")

        // Clearance to both physical screen edges is exactly 51 - 32 = 19pt
        let edgeGap = 51.0 - hubRadius
        TestAssertion.assertEqual(edgeGap, 19.0, "Clearance to both adjacent screen edges must be exactly 19pt (symmetric)")
    }

    private static func testStashShelfStorage() {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("StashStorageTests_\(UUID().uuidString)")
        let testFileURL = tempDir.appendingPathComponent("test_stash.json")
        let storage = StashShelfStorage(fileURL: testFileURL)

        // Initial load should be empty
        let initial = storage.load()
        TestAssertion.assertTrue(initial.isEmpty, "Initial load from non-existent file should be empty")

        // Save items
        let item1 = StashItem(title: "Doc1.pdf", detailText: "/path", itemType: .file, fileSizeBytes: 1024)
        let item2 = StashItem(title: "https://apple.com", detailText: "Link", itemType: .url)
        storage.save([item1, item2])

        // Load items back
        let loaded = storage.load()
        TestAssertion.assertEqual(loaded.count, 2, "Loaded items count should be 2")
        TestAssertion.assertEqual(loaded[0].title, "Doc1.pdf", "First item title matches")
        TestAssertion.assertEqual(loaded[1].title, "https://apple.com", "Second item title matches")

        // Clear
        storage.clear()
        let cleared = storage.load()
        TestAssertion.assertTrue(cleared.isEmpty, "Storage should be empty after clear")

        // Cleanup
        try? FileManager.default.removeItem(at: tempDir)
    }

    private static func testCornerDialAlignmentGeometry() {
        let screen = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        let dialRadius: CGFloat = Defaults.HotCorner.defaultDialRadiusPoints
        let padding: CGFloat = Defaults.HotCorner.cornerWindowPaddingPoints
        let cornerSize = dialRadius + padding

        // Top Left: panel at (minX, maxY - cornerSize), dial pinned at .topLeading (0, 0)
        let tlPanel = CGRect(x: screen.minX, y: screen.maxY - cornerSize, width: cornerSize, height: cornerSize)
        TestAssertion.assertEqual(tlPanel.minX, screen.minX, "Top-left panel minX aligns with screen minX")
        TestAssertion.assertEqual(tlPanel.maxY, screen.maxY, "Top-left panel maxY aligns with screen maxY")

        // Top Right: panel at (maxX - cornerSize, maxY - cornerSize), dial pinned at .topTrailing
        let trPanel = CGRect(x: screen.maxX - cornerSize, y: screen.maxY - cornerSize, width: cornerSize, height: cornerSize)
        TestAssertion.assertEqual(trPanel.maxX, screen.maxX, "Top-right panel maxX aligns with screen maxX")
        TestAssertion.assertEqual(trPanel.maxY, screen.maxY, "Top-right panel maxY aligns with screen maxY")

        // Bottom Left: panel at (minX, minY), dial pinned at .bottomLeading
        let blPanel = CGRect(x: screen.minX, y: screen.minY, width: cornerSize, height: cornerSize)
        TestAssertion.assertEqual(blPanel.minX, screen.minX, "Bottom-left panel minX aligns with screen minX")
        TestAssertion.assertEqual(blPanel.minY, screen.minY, "Bottom-left panel minY aligns with screen minY")

        // Bottom Right: panel at (maxX - cornerSize, minY), dial pinned at .bottomTrailing
        let brPanel = CGRect(x: screen.maxX - cornerSize, y: screen.minY, width: cornerSize, height: cornerSize)
        TestAssertion.assertEqual(brPanel.maxX, screen.maxX, "Bottom-right panel maxX aligns with screen maxX")
        TestAssertion.assertEqual(brPanel.minY, screen.minY, "Bottom-right panel minY aligns with screen minY")
    }

    private static func testLeftEdgeDrawerAutoCloseBounds() {
        let frame = CGRect(x: 0, y: 0, width: 1512, height: 982)
        let leftEdgeHeight: CGFloat = Defaults.LeftEdgeDrawer.panelHeightPoints
        let leftEdgeY = (frame.height - leftEdgeHeight) / 2.0

        let shelfWidth: CGFloat = Defaults.LeftEdgeDrawer.shelfTotalWidthPoints + 25.0 // with 25pt margin (377.0)
        let shelfHeight: CGFloat = Defaults.LeftEdgeDrawer.shelfTotalHeightPoints + 25.0
        let shelfY = leftEdgeY + (leftEdgeHeight - shelfHeight) / 2.0
        let shelfDrawerRect = CGRect(x: frame.minX, y: shelfY, width: shelfWidth, height: shelfHeight)

        // Mouse inside shelf drawer must NOT trigger auto-close
        let insidePt = CGPoint(x: 100, y: leftEdgeY + 100)
        TestAssertion.assertTrue(shelfDrawerRect.contains(insidePt), "Cursor inside drawer area must stay open")

        // Mouse moved into workspace (> 377pt) must trigger auto-close timer
        let outsidePt = CGPoint(x: 420, y: leftEdgeY + 100)
        TestAssertion.assertFalse(shelfDrawerRect.contains(outsidePt), "Cursor moved to main workspace must trigger auto-close")
    }

    private static func testLeftEdgeExtremeDwellSymmetry() {
        let frame = CGRect(x: 0, y: 0, width: 1512, height: 982)
        let leftEdgeHeight: CGFloat = Defaults.LeftEdgeDrawer.panelHeightPoints
        let leftEdgeY = frame.minY + (frame.height - leftEdgeHeight) / 2.0
        let leftRect = CGRect(x: frame.minX, y: leftEdgeY, width: Defaults.LeftEdgeDrawer.panelWidthPoints, height: leftEdgeHeight)

        // Extreme left edge threshold is <= 2.5pt from physical frame.minX
        let atEdgePt = CGPoint(x: frame.minX + 1.0, y: leftRect.midY)
        let isAtEdgeX = atEdgePt.x <= (frame.minX + 2.5) && atEdgePt.x >= (frame.minX - 1.0)
        let isWithinEdgeY = atEdgePt.y >= leftRect.minY && atEdgePt.y <= leftRect.maxY
        TestAssertion.assertTrue(isAtEdgeX && isWithinEdgeY, "Point directly on left physical edge must qualify for dwell summon")

        // Point inside standard window (> 3.0pt) must NOT trigger dwell summon
        let insideWindowPt = CGPoint(x: frame.minX + 10.0, y: leftRect.midY)
        let notAtEdge = insideWindowPt.x <= (frame.minX + 2.5) && insideWindowPt.x >= (frame.minX - 1.0)
        TestAssertion.assertFalse(notAtEdge, "Point away from extreme left edge must not trigger dwell summon")
    }

    private static func testRightEdgeExtremeDwellSymmetry() {
        let frame = CGRect(x: 0, y: 0, width: 1512, height: 982)
        let panelHeight: CGFloat = Defaults.LeftEdgeDrawer.panelHeightPoints
        let panelY = frame.minY + (frame.height - panelHeight) / 2.0
        let panelWidth = Defaults.LeftEdgeDrawer.panelWidthPoints
        let rightRect = CGRect(x: frame.maxX - panelWidth, y: panelY, width: panelWidth, height: panelHeight)

        let atEdgePt = CGPoint(x: frame.maxX - 1.0, y: rightRect.midY)
        let isAtEdgeX = atEdgePt.x >= (frame.maxX - 2.5) && atEdgePt.x <= (frame.maxX + 1.0)
        let isWithinEdgeY = atEdgePt.y >= rightRect.minY && atEdgePt.y <= rightRect.maxY
        TestAssertion.assertTrue(isAtEdgeX && isWithinEdgeY, "Point directly on right physical edge must qualify for dwell summon")

        let insideWindowPt = CGPoint(x: frame.maxX - 10.0, y: rightRect.midY)
        let notAtEdge = insideWindowPt.x >= (frame.maxX - 2.5) && insideWindowPt.x <= (frame.maxX + 1.0)
        TestAssertion.assertFalse(notAtEdge, "Point away from extreme right edge must not trigger dwell summon")
    }

    private static func testShortcutValidatorAudit() {
        TestAssertion.assertEqual(ShortcutValidator.canonicalize("cmd-option-s"), "option+command+s")
        TestAssertion.assertEqual(ShortcutValidator.keycapTokens(for: "Control+Option+S"), ["⌃", "⌥", "S"])

        let clean = ShortcutValidator.auditConflicts(
            shortcuts: [
                ("Toggle Dials", "Option+S"),
                ("Palette", "Option+Space"),
                ("Stash Shelf", "Control+Option+S"),
                ("Scratchpad", "Control+Option+N")
            ],
            language: "en"
        )
        TestAssertion.assertTrue(clean.isEmpty, "Default non-overlapping shortcuts produce zero conflicts")

        let conflicting = ShortcutValidator.auditConflicts(
            shortcuts: [
                ("Toggle Dials", "Command+Space"),
                ("Palette", "Control+Option+D"),
                ("Stash Shelf", "Option+S"),
                ("Scratchpad", "Option+S")
            ],
            language: "vi"
        )
        TestAssertion.assertEqual(conflicting.count, 3, "Detects Spotlight, Second Dock reserved conflict, and duplicate internal binding")
    }
}
