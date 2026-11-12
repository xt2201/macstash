import Foundation
import MacStashCore
import MacStashDesignSystem

@MainActor
public enum DesignSystemTests {
    public static func run() {
        testSpacingAndRadiiTokens()
        testTypographyTokens()
        testColorTokens()
        testAppIconCacheBehavior()
    }

    private static func testSpacingAndRadiiTokens() {
        // Spacing scale is strictly geometric 4pt/8pt grid
        TestAssertion.assertEqual(DSSpacing.xxs, 2.0, "DSSpacing.xxs must be 2.0")
        TestAssertion.assertEqual(DSSpacing.xs, 4.0, "DSSpacing.xs must be 4.0")
        TestAssertion.assertEqual(DSSpacing.sm, 8.0, "DSSpacing.sm must be 8.0")
        TestAssertion.assertEqual(DSSpacing.md, 12.0, "DSSpacing.md must be 12.0")
        TestAssertion.assertEqual(DSSpacing.lg, 16.0, "DSSpacing.lg must be 16.0")
        TestAssertion.assertEqual(DSSpacing.xl, 24.0, "DSSpacing.xl must be 24.0")
        TestAssertion.assertEqual(DSSpacing.xxl, 32.0, "DSSpacing.xxl must be 32.0")

        // Radius continuous tokens
        TestAssertion.assertEqual(DSRadius.xs, 5.0, "DSRadius.xs must be 5.0")
        TestAssertion.assertEqual(DSRadius.sm, 8.0, "DSRadius.sm must be 8.0")
        TestAssertion.assertEqual(DSRadius.md, 12.0, "DSRadius.md must be 12.0")
        TestAssertion.assertEqual(DSRadius.lg, 16.0, "DSRadius.lg must be 16.0")
        TestAssertion.assertEqual(DSRadius.xl, 20.0, "DSRadius.xl must be 20.0")
        TestAssertion.assertEqual(DSRadius.pill, 999.0, "DSRadius.pill must be 999.0")
    }

    private static func testTypographyTokens() {
        // Typography scale
        TestAssertion.assertEqual(DSTypography.micro, 10.0, "Micro size must be 10.0pt")
        TestAssertion.assertEqual(DSTypography.caption, 11.0, "Caption size must be 11.0pt")
        TestAssertion.assertEqual(DSTypography.bodySmall, 12.0, "BodySmall size must be 12.0pt")
        TestAssertion.assertEqual(DSTypography.body, 13.0, "Body size must be 13.0pt")
        TestAssertion.assertEqual(DSTypography.subheadline, 14.0, "Subheadline size must be 14.0pt")
        TestAssertion.assertEqual(DSTypography.headline, 15.0, "Headline size must be 15.0pt")
        TestAssertion.assertEqual(DSTypography.title, 18.0, "Title size must be 18.0pt")
        TestAssertion.assertEqual(DSTypography.hero, 22.0, "Hero size must be 22.0pt")
    }

    private static func testColorTokens() {
        // Action gradients have at least 2 stops
        let volColors = DSColor.actionGradient(for: .volume)
        TestAssertion.assertTrue(volColors.count >= 2, "Volume action gradient must have at least 2 colors")

        let brightColors = DSColor.actionGradient(for: .brightness)
        TestAssertion.assertTrue(brightColors.count >= 2, "Brightness action gradient must have at least 2 colors")

        let timerColors = DSColor.actionGradient(for: .timer)
        TestAssertion.assertTrue(timerColors.count >= 2, "Timer action gradient must have at least 2 colors")
    }

    private static func testAppIconCacheBehavior() {
        let cache = AppIconCache.shared
        cache.clear()
        let icon1 = cache.icon(forPath: "/System/Applications/Calculator.app", targetSize: CGSize(width: 36, height: 36))
        let icon2 = cache.icon(forPath: "/System/Applications/Calculator.app", targetSize: CGSize(width: 36, height: 36))
        TestAssertion.assertEqual(icon1.size.width, 36.0, "Icon size width matches requested")
        TestAssertion.assertEqual(icon2.size.width, 36.0, "Cached icon size width matches requested")
        cache.clear()
    }
}
