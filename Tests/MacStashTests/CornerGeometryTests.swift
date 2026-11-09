import Foundation
import CoreGraphics
import MacStashCore

public enum CornerGeometryTests {
    public static func run() {
        testSingleDisplayAllCornersAreOuter()
        testHorizontalDualDisplayInnerCornersAreRejected()
        testVerticalDualDisplayInnerCornersAreRejected()
        testNegativeCoordinatesAndOffsetScreen()
        testHitZoneVertexContainment()
        testDirectCornerIsOuterCorner()
        testOuterRightEdge()
        testOuterLeftEdge()
    }

    private static func testSingleDisplayAllCornersAreOuter() {
        let screen = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        let allScreens = [screen]

        let tlPoint = CGPoint(x: 2, y: 1078)
        TestAssertion.assertTrue(CornerGeometry.isOuterCorner(point: tlPoint, corner: CornerPosition.topLeft, screen: screen, allScreens: allScreens))

        let trPoint = CGPoint(x: 1918, y: 1078)
        TestAssertion.assertTrue(CornerGeometry.isOuterCorner(point: trPoint, corner: CornerPosition.topRight, screen: screen, allScreens: allScreens))

        let blPoint = CGPoint(x: 2, y: 2)
        TestAssertion.assertTrue(CornerGeometry.isOuterCorner(point: blPoint, corner: CornerPosition.bottomLeft, screen: screen, allScreens: allScreens))

        let brPoint = CGPoint(x: 1918, y: 2)
        TestAssertion.assertTrue(CornerGeometry.isOuterCorner(point: brPoint, corner: CornerPosition.bottomRight, screen: screen, allScreens: allScreens))
    }

    private static func testHorizontalDualDisplayInnerCornersAreRejected() {
        let display1 = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        let display2 = CGRect(x: 1920, y: 0, width: 1920, height: 1080)
        let allScreens = [display1, display2]

        // Inner corners between display 1 and display 2 must be false
        let d1TRPoint = CGPoint(x: 1918, y: 1078)
        TestAssertion.assertFalse(CornerGeometry.isOuterCorner(point: d1TRPoint, corner: CornerPosition.topRight, screen: display1, allScreens: allScreens))

        let d1BRPoint = CGPoint(x: 1918, y: 2)
        TestAssertion.assertFalse(CornerGeometry.isOuterCorner(point: d1BRPoint, corner: CornerPosition.bottomRight, screen: display1, allScreens: allScreens))

        let d2TLPoint = CGPoint(x: 1922, y: 1078)
        TestAssertion.assertFalse(CornerGeometry.isOuterCorner(point: d2TLPoint, corner: CornerPosition.topLeft, screen: display2, allScreens: allScreens))

        let d2BLPoint = CGPoint(x: 1922, y: 2)
        TestAssertion.assertFalse(CornerGeometry.isOuterCorner(point: d2BLPoint, corner: CornerPosition.bottomLeft, screen: display2, allScreens: allScreens))

        // Outer boundaries
        let d1TLPoint = CGPoint(x: 2, y: 1078)
        TestAssertion.assertTrue(CornerGeometry.isOuterCorner(point: d1TLPoint, corner: CornerPosition.topLeft, screen: display1, allScreens: allScreens))

        let d2TRPoint = CGPoint(x: 3838, y: 1078)
        TestAssertion.assertTrue(CornerGeometry.isOuterCorner(point: d2TRPoint, corner: CornerPosition.topRight, screen: display2, allScreens: allScreens))
    }

    private static func testVerticalDualDisplayInnerCornersAreRejected() {
        let display1 = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        let display2 = CGRect(x: 0, y: 1080, width: 1920, height: 1080)
        let allScreens = [display1, display2]

        let d1TLPoint = CGPoint(x: 2, y: 1078)
        TestAssertion.assertFalse(CornerGeometry.isOuterCorner(point: d1TLPoint, corner: CornerPosition.topLeft, screen: display1, allScreens: allScreens))

        let d2BLPoint = CGPoint(x: 2, y: 1082)
        TestAssertion.assertFalse(CornerGeometry.isOuterCorner(point: d2BLPoint, corner: CornerPosition.bottomLeft, screen: display2, allScreens: allScreens))

        let d1BLPoint = CGPoint(x: 2, y: 2)
        TestAssertion.assertTrue(CornerGeometry.isOuterCorner(point: d1BLPoint, corner: CornerPosition.bottomLeft, screen: display1, allScreens: allScreens))

        let d2TLPoint = CGPoint(x: 2, y: 2158)
        TestAssertion.assertTrue(CornerGeometry.isOuterCorner(point: d2TLPoint, corner: CornerPosition.topLeft, screen: display2, allScreens: allScreens))
    }

