import SwiftUI
import SideDockCore

public struct DateConfig: Codable, Equatable, Sendable {
    public var showWeekday: Bool
    public var fullMonthName: Bool

    public init(showWeekday: Bool = true, fullMonthName: Bool = true) {
        self.showWeekday = showWeekday
        self.fullMonthName = fullMonthName
    }
}

public struct DateWidgetView: View {
    public let config: DateConfig
    public let size: WidgetSize
    @State private var currentDate: Date = Date()

    public init(config: DateConfig = DateConfig(), size: WidgetSize = .small) {
        self.config = config
        self.size = size
    }

    private var weekdayFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateFormat = "EEE"
        return df
    }

    private var dayFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateFormat = "d"
        return df
    }

    private var monthFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateFormat = config.fullMonthName ? "MMMM" : "MMM"
        return df
    }

    public var body: some View {
        HStack(spacing: 6) {
            VStack(spacing: 1) {
                if config.showWeekday {
                    Text(weekdayFormatter.string(from: currentDate).uppercased())
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.red)
                }

                Text(dayFormatter.string(from: currentDate))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.primary)

                if size != .small {
                    Text(monthFormatter.string(from: currentDate))
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
    }
}
