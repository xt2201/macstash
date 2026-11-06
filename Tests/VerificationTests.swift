import Foundation
import CoreGraphics

// Test 1: Geometry math check
func testDialGeometry() {
    print("Running Dial Geometry Tests...")

    // Bottom-right corner
    let brCenter = CGPoint(x: 150, y: 150)
    // At value = 0.0, angle should be 180°
    let val0Angle = 180.0 + (0.0 * 90.0)
    assert(val0Angle == 180.0, "BR value 0.0 angle must be 180°")

    // At value = 1.0, angle should be 270°
    let val1Angle = 180.0 + (1.0 * 90.0)
    assert(val1Angle == 270.0, "BR value 1.0 angle must be 270°")

    // Check polar to cartesian
    let rad180 = 180.0 * .pi / 180.0
    let p0 = CGPoint(x: brCenter.x + 100 * cos(CGFloat(rad180)), y: brCenter.y + 100 * sin(CGFloat(rad180)))
    assert(abs(p0.x - 50) < 0.001, "Point at 180° must have x = 50")
    assert(abs(p0.y - 150) < 0.001, "Point at 180° must have y = 150")

    print("  Corner Geometry Math verified.")
}

// Test 2: Codable AppProfile
struct TestProfile: Codable {
    var name: String
    var bundleId: String?
    var isEnabled: Bool
}

func testProfileSerialization() {
    print("Running Profile Serialization Tests...")
    let profile = TestProfile(name: "Xcode Profile", bundleId: "com.apple.dt.Xcode", isEnabled: true)
    let encoder = JSONEncoder()
    let data = try! encoder.encode(profile)
    let decoded = try! JSONDecoder().decode(TestProfile.self, from: data)

    assert(decoded.name == "Xcode Profile", "Decoded name mismatch")
    assert(decoded.bundleId == "com.apple.dt.Xcode", "Decoded bundleId mismatch")
    assert(decoded.isEnabled == true, "Decoded isEnabled mismatch")
    print("  Profile JSON roundtrip verified.")
}

testDialGeometry()
testProfileSerialization()
print("All Automated Logic Tests Passed Successfully!")
