import Foundation
import CoreGraphics
import SideDockCore

public enum SideDockLayoutEngineTests {
    public static func run() {
        testFloatingDockClamping()
        testFixedBottomAboveNativeDock()
        testFixedEdgePositions()
        testEdgeTriggerDetection()
        testAutoFitScreenWidthConstraint()
        testReserveSpacePolicy()
        testMagnificationEngineCurve()
        testAnchoredPopoverGeometry()
    }

    private static func testFloatingDockClamping() {
        let engine = DockLayoutEngine()
        let screen = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        let visible = CGRect(x: 0, y: 70, width: 1920, height: 980) // 70px native dock at bottom, 30px menu bar at top
        let contentSize = CGSize(width: 400, height: 60)

        // Case 1: Within bounds
        var config = DockLayoutConfig(placement: .floating, floatingX: 500, floatingY: 300)
        var frame = engine.calculateWindowFrame(screenFrame: screen, visibleFrame: visible, contentSize: contentSize, config: config)
        TestAssertion.assertEqual(frame.origin.x, 500.0, "Floating dock within bounds retains X")
        TestAssertion.assertEqual(frame.origin.y, 300.0, "Floating dock within bounds retains Y")

        // Case 2: Out of bounds (negative X / Y)
        config.floatingX = -100
        config.floatingY = 10
        frame = engine.calculateWindowFrame(screenFrame: screen, visibleFrame: visible, contentSize: contentSize, config: config)
        TestAssertion.assertTrue(frame.origin.x >= visible.minX, "Floating dock X clamped above visible minX")
        TestAssertion.assertTrue(frame.origin.y >= visible.minY, "Floating dock Y clamped above visible minY")

        // Case 3: Out of bounds (overflow right / top)
        config.floatingX = 2500
        config.floatingY = 1500
        frame = engine.calculateWindowFrame(screenFrame: screen, visibleFrame: visible, contentSize: contentSize, config: config)
        TestAssertion.assertTrue(frame.maxX <= visible.maxX, "Floating dock maxX clamped within visible maxX")
        TestAssertion.assertTrue(frame.maxY <= visible.maxY, "Floating dock maxY clamped within visible maxY")
    }

    private static func testFixedBottomAboveNativeDock() {
        let engine = DockLayoutEngine()
        let screen = CGRect(x: 0, y: 0, width: 1440, height: 900)
        // Native macOS Dock is 60pt high at the bottom
        let visible = CGRect(x: 0, y: 60, width: 1440, height: 815)
        let contentSize = CGSize(width: 500, height: 50)
        let config = DockLayoutConfig(placement: .fixedBottom, bottomOffset: 8.0)

        let frame = engine.calculateWindowFrame(screenFrame: screen, visibleFrame: visible, contentSize: contentSize, config: config)

        // FR-CORE-04: distance between native dock and SideDock must be >= 0 px
        let distanceToNativeDock = frame.minY - visible.minY
        TestAssertion.assertEqual(distanceToNativeDock, 8.0, "SideDock sits exactly offset points above native dock")
        TestAssertion.assertTrue(distanceToNativeDock >= 0, "SideDock does not overlap native macOS Dock")
        TestAssertion.assertEqual(frame.midX, visible.midX, "SideDock is centered horizontally")
    }

    private static func testFixedEdgePositions() {
        let engine = DockLayoutEngine()
        let screen = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        let visible = CGRect(x: 0, y: 50, width: 1920, height: 1000)
        let contentSize = CGSize(width: 300, height: 50)

        // Fixed Top
        let topConfig = DockLayoutConfig(placement: .fixedTop, bottomOffset: 10.0)
        let topFrame = engine.calculateWindowFrame(screenFrame: screen, visibleFrame: visible, contentSize: contentSize, config: topConfig)
        TestAssertion.assertEqual(topFrame.maxY, visible.maxY - 10.0, "Fixed top positioned below menu bar")

        // Fixed Left
        let leftConfig = DockLayoutConfig(placement: .fixedLeft, bottomOffset: 12.0)
        let leftFrame = engine.calculateWindowFrame(screenFrame: screen, visibleFrame: visible, contentSize: contentSize, config: leftConfig)
        TestAssertion.assertEqual(leftFrame.minX, visible.minX + 12.0, "Fixed left positioned at left edge")

        // Fixed Right
        let rightConfig = DockLayoutConfig(placement: .fixedRight, bottomOffset: 12.0)
        let rightFrame = engine.calculateWindowFrame(screenFrame: screen, visibleFrame: visible, contentSize: contentSize, config: rightConfig)
        TestAssertion.assertEqual(rightFrame.maxX, visible.maxX - 12.0, "Fixed right positioned at right edge")
    }

