import Foundation
import Combine

/// Manages MacBook backlit keyboard brightness via Apple private CoreBrightness framework
@MainActor
public final class KeyboardBrightnessManager: ObservableObject {
    public static let shared = KeyboardBrightnessManager()

    @Published public private(set) var brightness: Float = 0.5
    @Published public private(set) var isSupported: Bool = false

    private var clientInstance: AnyObject?
    private var keyboardID: UInt64 = 0

    private init() {
        loadClient()
        updateBrightnessFromHardware()
    }

    private func loadClient() {
        guard dlopen("/System/Library/PrivateFrameworks/CoreBrightness.framework/CoreBrightness", RTLD_LAZY) != nil else {
            return
        }

        guard let clientClass = NSClassFromString("KeyboardBrightnessClient") as? NSObject.Type else {
            return
        }

        let client = clientClass.init()
        self.clientInstance = client

        // Query keyboard IDs
        let sel = NSSelectorFromString("copyKeyboardBacklightIDs")
        if client.responds(to: sel),
           let result = client.perform(sel)?.takeRetainedValue() as? [Any],
           let firstID = result.first as? UInt64 {
            self.keyboardID = firstID
            self.isSupported = true
        } else {
            self.isSupported = false
        }
    }

    public func updateBrightnessFromHardware() {
        guard isSupported, let client = clientInstance else { return }

        // Method signature: - (float)brightnessForKeyboard:(unsigned long long)arg1;
        // Or backlightLevelForKeyboard:
        typealias GetBrightnessFunc = @convention(c) (AnyObject, Selector, UInt64) -> Float
        let sel = NSSelectorFromString("brightnessForKeyboard:")
        guard client.responds(to: sel),
              let methodIMP = client.method(for: sel) else { return }

        let fn = unsafeBitCast(methodIMP, to: GetBrightnessFunc.self)
        let current = fn(client, sel, keyboardID)

        DispatchQueue.main.async {
            self.brightness = max(0.0, min(1.0, current))
        }
    }

    public func setBrightness(_ newBrightness: Float) {
        let clamped = max(0.0, min(1.0, newBrightness))
        DispatchQueue.main.async { self.brightness = clamped }

        guard isSupported, let client = clientInstance else { return }

        // Method signature: - (BOOL)setBrightness:(float)arg1 forKeyboard:(unsigned long long)arg2;
        typealias SetBrightnessFunc = @convention(c) (AnyObject, Selector, Float, UInt64) -> Bool
        let sel = NSSelectorFromString("setBrightness:forKeyboard:")
        guard client.responds(to: sel),
              let methodIMP = client.method(for: sel) else { return }

        let fn = unsafeBitCast(methodIMP, to: SetBrightnessFunc.self)
        _ = fn(client, sel, clamped, keyboardID)
    }
}
