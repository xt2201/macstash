import SwiftUI
import SideDockCore

public enum ClockStyle: String, Codable, Sendable, CaseIterable {
    case digital
    case analog
    case flip
}

public struct ClockConfig: Codable, Equatable, Sendable {
    public var style: ClockStyle
    public var is24Hour: Bool
    public var showSeconds: Bool
    public var timeZoneIdentifier: String

    public init(
        style: ClockStyle = .digital,
        is24Hour: Bool = true,
        showSeconds: Bool = false,
        timeZoneIdentifier: String = TimeZone.current.identifier
    ) {
        self.style = style
        self.is24Hour = is24Hour
        self.showSeconds = showSeconds
        self.timeZoneIdentifier = timeZoneIdentifier
    }
}

public struct ClockWidgetView: View {
    public let config: ClockConfig
    public let size: WidgetSize
    @State private var currentDate: Date = Date()
    @State private var timer: Timer?

    public init(config: ClockConfig, size: WidgetSize = .small) {
        self.config = config
        self.size = size
    }

    private var targetTimeZone: TimeZone {
        TimeZone(identifier: config.timeZoneIdentifier) ?? .current
    }

    private var timeFormatter: DateFormatter {
        let df = DateFormatter()
        df.timeZone = targetTimeZone
        if config.is24Hour {
            df.dateFormat = config.showSeconds ? "HH:mm:ss" : "HH:mm"
        } else {
            df.dateFormat = config.showSeconds ? "h:mm:ss a" : "h:mm a"
        }
        return df
    }

    public var body: some View {
        HStack(spacing: 6) {
            switch config.style {
            case .digital, .flip:
                VStack(spacing: 2) {
                    Text(timeFormatter.string(from: currentDate))
                        .font(.system(size: size == .small ? 13 : 15, weight: .semibold, design: .monospaced))
                        .foregroundColor(.primary)

                    if size != .small {
                        Text(targetTimeZone.localizedName(for: .generic, locale: .current) ?? targetTimeZone.identifier)
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            case .analog:
                AnalogClockFace(date: currentDate, timeZone: targetTimeZone)
                    .frame(width: size == .small ? 36 : 44, height: size == .small ? 36 : 44)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                self.currentDate = Date()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

private struct AnalogClockFace: View {
    let date: Date
    let timeZone: TimeZone

    var body: some View {
        GeometryReader { geo in
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: date) % 12
            let minute = calendar.component(.minute, from: date)
            let second = calendar.component(.second, from: date)

            let hourAngle = Double(hour) * 30.0 + Double(minute) * 0.5
            let minAngle = Double(minute) * 6.0
            let secAngle = Double(second) * 6.0

            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.3), lineWidth: 1.5)

                // Hour Hand
                HandShape(lengthFraction: 0.5)
                    .rotation(.degrees(hourAngle))
                    .stroke(Color.primary, lineWidth: 2)

                // Minute Hand
                HandShape(lengthFraction: 0.75)
                    .rotation(.degrees(minAngle))
                    .stroke(Color.primary.opacity(0.8), lineWidth: 1.5)

                // Second Hand
                HandShape(lengthFraction: 0.85)
                    .rotation(.degrees(secAngle))
                    .stroke(Color.red, lineWidth: 1)

                Circle()
                    .fill(Color.primary)
                    .frame(width: 4, height: 4)
            }
        }
    }
}

private struct HandShape: Shape {
    let lengthFraction: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let top = CGPoint(x: rect.midX, y: rect.midY - (rect.height / 2) * lengthFraction)
        path.move(to: center)
        path.addLine(to: top)
        return path
    }
}
