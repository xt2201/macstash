import Foundation
import CoreGraphics

public final class SoftwareDimmingService: BrightnessControlProtocol, @unchecked Sendable {
    private var dimmedDisplays = Set<CGDirectDisplayID>()
    private var levels: [CGDirectDisplayID: Float] = [:]

    public init() {}

    deinit {
        restoreAllDisplays()
    }

    public func getBrightness(for display: DisplayInfo) async -> Float {
        levels[display.id] ?? Defaults.Brightness.defaultLevel
    }

    public func setBrightness(_ level: Float, for display: DisplayInfo) async -> Bool {
        let clamped = BrightnessPolicy.clamp(level)
        levels[display.id] = clamped

        let tableSize: UInt32 = 256
        var redTable = [CGGammaValue](repeating: 0, count: Int(tableSize))
        var greenTable = [CGGammaValue](repeating: 0, count: Int(tableSize))
        var blueTable = [CGGammaValue](repeating: 0, count: Int(tableSize))

        // Minimum software brightness floor (0.05) to prevent pure black screen lockouts
        let effectiveLevel = max(0.05, clamped)

        for i in 0..<Int(tableSize) {
            let val = (CGGammaValue(i) / CGGammaValue(tableSize - 1)) * CGGammaValue(effectiveLevel)
            redTable[i] = val
            greenTable[i] = val
            blueTable[i] = val
        }

        let result = CGSetDisplayTransferByTable(
            display.id,
            tableSize,
            &redTable,
            &greenTable,
            &blueTable
        )

        if result == .success {
            dimmedDisplays.insert(display.id)
            return true
        }

        AppLogger.brightness.warning("Failed to set gamma table for display \(display.id)")
        return false
    }

    public func restore(display: DisplayInfo) {
        CGDisplayRestoreColorSyncSettings()
        dimmedDisplays.remove(display.id)
    }

    public func restoreAllDisplays() {
        guard !dimmedDisplays.isEmpty else { return }
        CGDisplayRestoreColorSyncSettings()
        dimmedDisplays.removeAll()
        AppLogger.brightness.info("Restored all displays color sync and gamma settings")
    }
}
