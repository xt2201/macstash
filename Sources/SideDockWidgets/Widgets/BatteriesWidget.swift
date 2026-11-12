import SwiftUI
import AppKit
import IOKit.ps
import os.log
import SideDockCore

public struct BatteriesConfig: Codable, Equatable, Sendable {
    public var showPeripherals: Bool
    public var showPercentageLabel: Bool

    public init(showPeripherals: Bool = true, showPercentageLabel: Bool = true) {
        self.showPeripherals = showPeripherals
        self.showPercentageLabel = showPercentageLabel
    }
}

public struct BatteryDeviceReading: Identifiable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let percentage: Int
    public let isCharging: Bool
    public let symbolName: String

    public init(id: String, name: String, percentage: Int, isCharging: Bool = false, symbolName: String) {
        self.id = id
        self.name = name
        self.percentage = max(0, min(100, percentage))
        self.isCharging = isCharging
        self.symbolName = symbolName
    }
}

public enum BatteriesReader {
    private static let logger = Logger(subsystem: "com.macstash.app", category: "batteries")

    public static func readAllDevices(includePeripherals: Bool) async -> [BatteryDeviceReading] {
        await Task.detached(priority: .utility) {
            var readings: [BatteryDeviceReading] = []
            readings.append(contentsOf: readPowerSources())
            if includePeripherals {
                readings.append(contentsOf: readBluetoothHIDBatteries())
            }
            return readings
        }.value
    }

    private static func readPowerSources() -> [BatteryDeviceReading] {
        var result: [BatteryDeviceReading] = []
        guard let blob = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(blob)?.takeRetainedValue() as? [CFTypeRef] else {
            return result
        }

        for ps in sources {
            guard let desc = IOPSGetPowerSourceDescription(blob, ps)?.takeUnretainedValue() as? [String: Any] else {
                continue
            }
            let name = (desc[kIOPSNameKey] as? String) ?? "Mac"
            let current = desc[kIOPSCurrentCapacityKey] as? Int ?? 0
            let maxCap = max(1, desc[kIOPSMaxCapacityKey] as? Int ?? 100)
            let pct = Int(round((Double(current) / Double(maxCap)) * 100.0))
            let charging = (desc[kIOPSIsChargingKey] as? Bool) ?? false
            let type = (desc[kIOPSTypeKey] as? String) ?? ""
            let symbol = type.contains("InternalBattery") ? "laptopcomputer" : "battery.100"
            result.append(BatteryDeviceReading(
                id: "ps_\(name)",
                name: name == "InternalBattery-0" ? "Mac" : name,
                percentage: pct,
                isCharging: charging,
                symbolName: symbol
            ))
        }
        return result
    }

    private static func readBluetoothHIDBatteries() -> [BatteryDeviceReading] {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/sbin/ioreg")
        proc.arguments = ["-r", "-c", "AppleDeviceManagementHIDEventService", "-k", "BatteryPercent"]

        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.standardError = FileHandle.nullDevice

        do {
            try proc.run()
        } catch {
            logger.debug("ioreg battery scan failed: \(error.localizedDescription, privacy: .public)")
            return []
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        proc.waitUntilExit()
        guard let output = String(data: data, encoding: .utf8), !output.isEmpty else {
            return []
        }

        return parseIORegBatteryOutput(output)
    }

    public static func parseIORegBatteryOutput(_ output: String) -> [BatteryDeviceReading] {
        var devices: [BatteryDeviceReading] = []
        var currentProduct: String?
        var currentPercent: Int?

        for rawLine in output.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.hasPrefix("+-o ") {
                if let product = currentProduct, let pct = currentPercent {
                    devices.append(makeHIDReading(name: product, percentage: pct))
                }
                currentProduct = nil
                currentPercent = nil
            } else if line.contains("\"Product\" = ") {
                if let range = line.range(of: "\"Product\" = \"") {
                    let rest = line[range.upperBound...]
                    if let end = rest.firstIndex(of: "\"") {
                        currentProduct = String(rest[..<end])
                    }
                }
            } else if line.contains("\"BatteryPercent\" = ") {
                if let eqIdx = line.lastIndex(of: "=") {
                    let numStr = line[line.index(after: eqIdx)...].trimmingCharacters(in: .whitespaces)
                    currentPercent = Int(numStr)
                }
            }
        }

        if let product = currentProduct, let pct = currentPercent {
            devices.append(makeHIDReading(name: product, percentage: pct))
        }
        return devices
    }

