import SwiftUI
import IOKit.ps
import Darwin
import SideDockCore

public struct SystemStatsConfig: Codable, Equatable, Sendable {
    public var showCPU: Bool
    public var showRAM: Bool
    public var showBattery: Bool
    public var showDisk: Bool

    public init(showCPU: Bool = true, showRAM: Bool = true, showBattery: Bool = true, showDisk: Bool = false) {
        self.showCPU = showCPU
        self.showRAM = showRAM
        self.showBattery = showBattery
        self.showDisk = showDisk
    }
}

public struct CPUTickSample: Equatable, Sendable {
    public let activeTicks: UInt64
    public let totalTicks: UInt64

    public init(activeTicks: UInt64, totalTicks: UInt64) {
        self.activeTicks = activeTicks
        self.totalTicks = totalTicks
    }

    public static func deltaPercent(from previous: CPUTickSample?, to current: CPUTickSample) -> Double {
        guard let prev = previous,
              current.totalTicks > prev.totalTicks,
              current.activeTicks >= prev.activeTicks else {
            guard current.totalTicks > 0 else { return 0.0 }
            return min(100.0, max(0.0, (Double(current.activeTicks) / Double(current.totalTicks)) * 100.0))
        }
        let deltaActive = Double(current.activeTicks - prev.activeTicks)
        let deltaTotal = Double(current.totalTicks - prev.totalTicks)
        return min(100.0, max(0.0, (deltaActive / deltaTotal) * 100.0))
    }
}

public struct SystemMetrics: Equatable, Sendable {
    public let cpuPercent: Double
    public let ramPercent: Double
    public let batteryPercent: Int
    public let isCharging: Bool
    public let freeDiskGB: Double

    public init(
        cpuPercent: Double = 0.0,
        ramPercent: Double = 0.0,
        batteryPercent: Int = 100,
        isCharging: Bool = false,
        freeDiskGB: Double = 0.0
    ) {
        self.cpuPercent = cpuPercent
        self.ramPercent = ramPercent
        self.batteryPercent = batteryPercent
        self.isCharging = isCharging
        self.freeDiskGB = freeDiskGB
    }
}

public struct SystemStatsWidgetView: View {
    public let config: SystemStatsConfig
    public let size: WidgetSize
    @State private var metrics: SystemMetrics = SystemMetrics()
    @State private var previousSample: CPUTickSample? = nil
    @State private var timer: Timer?

    public init(config: SystemStatsConfig = SystemStatsConfig(), size: WidgetSize = .medium) {
        self.config = config
        self.size = size
    }

    public var body: some View {
        HStack(spacing: 8) {
            if config.showCPU {
                metricBadge(icon: "cpu", color: .blue, text: "\(Int(round(metrics.cpuPercent)))%")
            }

            if config.showRAM {
                metricBadge(icon: "memorychip", color: .purple, text: "\(Int(round(metrics.ramPercent)))%")
            }

            if config.showBattery && size != .small {
                metricBadge(
                    icon: metrics.isCharging ? "battery.100.bolt" : "battery.75",
                    color: metrics.batteryPercent <= 20 ? .red : .green,
                    text: "\(metrics.batteryPercent)%"
                )
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .onAppear {
            readMetrics()
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
                Task { @MainActor in
                    self.readMetrics()
                }
            }
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }

    private func metricBadge(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(color)
            Text(text)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .monospacedDigit()
        }
    }

    private func readMetrics() {
        let cpuSample = sampleCPUTicks()
        let cpu = CPUTickSample.deltaPercent(from: previousSample, to: cpuSample)
        self.previousSample = cpuSample
        let ram = readRAMUsage()
        let (bat, charging) = readBattery()
        self.metrics = SystemMetrics(
            cpuPercent: cpu,
            ramPercent: ram,
            batteryPercent: bat,
            isCharging: charging
        )
    }

    private func sampleCPUTicks() -> CPUTickSample {
        var cpuInfo = host_cpu_load_info()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info_data_t>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &cpuInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return CPUTickSample(activeTicks: 0, totalTicks: 0) }
        let user = UInt64(cpuInfo.cpu_ticks.0)
        let system = UInt64(cpuInfo.cpu_ticks.1)
        let idle = UInt64(cpuInfo.cpu_ticks.2)
        let nice = UInt64(cpuInfo.cpu_ticks.3)
        let active = user + system + nice
        let total = active + idle
        return CPUTickSample(activeTicks: active, totalTicks: total)
    }

    private func readRAMUsage() -> Double {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return 40.0 }
        let pageSize = UInt64(getpagesize())
        let active = UInt64(stats.active_count) * pageSize
        let wired = UInt64(stats.wire_count) * pageSize
        let compressed = UInt64(stats.compressor_page_count) * pageSize
        let used = Double(active + wired + compressed)
        let total = Double(ProcessInfo.processInfo.physicalMemory)
        guard total > 0 else { return 40.0 }
        return min(100.0, max(0.0, (used / total) * 100.0))
    }

    private func readBattery() -> (Int, Bool) {
        let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue()
        guard let list = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef],
              let first = list.first,
              let desc = IOPSGetPowerSourceDescription(snapshot, first)?.takeUnretainedValue() as? [String: Any] else {
            return (100, true)
        }
        let current = desc[kIOPSCurrentCapacityKey as String] as? Int ?? 100
        let max = desc[kIOPSMaxCapacityKey as String] as? Int ?? 100
        let isCharging = desc[kIOPSIsChargingKey as String] as? Bool ?? false
        let percent = max > 0 ? Int((Double(current) / Double(max)) * 100) : 100
        return (percent, isCharging)
    }
}
