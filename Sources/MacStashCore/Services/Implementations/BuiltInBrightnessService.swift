import Foundation
import CoreGraphics

private typealias DisplayServicesGetBrightnessType = @convention(c) (CGDirectDisplayID, UnsafeMutablePointer<Float>) -> Int32
private typealias DisplayServicesSetBrightnessType = @convention(c) (CGDirectDisplayID, Float) -> Int32

public final class BuiltInBrightnessService: BrightnessControlProtocol, @unchecked Sendable {
    private var getBrightnessFunc: DisplayServicesGetBrightnessType?
    private var setBrightnessFunc: DisplayServicesSetBrightnessType?

    public init() {
        loadDisplayServices()
    }

    private func loadDisplayServices() {
        let path = "/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices"
        guard let handle = dlopen(path, RTLD_LAZY) else {
            AppLogger.brightness.warning("DisplayServices.framework dlopen failed")
            return
        }

        if let getSym = dlsym(handle, "DisplayServicesGetBrightness") {
            getBrightnessFunc = unsafeBitCast(getSym, to: DisplayServicesGetBrightnessType.self)
        }

        if let setSym = dlsym(handle, "DisplayServicesSetBrightness") {
            setBrightnessFunc = unsafeBitCast(setSym, to: DisplayServicesSetBrightnessType.self)
        }
    }

    public func getBrightness(for display: DisplayInfo) async -> Float {
        guard let getBrightness = getBrightnessFunc else {
            return Defaults.Brightness.defaultLevel
        }

        var current: Float = Defaults.Brightness.defaultLevel
        let result = getBrightness(display.id, &current)
        if result == 0 {
            return BrightnessPolicy.clamp(current)
        }

        AppLogger.brightness.debug("DisplayServicesGetBrightness returned status \(result) for display \(display.id)")
        return Defaults.Brightness.defaultLevel
    }

    public func setBrightness(_ level: Float, for display: DisplayInfo) async -> Bool {
        let clamped = BrightnessPolicy.clamp(level)
        guard let setBrightness = setBrightnessFunc else {
            return false
        }

        let result = setBrightness(display.id, clamped)
        if result == 0 {
            return true
        }

        AppLogger.brightness.debug("DisplayServicesSetBrightness returned status \(result) for display \(display.id)")
        return false
    }
}
