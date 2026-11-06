import Foundation
import MacStashCore

public enum BrightnessPolicyTests {
    public static func run() {
        testClamping()
        testMethodResolution()
        testKeyboardBrightnessPolicy()
    }

    private static func testKeyboardBrightnessPolicy() {
        // Clamping
        TestAssertion.assertEqual(KeyboardBrightnessPolicy.clamp(-0.2), Float(0.0))
        TestAssertion.assertEqual(KeyboardBrightnessPolicy.clamp(1.4), Float(1.0))
        TestAssertion.assertEqual(KeyboardBrightnessPolicy.clamp(0.75), Float(0.75))

        // Toggle
        TestAssertion.assertEqual(KeyboardBrightnessPolicy.toggle(current: 0.8), Float(0.0))
        TestAssertion.assertEqual(KeyboardBrightnessPolicy.toggle(current: 0.1), Float(0.0))
        TestAssertion.assertEqual(KeyboardBrightnessPolicy.toggle(current: 0.0), Float(0.6))
        TestAssertion.assertEqual(KeyboardBrightnessPolicy.toggle(current: 0.04), Float(0.6))

        // Significant change
        TestAssertion.assertTrue(KeyboardBrightnessPolicy.isSignificantChange(from: 0.0, to: 0.05), "Detects 0.05 change")
        TestAssertion.assertFalse(KeyboardBrightnessPolicy.isSignificantChange(from: 0.50001, to: 0.50002), "Ignores negligible change")
    }

    private static func testClamping() {
        TestAssertion.assertEqual(BrightnessPolicy.clamp(-0.5), Float(0.0))
        TestAssertion.assertEqual(BrightnessPolicy.clamp(1.5), Float(1.0))
        TestAssertion.assertEqual(BrightnessPolicy.clamp(0.42), Float(0.42))
    }

    private static func testMethodResolution() {
        let r1 = BrightnessPolicy.resolveActualMethod(preferred: .auto, isBuiltIn: true, isDDCSupported: false)
        TestAssertion.assertEqual(r1.method, BrightnessMethod.builtIn)

        let r2 = BrightnessPolicy.resolveActualMethod(preferred: .auto, isBuiltIn: false, isDDCSupported: true)
        TestAssertion.assertEqual(r2.method, BrightnessMethod.ddc)

        let r3 = BrightnessPolicy.resolveActualMethod(preferred: .auto, isBuiltIn: false, isDDCSupported: false)
        TestAssertion.assertEqual(r3.method, BrightnessMethod.software)

        let r4 = BrightnessPolicy.resolveActualMethod(preferred: .software, isBuiltIn: false, isDDCSupported: true)
        TestAssertion.assertEqual(r4.method, BrightnessMethod.software)
    }
}
