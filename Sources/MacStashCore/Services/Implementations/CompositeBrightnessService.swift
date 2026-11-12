import Foundation
import CoreGraphics
import Combine

public final class CompositeBrightnessService: ObservableObject, @unchecked Sendable {
    public let builtInService: BuiltInBrightnessService
    public let ddcService: DDCBrightnessService
    public let softwareService: SoftwareDimmingService
    public let displayService: DisplayServiceProtocol

    @Published public private(set) var profiles: [String: DisplayBrightnessProfile] = [:]

    public init(
        builtInService: BuiltInBrightnessService = BuiltInBrightnessService(),
        ddcService: DDCBrightnessService = DDCBrightnessService(),
        softwareService: SoftwareDimmingService = SoftwareDimmingService(),
        displayService: DisplayServiceProtocol = SystemDisplayService()
    ) {
        self.builtInService = builtInService
        self.ddcService = ddcService
        self.softwareService = softwareService
        self.displayService = displayService
    }

    public func brightness(for display: DisplayInfo) async -> Float {
        if display.isBuiltIn {
            return await builtInService.getBrightness(for: display)
        }
        if let profile = profiles[display.uuid] {
            return profile.brightnessLevel
        }
        return Defaults.Brightness.defaultLevel
    }

    /// Synchronously checks the live physical brightness from hardware (for built-in Apple displays).
    public func currentHardwareBrightness(for display: DisplayInfo) -> Float? {
        if display.isBuiltIn {
            return builtInService.currentBrightness(for: display.id)
        }
        return nil
    }

    /// Purely reads the brightness level for a display without mutating `@Published` state.
    /// Safe to invoke inside `SwiftUI.View.body`.
    public func readBrightnessLevel(for display: DisplayInfo) -> Float {
        if let live = currentHardwareBrightness(for: display) {
            return live
        }
        return profiles[display.uuid]?.brightnessLevel ?? Defaults.Brightness.defaultLevel
    }

    /// Synchronously synchronizes internal profile state with the live hardware brightness.
    /// Returns the live clamped brightness value without emitting redundant `@Published` updates when unchanged.
    @discardableResult
    public func syncHardwareBrightness(for display: DisplayInfo) -> Float {
        let existing = profiles[display.uuid]
        var profile = existing ?? DisplayBrightnessProfile(
            displayUUID: display.uuid,
            displayName: display.name,
            isBuiltIn: display.isBuiltIn
        )
        let result: Float
        if let live = currentHardwareBrightness(for: display) {
            profile.brightnessLevel = live
            profile.actualMethod = .builtIn
            result = live
        } else {
            result = profile.brightnessLevel
        }

        let didChange = existing == nil
            || abs((existing?.brightnessLevel ?? -1) - profile.brightnessLevel) > 0.002
            || existing?.actualMethod != profile.actualMethod
        if didChange {
            profiles[display.uuid] = profile
        }
        return result
    }

    /// Synchronizes all connected displays with physical hardware values.
    public func syncAllDisplays(_ displays: [DisplayInfo]) {
        for display in displays {
            syncHardwareBrightness(for: display)
        }
    }

    public func setBrightness(_ level: Float, for display: DisplayInfo) async -> Bool {
        let clamped = BrightnessPolicy.clamp(level)
        var profile = profiles[display.uuid] ?? DisplayBrightnessProfile(
            displayUUID: display.uuid,
            displayName: display.name,
            isBuiltIn: display.isBuiltIn
        )

        profile.brightnessLevel = clamped

        let success: Bool
        if display.isBuiltIn {
            success = await builtInService.setBrightness(clamped, for: display)
            profile.actualMethod = .builtIn
        } else {
            let isDDC = await ddcService.isDDCSupported(for: display)
            let resolution = BrightnessPolicy.resolveActualMethod(
                preferred: profile.preferredMethod,
                isBuiltIn: display.isBuiltIn,
                isDDCSupported: isDDC
            )
            profile.actualMethod = resolution.method

            switch resolution.method {
            case .ddc:
                let ddcSuccess = await ddcService.setBrightness(clamped, for: display)
                if ddcSuccess {
                    success = true
                } else {
                    profile.actualMethod = .software
                    success = await softwareService.setBrightness(clamped, for: display)
                }
            case .software, .auto, .builtIn:
                success = await softwareService.setBrightness(clamped, for: display)
            }
        }

        let updatedProfile = profile
        DispatchQueue.main.async {
            self.profiles[display.uuid] = updatedProfile
        }

        return success
    }

    public func restoreAllSoftwareDimming() {
        softwareService.restoreAllDisplays()
    }

    public func queryConnectedDisplays() -> [DisplayInfo] {
        displayService.activeDisplays()
    }

    public func profile(for uuid: String) -> DisplayBrightnessProfile? {
        profiles[uuid]
    }

    public func setProfile(_ profile: DisplayBrightnessProfile) {
        profiles[profile.displayUUID] = profile
    }
}
