import SwiftUI
import SideDockCore

public struct WeatherCity: Codable, Equatable, Sendable, Identifiable {
    public var id: String { "\(name)_\(latitude)_\(longitude)" }
    public let name: String
    public let country: String
    public let latitude: Double
    public let longitude: Double

    public init(name: String, country: String, latitude: Double, longitude: Double) {
        self.name = name
        self.country = country
        self.latitude = latitude
        self.longitude = longitude
    }
}

public struct WeatherConfig: Codable, Equatable, Sendable {
    public var selectedCity: WeatherCity
    public var useFahrenheit: Bool

    public init(
        selectedCity: WeatherCity = WeatherCity(name: "Hanoi", country: "Vietnam", latitude: 21.0285, longitude: 105.8542),
        useFahrenheit: Bool = false
    ) {
        self.selectedCity = selectedCity
        self.useFahrenheit = useFahrenheit
    }
}

public struct WeatherData: Codable, Equatable, Sendable {
    public let currentTemperature: Double
    public let weatherCode: Int
    public let dailyHigh: Double
    public let dailyLow: Double
    public let conditionText: String
    public let systemIcon: String

    public init(
        currentTemperature: Double = 26.0,
        weatherCode: Int = 0,
        dailyHigh: Double = 30.0,
        dailyLow: Double = 22.0,
        conditionText: String = "Clear",
        systemIcon: String = "sun.max.fill"
    ) {
        self.currentTemperature = currentTemperature
        self.weatherCode = weatherCode
        self.dailyHigh = dailyHigh
        self.dailyLow = dailyLow
        self.conditionText = conditionText
        self.systemIcon = systemIcon
    }

    public static func mapWMOWeatherCode(_ code: Int) -> (text: String, icon: String) {
        switch code {
        case 0: return ("Clear", "sun.max.fill")
        case 1, 2, 3: return ("Partly Cloudy", "cloud.sun.fill")
        case 45, 48: return ("Fog", "cloud.fog.fill")
        case 51, 53, 55, 61, 63, 65: return ("Rain", "cloud.rain.fill")
        case 71, 73, 75: return ("Snow", "snowflake")
        case 95, 96, 99: return ("Thunderstorm", "cloud.bolt.rain.fill")
        default: return ("Partly Cloudy", "cloud.sun.fill")
        }
    }
}

public struct WeatherWidgetView: View {
    public let config: WeatherConfig
    public let size: WidgetSize
    @State private var weatherData: WeatherData = WeatherData()
    @State private var isLoading: Bool = false

    public init(config: WeatherConfig = WeatherConfig(), size: WidgetSize = .medium) {
        self.config = config
        self.size = size
    }

    private var formattedTemp: String {
        let temp = config.useFahrenheit ? (weatherData.currentTemperature * 9 / 5 + 32) : weatherData.currentTemperature
        let unit = config.useFahrenheit ? "°F" : "°C"
        return "\(Int(round(temp)))\(unit)"
    }

    public var body: some View {
        HStack(spacing: 8) {
            Image(systemName: weatherData.systemIcon)
                .font(.system(size: size == .small ? 16 : 20))
                .foregroundColor(.yellow)

            VStack(alignment: .leading, spacing: 2) {
                Text(formattedTemp)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.primary)

                if size != .small {
                    Text(config.selectedCity.name)
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .task {
            await fetchWeather()
        }
    }

    private func fetchWeather() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        let lat = config.selectedCity.latitude
        let lon = config.selectedCity.longitude
        guard let url = URL(string: "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lon)&current_weather=true&daily=temperature_2m_max,temperature_2m_min&timezone=auto") else {
            return
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return }

            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let current = json["current_weather"] as? [String: Any],
               let temp = current["temperature"] as? Double,
               let code = current["weathercode"] as? Int {
                let mapped = WeatherData.mapWMOWeatherCode(code)
                var high = temp
                var low = temp
                if let daily = json["daily"] as? [String: Any],
                   let maxs = daily["temperature_2m_max"] as? [Double], let firstMax = maxs.first,
                   let mins = daily["temperature_2m_min"] as? [Double], let firstMin = mins.first {
                    high = firstMax
                    low = firstMin
                }
                self.weatherData = WeatherData(
                    currentTemperature: temp,
                    weatherCode: code,
                    dailyHigh: high,
                    dailyLow: low,
                    conditionText: mapped.text,
                    systemIcon: mapped.icon
                )
            }
        } catch {
            // Keep cached weather on error
        }
    }
}
