import SwiftUI
import SideDockCore
import SideDockWidgets
import MacStashCore

/// Per-widget configuration sheet allowing users to customize clock style/timezone,
/// weather city (via Open-Meteo geocoding), date display, system stats metrics,
/// pomodoro intervals, bookmarks, and widget size.
public struct WidgetConfigSheet: View {
    @Environment(\.dismiss) private var dismiss
    public let widgetItem: WidgetItem
    public let onSave: (WidgetItem) -> Void

    @State private var selectedSize: WidgetSize
    @State private var clockConfig: ClockConfig
    @State private var dateConfig: DateConfig
    @State private var weatherConfig: WeatherConfig
    @State private var statsConfig: SystemStatsConfig
    @State private var pomodoroConfig: PomodoroConfig
    @State private var bookmarksConfig: BookmarksConfig

    // Weather city search
    @State private var cityQuery: String = ""
    @State private var cityResults: [WeatherCity] = []
    @State private var isSearchingCity: Bool = false

    // Bookmarks quick add
    @State private var newBookmarkTitle: String = ""
    @State private var newBookmarkURL: String = ""

    private func localized(_ key: String) -> String {
        LocalizationService.shared.localized(key)
    }

    public init(widgetItem: WidgetItem, onSave: @escaping (WidgetItem) -> Void) {
        self.widgetItem = widgetItem
        self.onSave = onSave
        let data = widgetItem.configurationData ?? Data()
        _selectedSize = State(initialValue: widgetItem.size)
        _clockConfig = State(initialValue: (try? JSONDecoder().decode(ClockConfig.self, from: data)) ?? ClockConfig())
        _dateConfig = State(initialValue: (try? JSONDecoder().decode(DateConfig.self, from: data)) ?? DateConfig())
        _weatherConfig = State(initialValue: (try? JSONDecoder().decode(WeatherConfig.self, from: data)) ?? WeatherConfig())
        _statsConfig = State(initialValue: (try? JSONDecoder().decode(SystemStatsConfig.self, from: data)) ?? SystemStatsConfig())
        _pomodoroConfig = State(initialValue: (try? JSONDecoder().decode(PomodoroConfig.self, from: data)) ?? PomodoroConfig())
        _bookmarksConfig = State(initialValue: (try? JSONDecoder().decode(BookmarksConfig.self, from: data)) ?? BookmarksConfig())
    }

