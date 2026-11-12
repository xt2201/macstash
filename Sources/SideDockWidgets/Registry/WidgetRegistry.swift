import SwiftUI
import SideDockCore

public final class WidgetRegistry: @unchecked Sendable {
    public static let shared = WidgetRegistry()

    private let descriptors: [WidgetDescriptor]

    public init() {
        self.descriptors = [
            WidgetDescriptor(
                id: "clock",
                displayName: "Clock",
                category: .general,
                systemIconName: "clock.fill",
                description: "Digital, analog, or flip clock with comprehensive multi-timezone support.",
                supportedSizes: [.small, .medium],
                requiredPermissions: [.none]
            ),
            WidgetDescriptor(
                id: "date",
                displayName: "Date",
                category: .general,
                systemIconName: "calendar.badge.clock",
                description: "Clean date display with weekday and full untruncated month name.",
                supportedSizes: [.small, .medium],
                requiredPermissions: [.none]
            ),
            WidgetDescriptor(
                id: "weather",
                displayName: "Weather",
                category: .general,
                systemIconName: "cloud.sun.fill",
                description: "Current weather and multi-day forecast powered by Open-Meteo with manual city selection.",
                supportedSizes: [.small, .medium, .large],
                requiredPermissions: [.none],
                networkDomains: ["api.open-meteo.com", "geocoding-api.open-meteo.com"],
                privacyNote: "Calls Open-Meteo API for forecasts without sending personal identifiers."
            ),
            WidgetDescriptor(
                id: "nowPlaying",
                displayName: "Now Playing",
                category: .media,
                systemIconName: "music.note",
                description: "Real-time playback controls, track title, and progress for Apple Music and Spotify.",
                supportedSizes: [.small, .medium, .large],
                requiredPermissions: [.appleEvents],
                privacyNote: "Communicates directly with Music and Spotify using local AppleScript."
            ),
            WidgetDescriptor(
                id: "calendar",
                displayName: "Calendar",
                category: .productivity,
                systemIconName: "calendar",
                description: "Upcoming events, countdown, and 1-click video meeting Join buttons.",
                supportedSizes: [.small, .medium, .large],
                requiredPermissions: [.calendar],
                privacyNote: "Reads calendar events strictly on-device via Apple EventKit."
            ),
            WidgetDescriptor(
                id: "reminders",
                displayName: "Reminders",
                category: .productivity,
                systemIconName: "checklist",
                description: "View due tasks, check off completed items, and quick-add tasks.",
                supportedSizes: [.small, .medium, .large],
                requiredPermissions: [.reminders],
                privacyNote: "Interacts locally with Apple Reminders via EventKit."
            ),
            WidgetDescriptor(
                id: "systemStats",
                displayName: "System Stats",
                category: .system,
                systemIconName: "cpu",
                description: "Live CPU usage, RAM utilization, battery percentage, and charging status.",
                supportedSizes: [.small, .medium, .large],
                requiredPermissions: [.none]
            ),
            WidgetDescriptor(
                id: "pomodoro",
                displayName: "Pomodoro",
                category: .productivity,
                systemIconName: "timer",
                description: "Focus sprints and break cycles with desktop completion alerts.",
                supportedSizes: [.small, .medium],
                requiredPermissions: [.notifications]
            ),
            WidgetDescriptor(
                id: "search",
                displayName: "Search",
                category: .utility,
                systemIconName: "magnifyingglass",
                description: "Spotlight file and application launcher with fast keyboard activation.",
                supportedSizes: [.small, .medium, .large],
                requiredPermissions: [.none]
            ),
            WidgetDescriptor(
                id: "fileShelf",
                displayName: "File Shelf",
                category: .utility,
                systemIconName: "tray.full.fill",
                description: "Drop temporary files onto the dock to hold and reuse across apps.",
                supportedSizes: [.small, .medium],
                requiredPermissions: [.none]
            ),
            WidgetDescriptor(
                id: "clipboard",
                displayName: "Clipboard History",
                category: .utility,
                systemIconName: "doc.on.clipboard",
                description: "Local clipboard history monitor with quick click-to-copy.",
                supportedSizes: [.small, .medium, .large],
                requiredPermissions: [.none]
            ),
            WidgetDescriptor(
                id: "quickNote",
                displayName: "Quick Note",
                category: .productivity,
                systemIconName: "note.text",
                description: "Lightweight scratchpad for instant notes on your dock.",
                supportedSizes: [.small, .medium, .large],
                requiredPermissions: [.none]
            ),
            WidgetDescriptor(
                id: "screenshot",
                displayName: "Screenshot Launcher",
                category: .utility,
                systemIconName: "camera.viewfinder",
                description: "One-click interactive area, fullscreen capture, and screen recording.",
                supportedSizes: [.small, .medium],
                requiredPermissions: [.none]
            ),
            WidgetDescriptor(
                id: "colorPicker",
                displayName: "Color Picker",
                category: .utility,
                systemIconName: "eyedropper",
                description: "Sample pixel color anywhere on screen and copy HEX codes.",
                supportedSizes: [.small, .medium],
                requiredPermissions: [.none]
            ),
            WidgetDescriptor(
                id: "unitConverter",
                displayName: "Unit Converter",
                category: .utility,
                systemIconName: "ruler",
                description: "Offline converter for Length, Temp, Weight, and Currency reference rates.",
                supportedSizes: [.small, .medium, .large],
                requiredPermissions: [.none]
            ),
            WidgetDescriptor(
                id: "bookmarks",
                displayName: "Bookmarks",
                category: .utility,
                systemIconName: "bookmark.fill",
                description: "Quick links to your most frequent websites and developer docs.",
                supportedSizes: [.small, .medium],
                requiredPermissions: [.none]
            ),
            WidgetDescriptor(
                id: "batteries",
                displayName: "Batteries",
                category: .system,
                systemIconName: "battery.100.bolt",
                description: "Live battery levels for Mac and connected Bluetooth peripherals.",
                supportedSizes: [.small, .medium, .large],
                requiredPermissions: [.none]
            ),
            WidgetDescriptor(
                id: "photoFrame",
                displayName: "Photo Frame",
                category: .general,
                systemIconName: "photo.on.rectangle.angled",
                description: "Slideshow frame cycling through photos from a local folder.",
                supportedSizes: [.small, .medium, .large],
                requiredPermissions: [.none]
            )
        ]
    }

