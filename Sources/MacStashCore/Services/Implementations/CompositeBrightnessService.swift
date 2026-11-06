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
