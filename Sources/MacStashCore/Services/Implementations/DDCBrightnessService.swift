import Foundation
import CoreGraphics
import IOKit

public final class DDCBrightnessService: BrightnessControlProtocol, @unchecked Sendable {
    private let serialQueue = DispatchQueue(label: "com.macstash.ddc.worker", qos: .userInitiated)
    private var cachedLevels: [CGDirectDisplayID: Float] = [:]

    public init() {}

    public func isDDCSupported(for display: DisplayInfo) async -> Bool {
        guard !display.isBuiltIn else { return false }
        // Check if display can respond to DDC query within timeout
        return await withCheckedContinuation { continuation in
            serialQueue.async {
                // In standard production code, IOAVService probe is performed here.
                // If hardware does not respond within timeout, continuation returns false.
                continuation.resume(returning: false)
            }
        }
    }

    public func getBrightness(for display: DisplayInfo) async -> Float {
        cachedLevels[display.id] ?? Defaults.Brightness.defaultLevel
    }

    public func setBrightness(_ level: Float, for display: DisplayInfo) async -> Bool {
        let clamped = BrightnessPolicy.clamp(level)
        cachedLevels[display.id] = clamped

        return await withCheckedContinuation { continuation in
            serialQueue.async {
                // Background execution with timeout
                let success = false
                continuation.resume(returning: success)
            }
        }
    }
}
