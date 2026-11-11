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

    private var flipComponents: (hour: String, minute: String, suffix: String) {
        var cal = Calendar.current
        cal.timeZone = targetTimeZone
        let h24 = cal.component(.hour, from: currentDate)
        let m = cal.component(.minute, from: currentDate)
        if config.is24Hour {
            return (String(format: "%02d", h24), String(format: "%02d", m), "")
        } else {
            let h12 = h24 % 12 == 0 ? 12 : h24 % 12
            let ampm = h24 >= 12 ? "PM" : "AM"
            return (String(format: "%02d", h12), String(format: "%02d", m), ampm)
        }
    }

    public var body: some View {
        HStack(spacing: 6) {
            switch config.style {
            case .digital:
                VStack(spacing: 2) {
                    Text(timeFormatter.string(from: currentDate))
                        .font(.system(size: size == .small ? 13 : 15, weight: .semibold, design: .monospaced))
                        .monospacedDigit()
                        .foregroundColor(.primary)

                    if size != .small {
                        Text(targetTimeZone.localizedName(for: .shortGeneric, locale: .current) ?? targetTimeZone.identifier)
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            case .flip:
                let parts = flipComponents
                HStack(spacing: 3) {
                    flipCard(parts.hour)
                    Text(":")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                    flipCard(parts.minute)
                    if !parts.suffix.isEmpty && size != .small {
                        Text(parts.suffix)
                            .font(.system(size: 8.5, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                }
            case .analog:
                AnalogClockFace(date: currentDate, timeZone: targetTimeZone)
                    .frame(width: size == .small ? 36 : 40, height: size == .small ? 36 : 40)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }

    private func flipCard(_ text: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(Color.primary.opacity(0.10))
                .overlay(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.14), lineWidth: 0.6)
                )

            Text(text)
                .font(.system(size: size == .small ? 12 : 14, weight: .bold, design: .monospaced))
                .monospacedDigit()
                .foregroundColor(.primary)

            Rectangle()
                .fill(Color.primary.opacity(0.16))
                .frame(height: 0.8)
        }
        .frame(width: size == .small ? 22 : 26, height: size == .small ? 26 : 30)
    }

    private func startTimer() {
        stopTimer()
        currentDate = Date()
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
        GeometryReader { _ in
            var calendar = Calendar.current
            let _ = (calendar.timeZone = timeZone)
            let hour = calendar.component(.hour, from: date) % 12
            let minute = calendar.component(.minute, from: date)
            let second = calendar.component(.second, from: date)

            let hourAngle = Double(hour) * 30.0 + Double(minute) * 0.5
            let minAngle = Double(minute) * 6.0
            let secAngle = Double(second) * 6.0

            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.35), lineWidth: 1.5)

                HandShape(lengthFraction: 0.52)
                    .rotation(.degrees(hourAngle))
                    .stroke(Color.primary, style: StrokeStyle(lineWidth: 2, lineCap: .round))

                HandShape(lengthFraction: 0.76)
                    .rotation(.degrees(minAngle))
                    .stroke(Color.primary.opacity(0.85), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))

                HandShape(lengthFraction: 0.86)
                    .rotation(.degrees(secAngle))
                    .stroke(Color.red, style: StrokeStyle(lineWidth: 1, lineCap: .round))

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