    private static func makeHIDReading(name: String, percentage: Int) -> BatteryDeviceReading {
        let lower = name.lowercased()
        let symbol: String
        if lower.contains("mouse") {
            symbol = "magicmouse.fill"
        } else if lower.contains("trackpad") {
            symbol = "rectangle.and.hand.point.up.left.filled"
        } else if lower.contains("keyboard") {
            symbol = "keyboard.fill"
        } else if lower.contains("airpod") || lower.contains("head") {
            symbol = "airpodspro"
        } else {
            symbol = "wave.3.right"
        }
        return BatteryDeviceReading(
            id: "hid_\(name)",
            name: name,
            percentage: percentage,
            isCharging: false,
            symbolName: symbol
        )
    }
}

public struct BatteriesWidgetView: View {
    public let config: BatteriesConfig
    public let size: WidgetSize

    @State private var devices: [BatteryDeviceReading] = []
    @State private var refreshTimer: Timer?

    public init(config: BatteriesConfig = BatteriesConfig(), size: WidgetSize = .medium) {
        self.config = config
        self.size = size
    }

    public var body: some View {
        Group {
            if devices.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "battery.100")
                        .foregroundColor(.green)
                    if size != .small {
                        Text("100%")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .monospacedDigit()
                    }
                }
            } else if size == .small, let first = devices.first {
                VStack(spacing: 2) {
                    batteryRing(first, diameter: 24)
                    if config.showPercentageLabel {
                        Text("\(first.percentage)%")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .monospacedDigit()
                    }
                }
            } else {
                HStack(spacing: 8) {
                    ForEach(devices.prefix(size == .large ? 4 : 2)) { dev in
                        VStack(spacing: 2) {
                            batteryRing(dev, diameter: 22)
                            Text("\(dev.percentage)%")
                                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                                .monospacedDigit()
                                .lineLimit(1)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .onAppear {
            startPolling()
        }
        .onDisappear {
            refreshTimer?.invalidate()
            refreshTimer = nil
        }
    }

    private func batteryRing(_ dev: BatteryDeviceReading, diameter: CGFloat) -> some View {
        let color: Color = dev.isCharging ? .green : (dev.percentage <= 20 ? .red : .green)
        return ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.14), lineWidth: 2.5)
            Circle()
                .trim(from: 0, to: CGFloat(dev.percentage) / 100.0)
                .stroke(color, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Image(systemName: dev.isCharging ? "bolt.fill" : dev.symbolName)
                .font(.system(size: diameter * 0.4, weight: .semibold))
                .foregroundColor(dev.isCharging ? .green : .primary)
        }
        .frame(width: diameter, height: diameter)
    }

    private func startPolling() {
        refreshTimer?.invalidate()
        Task { await refresh() }
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 45.0, repeats: true) { _ in
            Task { @MainActor in
                await refresh()
            }
        }
    }

    @MainActor
    private func refresh() async {
        devices = await BatteriesReader.readAllDevices(includePeripherals: config.showPeripherals)
    }
}

public struct BatteriesExpandedView: View {
    public let config: BatteriesConfig
    @State private var devices: [BatteryDeviceReading] = []

    public init(config: BatteriesConfig) {
        self.config = config
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Batteries", systemImage: "battery.100.bolt")
                    .font(.system(size: 13, weight: .bold))
                Spacer()
                Button {
                    Task {
                        devices = await BatteriesReader.readAllDevices(includePeripherals: config.showPeripherals)
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
            }

            if devices.isEmpty {
                Text("Scanning power sources...")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            } else {
                ForEach(devices) { dev in
                    HStack(spacing: 10) {
                        Image(systemName: dev.symbolName)
                            .font(.system(size: 14))
                            .frame(width: 20)
                            .foregroundColor(.accentColor)

                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                Text(dev.name)
                                    .font(.system(size: 11.5, weight: .medium))
                                    .lineLimit(1)
                                Spacer()
                                Text("\(dev.percentage)%")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .monospacedDigit()
                            }
                            ProgressView(value: Double(dev.percentage), total: 100.0)
                                .tint(dev.percentage <= 20 ? .red : .green)
                        }
                    }
                }
            }
        }
        .padding(14)
        .frame(width: 260)
        .task {
            devices = await BatteriesReader.readAllDevices(includePeripherals: config.showPeripherals)
        }
    }
}
