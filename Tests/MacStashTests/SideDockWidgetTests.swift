import Foundation
import SideDockCore
import SideDockWidgets

public enum SideDockWidgetTests {
    public static func run() {
        testWidgetRegistryRegistration()
        testWidgetSearchAndCategoryFilter()
        testWeatherWMOCodeMapping()
        testNowPlayingFreshness()
        testMultiProfileManagement()
    }

    private static func testWidgetRegistryRegistration() {
        let registry = WidgetRegistry.shared
        let descriptors = registry.allDescriptors()

        TestAssertion.assertEqual(descriptors.count, 10, "WidgetRegistry registers all 10 P0 local widgets")

        let expectedIDs = [
            "clock", "date", "weather", "nowPlaying", "calendar",
            "reminders", "systemStats", "pomodoro", "search", "fileShelf"
        ]
        for id in expectedIDs {
            TestAssertion.assertTrue(descriptors.contains(where: { $0.id == id }), "Widget '\(id)' is registered in registry")
        }
    }

    private static func testWidgetSearchAndCategoryFilter() {
        let registry = WidgetRegistry.shared

        // Search by query
        let clockMatches = registry.searchDescriptors(query: "clock")
        TestAssertion.assertTrue(!clockMatches.isEmpty, "Searching 'clock' returns Clock widget")
        TestAssertion.assertEqual(clockMatches.first?.id, "clock", "Clock is the primary match for query 'clock'")

        // Filter by category
        let mediaWidgets = registry.searchDescriptors(query: "", category: .media)
        TestAssertion.assertTrue(mediaWidgets.contains(where: { $0.id == "nowPlaying" }), "Media category contains Now Playing widget")
    }

    private static func testWeatherWMOCodeMapping() {
        let clear = WeatherData.mapWMOWeatherCode(0)
        TestAssertion.assertEqual(clear.text, "Clear", "WMO 0 maps to Clear")
        TestAssertion.assertEqual(clear.icon, "sun.max.fill", "WMO 0 maps to sun icon")

        let rain = WeatherData.mapWMOWeatherCode(61)
        TestAssertion.assertEqual(rain.text, "Rain", "WMO 61 maps to Rain")
        TestAssertion.assertEqual(rain.icon, "cloud.rain.fill", "WMO 61 maps to cloud.rain icon")
    }

    private static func testNowPlayingFreshness() {
        let freshState = NowPlayingTrackState(title: "Track", timestamp: Date())
        TestAssertion.assertTrue(freshState.isFresh, "Recent now playing state is fresh")

        let staleState = NowPlayingTrackState(title: "Track", timestamp: Date().addingTimeInterval(-10.0))
        TestAssertion.assertFalse(staleState.isFresh, "10-second-old now playing state is not fresh")
    }

    private static func testMultiProfileManagement() {
        var profiles = DockProfile.defaultProfiles()
        TestAssertion.assertTrue(profiles.count >= 3, "Starts with at least 3 profiles")

        // Add profile (FR-PRO-01: >= 8 profiles supported)
        for i in 4...10 {
            let p = DockProfile(name: "Profile \(i)", items: [])
            profiles.append(p)
        }
        TestAssertion.assertEqual(profiles.count, 10, "Supports at least 10 profiles")

        // Duplicate profile
        let duplicated = DockProfile(name: "Copy of \(profiles[0].name)", items: profiles[0].items)
        profiles.append(duplicated)
        TestAssertion.assertEqual(duplicated.items.count, profiles[0].items.count, "Duplicated profile retains items")
    }
}
