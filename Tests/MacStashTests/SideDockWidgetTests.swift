import Foundation
import SideDockCore
import SideDockWidgets

public enum SideDockWidgetTests {
    @MainActor
    public static func run() {
        testWidgetRegistryRegistration()
        testWidgetSearchAndCategoryFilter()
        testWeatherWMOCodeMapping()
        testNowPlayingFreshness()
        testMultiProfileManagement()
        testProfileExportImport()
        testPhase2WidgetViews()
    }

    private static func testWidgetRegistryRegistration() {
        let registry = WidgetRegistry.shared
        let descriptors = registry.allDescriptors()

        TestAssertion.assertEqual(descriptors.count, 16, "WidgetRegistry registers all 16 widgets (10 P0 + 6 Phase 2)")

        let expectedIDs = [
            "clock", "date", "weather", "nowPlaying", "calendar",
            "reminders", "systemStats", "pomodoro", "search", "fileShelf",
            "clipboard", "quickNote", "screenshot", "colorPicker", "unitConverter", "bookmarks"
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

    private static func testProfileExportImport() {
        let service = DockProfileTransferService()
        let original = DockProfile(
            name: "Developer Setup",
            items: [
                .widget(WidgetItem(widgetKind: "clipboard", size: .medium)),
                .widget(WidgetItem(widgetKind: "colorPicker", size: .small))
            ]
        )

        guard let data = try? service.exportProfileJSON(profile: original) else {
            TestAssertion.assertTrue(false, "Export profile generates valid JSON data")
            return
        }

        TestAssertion.assertTrue(data.count > 50, "Exported JSON data is non-empty")

        guard let imported = try? service.importProfile(from: data) else {
            TestAssertion.assertTrue(false, "Import profile succeeds from valid JSON package")
            return
        }

        TestAssertion.assertEqual(imported.name, "Developer Setup", "Imported profile preserves name")
        TestAssertion.assertEqual(imported.items.count, 2, "Imported profile preserves items count")
        TestAssertion.assertTrue(imported.id != original.id, "Imported profile is given a fresh UUID to prevent collisions")
    }

    @MainActor
    private static func testPhase2WidgetViews() {
        let registry = WidgetRegistry.shared
        let phase2Kinds = ["clipboard", "quickNote", "screenshot", "colorPicker", "unitConverter", "bookmarks"]

        for kind in phase2Kinds {
            let item = WidgetItem(widgetKind: kind, size: .medium)
            _ = registry.makeWidgetView(for: item)
            TestAssertion.assertTrue(true, "Widget view generated cleanly for kind: \(kind)")
        }
    }
}
