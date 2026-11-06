import Foundation
import CoreGraphics
import Combine

private typealias DisplayServicesGetBrightnessType = @convention(c) (CGDirectDisplayID, UnsafeMutablePointer<Float>) -> Int32
private typealias DisplayServicesSetBrightnessType = @convention(c) (CGDirectDisplayID, Float) -> Int32

/// Controls macOS display brightness using DisplayServices framework
public final class BrightnessManager: ObservableObject {
    public static let shared = BrightnessManager()

    @Published public private(set) var brightness: Float = 0.8

    private var getBrightnessFunc: DisplayServicesGetBrightnessType?
    private var setBrightnessFunc: DisplayServicesSetBrightnessType?

    private init() {
        loadDisplayServices()
        updateBrightnessFromHardware()
    }

    private func loadDisplayServices() {
        let path = "/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices"
        guard let handle = dlopen(path, RTLD_LAZY) else {
            return
        }

        if let getSym = dlsym(handle, "DisplayServicesGetBrightness") {
            getBrightnessFunc = unsafeBitCast(getSym, to: DisplayServicesGetBrightnessType.self)
        }

        if let setSym = dlsym(handle, "DisplayServicesSetBrightness") {
            setBrightnessFunc = unsafeBitCast(setSym, to: DisplayServicesSetBrightnessType.self)
        }
    }

    public func updateBrightnessFromHardware() {
        guard let getBrightness = getBrightnessFunc else { return }
        var current: Float = 0.5
        let mainDisplay = CGMainDisplayID()
        let result = getBrightness(mainDisplay, &current)
        if result == 0 {
            DispatchQueue.main.async {
                self.brightness = max(0.0, min(1.0, current))
            }
        }
    }

    public func setBrightness(_ newBrightness: Float) {
        let clamped = max(0.0, min(1.0, newBrightness))
        guard let setBrightness = setBrightnessFunc else {
            DispatchQueue.main.async { self.brightness = clamped }
            return
        }

        let mainDisplay = CGMainDisplayID()
        let result = setBrightness(mainDisplay, clamped)
        if result == 0 {
            DispatchQueue.main.async {
                self.brightness = clamped
            }
        }
    }
}
