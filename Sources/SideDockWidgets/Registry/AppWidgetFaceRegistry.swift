import SwiftUI
import SideDockCore

/// Maps supported macOS applications to live Dock widget faces (dynamic app icon replacement).
public enum AppWidgetFaceRegistry {
    public static func defaultWidgetKind(forBundleID bundleID: String) -> String? {
        switch bundleID {
        case "com.apple.iCal", "com.apple.Calendar":
            return "date"
        case "com.apple.weather":
            return "weather"
        case "com.apple.Music", "com.spotify.client":
            return "nowPlaying"
        case "com.apple.clock":
            return "clock"
        case "com.apple.reminders":
            return "reminders"
        case "com.apple.ActivityMonitor":
            return "systemStats"
        default:
            return nil
        }
    }

    public static func supportedWidgetKinds() -> [String] {
        ["clock", "date", "weather", "nowPlaying", "calendar", "reminders", "systemStats", "batteries"]
    }

    @MainActor
    @ViewBuilder
    public static func makeFaceView(widgetKind: String) -> some View {
        let item = WidgetItem(widgetKind: widgetKind, size: .small)
        WidgetRegistry.shared.makeWidgetView(for: item)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