    private static func testNegativeCoordinatesAndOffsetScreen() {
        let external = CGRect(x: -1920, y: 0, width: 1920, height: 1080)
        let builtIn = CGRect(x: 0, y: 0, width: 1512, height: 982)
        let allScreens = [external, builtIn]

        let blBuiltIn = CGPoint(x: 2, y: 2)
        TestAssertion.assertFalse(CornerGeometry.isOuterCorner(point: blBuiltIn, corner: CornerPosition.bottomLeft, screen: builtIn, allScreens: allScreens))

        let blExternal = CGPoint(x: -1918, y: 2)
        TestAssertion.assertTrue(CornerGeometry.isOuterCorner(point: blExternal, corner: CornerPosition.bottomLeft, screen: external, allScreens: allScreens))
    }

    private static func testHitZoneVertexContainment() {
        let frame = CGRect(x: 0, y: 0, width: 1512, height: 982)
        for corner in CornerPosition.allCases {
            let zone = HitZone(corner: corner, screenFrame: frame, sizePoints: 10.0)
            TestAssertion.assertTrue(zone.contains(point: zone.vertex))
        }

        let negFrame = CGRect(x: -1920, y: 0, width: 1920, height: 1080)
        for corner in CornerPosition.allCases {
            let zone = HitZone(corner: corner, screenFrame: negFrame, sizePoints: 10.0)
            TestAssertion.assertTrue(zone.contains(point: zone.vertex))
        }
    }

    private static func testDirectCornerIsOuterCorner() {
        let external = CGRect(x: -1920, y: 0, width: 1920, height: 1080)
        let builtIn = CGRect(x: 0, y: 0, width: 1512, height: 982)
        let allScreens = [external, builtIn]

        TestAssertion.assertTrue(CornerGeometry.isOuterCorner(corner: .topLeft, of: external, in: allScreens))
        TestAssertion.assertTrue(CornerGeometry.isOuterCorner(corner: .topRight, of: external, in: allScreens))
        TestAssertion.assertTrue(CornerGeometry.isOuterCorner(corner: .bottomLeft, of: external, in: allScreens))
        TestAssertion.assertFalse(CornerGeometry.isOuterCorner(corner: .bottomRight, of: external, in: allScreens))

        TestAssertion.assertFalse(CornerGeometry.isOuterCorner(corner: .topLeft, of: builtIn, in: allScreens))
        TestAssertion.assertTrue(CornerGeometry.isOuterCorner(corner: .topRight, of: builtIn, in: allScreens))
        TestAssertion.assertFalse(CornerGeometry.isOuterCorner(corner: .bottomLeft, of: builtIn, in: allScreens))
        TestAssertion.assertTrue(CornerGeometry.isOuterCorner(corner: .bottomRight, of: builtIn, in: allScreens))
    }

    private static func testOuterRightEdge() {
        let d1 = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        let d2 = CGRect(x: 1920, y: 0, width: 1920, height: 1080)
        let single = [d1]
        let dual = [d1, d2]

        TestAssertion.assertTrue(CornerGeometry.isOuterRightEdge(screen: d1, in: single))
        TestAssertion.assertFalse(CornerGeometry.isOuterRightEdge(screen: d1, in: dual))
        TestAssertion.assertTrue(CornerGeometry.isOuterRightEdge(screen: d2, in: dual))

        // Stacked vertically: both should have an outer right edge
        let d3 = CGRect(x: 0, y: 1080, width: 1920, height: 1080)
        let stacked = [d1, d3]
        TestAssertion.assertTrue(CornerGeometry.isOuterRightEdge(screen: d1, in: stacked))
        TestAssertion.assertTrue(CornerGeometry.isOuterRightEdge(screen: d3, in: stacked))

        // Vertically offset dual monitors (MacBook 982pt tall and External 1440pt tall offset upwards)
        let mb = CGRect(x: 0, y: 0, width: 1512, height: 982)
        let extOffset = CGRect(x: 1512, y: 400, width: 2560, height: 1440)
        let offsetDual = [mb, extOffset]
        TestAssertion.assertFalse(CornerGeometry.isOuterRightEdge(screen: mb, in: offsetDual), "MB right edge touches ext screen even with vertical offset")
        TestAssertion.assertTrue(CornerGeometry.isOuterRightEdge(screen: extOffset, in: offsetDual), "Ext right edge is outer right boundary")
    }

    private static func testOuterLeftEdge() {
        let d1 = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        let d2 = CGRect(x: 1920, y: 0, width: 1920, height: 1080)
        let dual = [d1, d2]

        TestAssertion.assertTrue(CornerGeometry.isOuterLeftEdge(screen: d1, in: dual), "d1 left edge is physical outer boundary")
        TestAssertion.assertFalse(CornerGeometry.isOuterLeftEdge(screen: d2, in: dual), "d2 left edge touches d1")

        // Vertically offset dual monitors
        let mb = CGRect(x: 0, y: 0, width: 1512, height: 982)
        let extOffset = CGRect(x: 1512, y: 400, width: 2560, height: 1440)
        let offsetDual = [mb, extOffset]
        TestAssertion.assertTrue(CornerGeometry.isOuterLeftEdge(screen: mb, in: offsetDual), "MB left edge is outer")
        TestAssertion.assertFalse(CornerGeometry.isOuterLeftEdge(screen: extOffset, in: offsetDual), "Ext left edge touches MB")
    }
}
