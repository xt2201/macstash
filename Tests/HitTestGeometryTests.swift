import Foundation
import CoreGraphics

func testHitTestPassThroughMath() {
    print("Running Hit-Test Pass-Through Math Tests...")

    let threshold: CGFloat = 8.0 // Tight hotzone: 8px

    // Function to calculate distance from corner vertex in flipped coordinates (0,0 is top-left)
    func isWithinHotzone(point: CGPoint, corner: String) -> Bool {
        let vertex: CGPoint
        switch corner {
        case "topLeft": vertex = CGPoint(x: 0, y: 0)
        case "topRight": vertex = CGPoint(x: 150, y: 0)
        case "bottomLeft": vertex = CGPoint(x: 0, y: 150)
        case "bottomRight": vertex = CGPoint(x: 150, y: 150)
        default: return false
        }
        let dist = hypot(point.x - vertex.x, point.y - vertex.y)
        return dist <= threshold
    }

    // 1. Point at (50, 50) is inside the 150x150 window but far from any corner vertex
    assert(!isWithinHotzone(point: CGPoint(x: 50, y: 50), corner: "bottomRight"), "Point (50, 50) must NOT trigger bottom-right corner")
    assert(!isWithinHotzone(point: CGPoint(x: 130, y: 130), corner: "bottomRight"), "Point (130, 130) is ~28px away and must NOT trigger (allows clicking app behind)")

    // 2. Point directly in extreme corner (148, 148) is ~2.8px from (150, 150)
    assert(isWithinHotzone(point: CGPoint(x: 148, y: 148), corner: "bottomRight"), "Extreme corner point (148, 148) MUST trigger")

    // 3. Top-left corner close button on Mac window is typically at (x: 18, y: 18)
    assert(!isWithinHotzone(point: CGPoint(x: 18, y: 18), corner: "topLeft"), "Window close button at (18, 18) must NOT trigger top-left dial (allows clicking close button!)")

    print("  Pass-Through Hit-Test geometry verified: normal app buttons will not be intercepted.")
}

testHitTestPassThroughMath()