    public func allDescriptors() -> [WidgetDescriptor] {
        return descriptors
    }

    public func descriptor(for id: String) -> WidgetDescriptor? {
        return descriptors.first(where: { $0.id == id })
    }

    public func searchDescriptors(query: String, category: WidgetCategory? = nil) -> [WidgetDescriptor] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return descriptors.filter { desc in
            let matchesCat = category == nil || desc.category == category
            if !matchesCat { return false }
            if trimmed.isEmpty { return true }
            return desc.displayName.lowercased().contains(trimmed) ||
                   desc.description.lowercased().contains(trimmed) ||
                   desc.id.lowercased().contains(trimmed)
        }
    }

    @MainActor
    @ViewBuilder
    public func makeWidgetView(for item: WidgetItem) -> some View {
        switch item.widgetKind {
        case "clock":
            let config = (try? JSONDecoder().decode(ClockConfig.self, from: item.configurationData ?? Data())) ?? ClockConfig()
            ClockWidgetView(config: config, size: item.size)
        case "date":
            let config = (try? JSONDecoder().decode(DateConfig.self, from: item.configurationData ?? Data())) ?? DateConfig()
            DateWidgetView(config: config, size: item.size)
        case "weather":
            let config = (try? JSONDecoder().decode(WeatherConfig.self, from: item.configurationData ?? Data())) ?? WeatherConfig()
            WeatherWidgetView(config: config, size: item.size)
        case "nowPlaying":
            let config = (try? JSONDecoder().decode(NowPlayingConfig.self, from: item.configurationData ?? Data())) ?? NowPlayingConfig()
            NowPlayingWidgetView(config: config, size: item.size)
        case "calendar":
            let config = (try? JSONDecoder().decode(CalendarConfig.self, from: item.configurationData ?? Data())) ?? CalendarConfig()
            CalendarWidgetView(config: config, size: item.size)
        case "reminders":
            let config = (try? JSONDecoder().decode(RemindersConfig.self, from: item.configurationData ?? Data())) ?? RemindersConfig()
            RemindersWidgetView(config: config, size: item.size)
        case "systemStats":
            let config = (try? JSONDecoder().decode(SystemStatsConfig.self, from: item.configurationData ?? Data())) ?? SystemStatsConfig()
            SystemStatsWidgetView(config: config, size: item.size)
        case "pomodoro":
            let config = (try? JSONDecoder().decode(PomodoroConfig.self, from: item.configurationData ?? Data())) ?? PomodoroConfig()
            PomodoroWidgetView(config: config, size: item.size)
        case "search":
            let config = (try? JSONDecoder().decode(SearchConfig.self, from: item.configurationData ?? Data())) ?? SearchConfig()
            SearchWidgetView(config: config, size: item.size)
        case "fileShelf":
            let config = (try? JSONDecoder().decode(FileShelfConfig.self, from: item.configurationData ?? Data())) ?? FileShelfConfig()
            FileShelfWidgetView(config: config, size: item.size)
        case "clipboard":
            let config = (try? JSONDecoder().decode(ClipboardConfig.self, from: item.configurationData ?? Data())) ?? ClipboardConfig()
            ClipboardWidgetView(config: config, size: item.size)
        case "quickNote":
            let config = (try? JSONDecoder().decode(QuickNoteConfig.self, from: item.configurationData ?? Data())) ?? QuickNoteConfig()
            QuickNoteWidgetView(config: config, size: item.size)
        case "screenshot":
            let config = (try? JSONDecoder().decode(ScreenshotConfig.self, from: item.configurationData ?? Data())) ?? ScreenshotConfig()
            ScreenshotWidgetView(config: config, size: item.size)
        case "colorPicker":
            let config = (try? JSONDecoder().decode(ColorPickerConfig.self, from: item.configurationData ?? Data())) ?? ColorPickerConfig()
            ColorPickerWidgetView(config: config, size: item.size)
        case "unitConverter":
            let config = (try? JSONDecoder().decode(UnitConverterConfig.self, from: item.configurationData ?? Data())) ?? UnitConverterConfig()
            UnitConverterWidgetView(config: config, size: item.size)
        case "bookmarks":
            let config = (try? JSONDecoder().decode(BookmarksConfig.self, from: item.configurationData ?? Data())) ?? BookmarksConfig()
            BookmarksWidgetView(config: config, size: item.size)
        case "batteries":
            let config = (try? JSONDecoder().decode(BatteriesConfig.self, from: item.configurationData ?? Data())) ?? BatteriesConfig()
            BatteriesWidgetView(config: config, size: item.size)
        case "photoFrame":
            let config = (try? JSONDecoder().decode(PhotoFrameConfig.self, from: item.configurationData ?? Data())) ?? PhotoFrameConfig()
            PhotoFrameWidgetView(config: config, size: item.size)
        default:
            HStack {
                Image(systemName: "exclamationmark.triangle")
                Text(item.customTitle ?? item.widgetKind)
            }
            .font(.system(size: 11))
            .padding(4)
        }
    }

    @MainActor
    @ViewBuilder
    public func makeExpandedView(for item: WidgetItem) -> some View {
        WidgetExpandedDetailView(item: item)
    }
}