    private var descriptor: WidgetDescriptor? {
        WidgetRegistry.shared.descriptor(for: widgetItem.widgetKind)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: descriptor?.systemIconName ?? "square.grid.2x2")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color.accentColor.gradient))

                VStack(alignment: .leading, spacing: 1) {
                    Text(descriptor?.displayName ?? widgetItem.widgetKind)
                        .font(.system(size: 15, weight: .bold))
                    Text(localized("dock.widgetConfigTitle"))
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            Divider()

            // Size selector
            if let supported = descriptor?.supportedSizes, supported.count > 1 {
                HStack {
                    Text(localized("dock.widgetSize"))
                        .font(.system(size: 12, weight: .medium))
                    Spacer()
                    Picker("", selection: $selectedSize) {
                        ForEach(supported, id: \.self) { sz in
                            Text(sizeTitle(sz)).tag(sz)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                }
            }

            // Specific widget controls
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    widgetSpecificControls
                }
            }
            .frame(maxHeight: 280)

            Divider()

            HStack {
                Spacer()
                Button(localized("dock.cancel")) {
                    dismiss()
                }
                .buttonStyle(.bordered)

                Button(localized("dock.done")) {
                    commitAndSave()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(18)
        .frame(width: 420)
    }

    @ViewBuilder
    private var widgetSpecificControls: some View {
        switch widgetItem.widgetKind {
        case "clock":
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(localized("dock.clockStyle"))
                        .font(.system(size: 12, weight: .medium))
                    Spacer()
                    Picker("", selection: $clockConfig.style) {
                        Text(localized("dock.clockDigital")).tag(ClockStyle.digital)
                        Text(localized("dock.clockAnalog")).tag(ClockStyle.analog)
                        Text(localized("dock.clockFlip")).tag(ClockStyle.flip)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 220)
                }

                Toggle(localized("dock.clock24h"), isOn: $clockConfig.is24Hour)
                Toggle(localized("dock.clockSeconds"), isOn: $clockConfig.showSeconds)

                HStack {
                    Text(localized("dock.clockTimezone"))
                        .font(.system(size: 12, weight: .medium))
                    Spacer()
                    Picker("", selection: $clockConfig.timeZoneIdentifier) {
                        ForEach(commonTimeZones, id: \.self) { tz in
                            Text(tz).tag(tz)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 220)
                }
            }

        case "weather":
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("\(localized("dock.weatherCity")):")
                        .font(.system(size: 12, weight: .medium))
                    Text("\(weatherConfig.selectedCity.name), \(weatherConfig.selectedCity.country)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.accentColor)
                }

                HStack {
                    TextField(localized("dock.weatherSearchPlaceholder"), text: $cityQuery)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            Task { await searchWeatherCity() }
                        }
                    Button(localized("dock.weatherSearch")) {
                        Task { await searchWeatherCity() }
                    }
                    .disabled(cityQuery.trimmingCharacters(in: .whitespaces).isEmpty || isSearchingCity)
                }

                if !cityResults.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(cityResults) { city in
                            Button {
                                weatherConfig.selectedCity = city
                                cityResults = []
                            } label: {
                                HStack {
                                    Text("\(city.name), \(city.country)")
                                        .font(.system(size: 11.5))
                                    Spacer()
                                    if city.id == weatherConfig.selectedCity.id {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.accentColor)
                                    }
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(RoundedRectangle(cornerRadius: 6).fill(Color.primary.opacity(0.05)))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Toggle(localized("dock.weatherFahrenheit"), isOn: $weatherConfig.useFahrenheit)
            }

        case "date":
            VStack(alignment: .leading, spacing: 10) {
                Toggle(localized("dock.dateWeekday"), isOn: $dateConfig.showWeekday)
                Toggle(localized("dock.dateFullMonth"), isOn: $dateConfig.fullMonthName)
            }

        case "systemStats":
            VStack(alignment: .leading, spacing: 10) {
                Toggle(localized("dock.statsCPU"), isOn: $statsConfig.showCPU)
                Toggle(localized("dock.statsRAM"), isOn: $statsConfig.showRAM)
                Toggle(localized("dock.statsBattery"), isOn: $statsConfig.showBattery)
            }

        case "pomodoro":
            VStack(alignment: .leading, spacing: 10) {
                Stepper("\(localized("dock.pomodoroFocusMins")): \(pomodoroConfig.focusMinutes)", value: $pomodoroConfig.focusMinutes, in: 1...120)
                Stepper("\(localized("dock.pomodoroBreakMins")): \(pomodoroConfig.shortBreakMinutes)", value: $pomodoroConfig.shortBreakMinutes, in: 1...30)
            }

        case "bookmarks":
            VStack(alignment: .leading, spacing: 10) {
                Text(localized("dock.bookmarksTitle"))
                    .font(.system(size: 12, weight: .semibold))

                ForEach(bookmarksConfig.bookmarks) { bm in
                    HStack {
                        Image(systemName: bm.systemIcon)
                            .foregroundColor(.accentColor)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(bm.title).font(.system(size: 11.5, weight: .semibold))
                            Text(bm.urlString).font(.system(size: 10)).foregroundColor(.secondary).lineLimit(1)
                        }
                        Spacer()
                        Button {
                            bookmarksConfig.bookmarks.removeAll { $0.id == bm.id }
                        } label: {
                            Image(systemName: "trash").foregroundColor(.red).font(.system(size: 11))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(6)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.primary.opacity(0.04)))
                }

                HStack(spacing: 6) {
                    TextField(localized("dock.bookmarksName"), text: $newBookmarkTitle)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 110)
                    TextField(localized("dock.bookmarksURL"), text: $newBookmarkURL)
                        .textFieldStyle(.roundedBorder)
                    Button(localized("dock.bookmarksAdd")) {
                        let title = newBookmarkTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                        let url = newBookmarkURL.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !title.isEmpty, !url.isEmpty else { return }
                        let normalizedURL = url.hasPrefix("http") ? url : "https://\(url)"
                        bookmarksConfig.bookmarks.append(BookmarkItem(title: title, urlString: normalizedURL))
                        newBookmarkTitle = ""
                        newBookmarkURL = ""
                    }
                    .disabled(newBookmarkTitle.trimmingCharacters(in: .whitespaces).isEmpty || newBookmarkURL.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }

        default:
            if let desc = descriptor {
                Text(desc.description)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
    }

    private var commonTimeZones: [String] {
        let base = [
            TimeZone.current.identifier,
            "Asia/Ho_Chi_Minh",
            "Asia/Tokyo",
            "Asia/Singapore",
            "Asia/Seoul",
            "Europe/London",
            "Europe/Paris",
            "Europe/Berlin",
            "America/New_York",
            "America/Los_Angeles",
            "America/Chicago",
            "Australia/Sydney",
            "UTC"
        ]
        var seen = Set<String>()
        return base.filter { seen.insert($0).inserted }
    }

    private func sizeTitle(_ sz: WidgetSize) -> String {
        switch sz {
        case .small: return localized("dock.sizeSmall")
        case .medium: return localized("dock.sizeMedium")
        case .large: return localized("dock.sizeLarge")
        }
    }

    private func searchWeatherCity() async {
        let q = cityQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty,
              let encoded = q.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://geocoding-api.open-meteo.com/v1/search?name=\(encoded)&count=5&language=en&format=json") else {
            return
        }
        isSearchingCity = true
        defer { isSearchingCity = false }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let results = json["results"] as? [[String: Any]] {
                self.cityResults = results.compactMap { item in
                    guard let name = item["name"] as? String,
                          let lat = item["latitude"] as? Double,
                          let lon = item["longitude"] as? Double else { return nil }
                    let country = (item["country"] as? String) ?? ""
                    return WeatherCity(name: name, country: country, latitude: lat, longitude: lon)
                }
            }
        } catch {
            // Keep existing list silently
        }
    }

    private func commitAndSave() {
        var updated = widgetItem
        updated.size = selectedSize

        let encoder = JSONEncoder()
        switch widgetItem.widgetKind {
        case "clock":
            updated.configurationData = try? encoder.encode(clockConfig)
        case "weather":
            updated.configurationData = try? encoder.encode(weatherConfig)
        case "date":
            updated.configurationData = try? encoder.encode(dateConfig)
        case "systemStats":
            updated.configurationData = try? encoder.encode(statsConfig)
        case "pomodoro":
            updated.configurationData = try? encoder.encode(pomodoroConfig)
        case "bookmarks":
            updated.configurationData = try? encoder.encode(bookmarksConfig)
        default:
            break
        }

        onSave(updated)
        dismiss()
    }
}