    private static func testEdgeTriggerDetection() {
        let engine = DockLayoutEngine()
        let screen = CGRect(x: 0, y: 0, width: 1920, height: 1080)

        // Bottom trigger
        let cursorAtBottom = CGPoint(x: 500, y: 4)
        TestAssertion.assertTrue(
            engine.isInsideEdgeTrigger(cursorLocation: cursorAtBottom, screenFrame: screen, placement: .fixedBottom, triggerThickness: 8.0),
            "Cursor near bottom activates bottom edge trigger"
        )

        let cursorAboveTrigger = CGPoint(x: 500, y: 25)
        TestAssertion.assertFalse(
            engine.isInsideEdgeTrigger(cursorLocation: cursorAboveTrigger, screenFrame: screen, placement: .fixedBottom, triggerThickness: 8.0),
            "Cursor above threshold does not activate bottom edge trigger"
        )
    }

    private static func testAutoFitScreenWidthConstraint() {
        let engine = DockLayoutEngine()
        let screen = CGRect(x: 0, y: 0, width: 800, height: 600)
        let visible = CGRect(x: 0, y: 0, width: 800, height: 570)
        let giantContent = CGSize(width: 1200, height: 60) // exceeds screen width

        let config = DockLayoutConfig(placement: .fixedBottom, autoFitScreen: true)
        let frame = engine.calculateWindowFrame(screenFrame: screen, visibleFrame: visible, contentSize: giantContent, config: config)

        TestAssertion.assertTrue(frame.width <= visible.width, "Giant content auto-fits within visible screen width")
    }

    private static func testReserveSpacePolicy() {
        let policy = ReserveSpacePolicy()
        let screenVisible = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        let dockFrame = CGRect(x: 400, y: 70, width: 1120, height: 60)

        // Window overlapping fixed bottom dock (minY=50, dock maxY=130)
        let window1 = CGRect(x: 200, y: 50, width: 1000, height: 800)
        let adjusted1 = policy.adjustWindowFrame(windowFrame: window1, dockFrame: dockFrame, placement: .fixedBottom, screenVisibleFrame: screenVisible)
        TestAssertion.assertEqual(adjusted1.minY, 130.0, "Window pushed up so minY matches dock maxY")
        TestAssertion.assertEqual(adjusted1.maxY, window1.maxY, "Window top stays at same position")

        // Window completely above dock
        let window2 = CGRect(x: 200, y: 200, width: 1000, height: 500)
        let adjusted2 = policy.adjustWindowFrame(windowFrame: window2, dockFrame: dockFrame, placement: .fixedBottom, screenVisibleFrame: screenVisible)
        TestAssertion.assertEqual(adjusted2, window2, "Non-overlapping window frame is preserved")
    }

    private static func testMagnificationEngineCurve() {
        let engine = DockMagnificationEngine()

        // Rest state when cursor is nil
        let rest = engine.scaleFactor(tileCenter: 100, cursorAxisPosition: nil, baseTileSize: 48, maxMagnification: 1.5)
        TestAssertion.assertEqual(rest, 1.0, "Magnification returns 1.0 at rest")

        // Peak at exact center
        let peak = engine.scaleFactor(tileCenter: 100, cursorAxisPosition: 100, baseTileSize: 48, maxMagnification: 1.5)
        TestAssertion.assertEqual(peak, 1.5, "Magnification peaks at maxMagnification when cursor is centered on tile")

        // Symmetric falloff on neighbors
        let left = engine.scaleFactor(tileCenter: 50, cursorAxisPosition: 100, baseTileSize: 48, maxMagnification: 1.5)
        let right = engine.scaleFactor(tileCenter: 150, cursorAxisPosition: 100, baseTileSize: 48, maxMagnification: 1.5)
        TestAssertion.assertEqual(left, right, "Magnification curve is symmetric around cursor")
        TestAssertion.assertTrue(left > 1.0 && left < 1.5, "Adjacent neighbor receives partial magnification")

        // Outside influence radius returns 1.0
        let far = engine.scaleFactor(tileCenter: 500, cursorAxisPosition: 100, baseTileSize: 48, maxMagnification: 1.5)
        TestAssertion.assertEqual(far, 1.0, "Tiles outside influence radius remain unscaled")
    }

    private static func testAnchoredPopoverGeometry() {
        let engine = DockLayoutEngine()
        let visible = CGRect(x: 0, y: 40, width: 1440, height: 830)
        let anchorBottom = CGRect(x: 700, y: 48, width: 48, height: 48)
        let popoverSize = CGSize(width: 240, height: 140)

        let bottomOrigin = engine.calculateAnchoredPopoverOrigin(
            anchorRect: anchorBottom,
            popoverSize: popoverSize,
            placement: .fixedBottom,
            visibleFrame: visible
        )
        TestAssertion.assertTrue(bottomOrigin.y >= anchorBottom.maxY, "Bottom dock popover opens above the tile")

        let anchorLeft = CGRect(x: 12, y: 400, width: 48, height: 48)
        let leftOrigin = engine.calculateAnchoredPopoverOrigin(
            anchorRect: anchorLeft,
            popoverSize: popoverSize,
            placement: .fixedLeft,
            visibleFrame: visible
        )
        TestAssertion.assertTrue(leftOrigin.x >= anchorLeft.maxX, "Left dock popover opens to the right of the tile")
    }
}
