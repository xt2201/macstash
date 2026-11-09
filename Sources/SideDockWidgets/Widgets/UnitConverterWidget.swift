import SwiftUI
import AppKit
import SideDockCore

public struct UnitConverterConfig: Codable, Equatable, Sendable {
    public var lastMode: String

    public init(lastMode: String = "length") {
        self.lastMode = lastMode
    }
}

public struct UnitConverterWidgetView: View {
    public let config: UnitConverterConfig
    public let size: WidgetSize

    @State private var inputValue: Double = 1.0
    @State private var mode: String // "length", "temp", "weight", "currency"

    public init(config: UnitConverterConfig = UnitConverterConfig(), size: WidgetSize = .medium) {
        self.config = config
        self.size = size
        _mode = State(initialValue: config.lastMode)
    }

    public var body: some View {
        Group {
            switch size {
            case .small:
                smallView
            case .medium, .large:
                mediumView
            }
        }
    }

    private var smallView: some View {
        Button {
            cycleMode()
        } label: {
            VStack(spacing: 2) {
                Image(systemName: modeIcon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.accentColor)
                Text(modeAbbreviation)
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.secondary)
            }
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("Unit Converter: Click to cycle mode (\(mode))")
    }

    private var mediumView: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Button {
                    cycleMode()
                } label: {
                    Label(modeTitle, systemImage: modeIcon)
                        .font(.system(size: 9, weight: .bold))
                }
                .buttonStyle(.plain)

                Spacer()

                HStack(spacing: 4) {
                    Button("-") { if inputValue > 1 { inputValue -= 1 } }
                        .font(.system(size: 9))
                    Text("\(Int(inputValue))")
                        .font(.system(size: 9, weight: .semibold))
                    Button("+") { inputValue += 1 }
                        .font(.system(size: 9))
                }
            }

            Text(convertedString)
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(6)
        .frame(width: size == .large ? 180 : 130, height: 44)
    }

    private var modeIcon: String {
        switch mode {
        case "temp": return "thermometer.medium"
        case "weight": return "scalemass"
        case "currency": return "dollarsign.circle"
        default: return "ruler"
        }
    }

    private var modeTitle: String {
        switch mode {
        case "temp": return "Temp"
        case "weight": return "Weight"
        case "currency": return "Currency"
        default: return "Length"
        }
    }

    private var modeAbbreviation: String {
        switch mode {
        case "temp": return "°C/°F"
        case "weight": return "kg/lb"
        case "currency": return "$/€/₫"
        default: return "cm/in"
        }
    }

    private var convertedString: String {
        switch mode {
        case "temp":
            let f = (inputValue * 9.0 / 5.0) + 32.0
            return "\(Int(inputValue))°C = \(String(format: "%.1f", f))°F"
        case "weight":
            let lb = inputValue * 2.20462
            return "\(Int(inputValue)) kg = \(String(format: "%.1f", lb)) lb"
        case "currency":
            let vnd = inputValue * 25400
            return "$\(Int(inputValue)) ≈ \(Int(vnd))₫"
        default:
            let inch = inputValue / 2.54
            return "\(Int(inputValue)) cm = \(String(format: "%.1f", inch)) in"
        }
    }

    private func cycleMode() {
        let modes = ["length", "temp", "weight", "currency"]
        if let idx = modes.firstIndex(of: mode) {
            mode = modes[(idx + 1) % modes.count]
        } else {
            mode = "length"
        }
    }
}
