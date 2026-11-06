import Foundation

public enum BrightnessMethod: String, Codable, CaseIterable, Sendable {
    case auto
    case builtIn
    case ddc
    case software

    public var displayName: String {
        switch self {
        case .auto: return "Automatic (Recommended)"
        case .builtIn: return "Native Display Services"
        case .ddc: return "DDC/CI Hardware"
        case .software: return "Software Dimming"
        }
    }
}

public struct DisplayBrightnessProfile: Codable, Equatable, Sendable {
    public var displayUUID: String
    public var displayName: String
    public var preferredMethod: BrightnessMethod
    public var actualMethod: BrightnessMethod
    public var brightnessLevel: Float
    public var isBuiltIn: Bool
    public var isEnabled: Bool

    public init(
        displayUUID: String,
        displayName: String,
        preferredMethod: BrightnessMethod = .auto,
        actualMethod: BrightnessMethod = .auto,
        brightnessLevel: Float = Defaults.Brightness.defaultLevel,
        isBuiltIn: Bool = false,
        isEnabled: Bool = true
    ) {
        self.displayUUID = displayUUID
        self.displayName = displayName
        self.preferredMethod = preferredMethod
        self.actualMethod = actualMethod
        self.brightnessLevel = max(Defaults.Brightness.minLevel, min(Defaults.Brightness.maxLevel, brightnessLevel))
        self.isBuiltIn = isBuiltIn
        self.isEnabled = isEnabled
    }
}

public enum BrightnessPolicy {
    public static func clamp(_ level: Float) -> Float {
        max(Defaults.Brightness.minLevel, min(Defaults.Brightness.maxLevel, level))
    }

    public static func resolveActualMethod(
        preferred: BrightnessMethod,
        isBuiltIn: Bool,
        isDDCSupported: Bool
    ) -> (method: BrightnessMethod, reason: String) {
        if isBuiltIn {
            return (.builtIn, "Built-in display uses native macOS display services.")
        }

        switch preferred {
        case .auto:
            if isDDCSupported {
                return (.ddc, "DDC/CI hardware control active.")
            } else {
                return (.software, "Hardware DDC not responding; fell back to software dimming.")
            }
        case .ddc:
            if isDDCSupported {
                return (.ddc, "DDC/CI hardware control active.")
            } else {
                return (.software, "Hardware DDC forced but not responding; fell back to software dimming.")
            }
        case .software:
            return (.software, "Software dimming selected by user.")
        case .builtIn:
            return (.software, "Display is external; fell back to software dimming.")
        }
    }
}

public enum KeyboardBrightnessPolicy {
    public static func clamp(_ level: Float) -> Float {
        max(0.0, min(1.0, level))
    }

    public static func toggle(current: Float) -> Float {
        current > 0.05 ? 0.0 : 0.6
    }

    public static func isSignificantChange(from current: Float, to newLevel: Float, threshold: Float = 0.0001) -> Bool {
        abs(current - newLevel) > threshold
    }
}
