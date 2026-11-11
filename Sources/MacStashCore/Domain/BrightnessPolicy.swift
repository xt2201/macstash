import Foundation

public enum BrightnessMethod: String, Codable, CaseIterable, Sendable {
    case auto
    case builtIn
    case ddc
    case software

    public var displayName: String {
        localizedDisplayName()
    }

    public func localizedDisplayName(using language: String? = nil) -> String {
        let isVi = (language ?? LocalizationService.shared.effectiveLanguage) == "vi"
        switch self {
        case .auto: return isVi ? "Tự động (Khuyên dùng)" : "Automatic (Recommended)"
        case .builtIn: return isVi ? "Dịch vụ hiển thị mặc định" : "Native Display Services"
        case .ddc: return isVi ? "Phần cứng DDC/CI" : "DDC/CI Hardware"
        case .software: return isVi ? "Giảm sáng phần mềm" : "Software Dimming"
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

    public static func clamp(_ level: Float, min minClamp: Float, max maxClamp: Float) -> Float {
        let low = max(Defaults.Brightness.minLevel, min(0.95, minClamp))
        let high = max(low, min(Defaults.Brightness.maxLevel, maxClamp))
        return max(low, min(high, level))
    }

    public static func resolveActualMethod(
        preferred: BrightnessMethod,
        isBuiltIn: Bool,
        isDDCSupported: Bool,
        language: String? = nil
    ) -> (method: BrightnessMethod, reason: String) {
        let isVi = (language ?? LocalizationService.shared.effectiveLanguage) == "vi"
        if isBuiltIn {
            return (.builtIn, isVi
                ? "Màn hình tích hợp sử dụng dịch vụ hiển thị gốc của macOS."
                : "Built-in display uses native macOS display services.")
        }

        switch preferred {
        case .auto:
            if isDDCSupported {
                return (.ddc, isVi ? "Đang điều khiển phần cứng DDC/CI." : "DDC/CI hardware control active.")
            } else {
                return (.software, isVi
                    ? "DDC phần cứng không phản hồi; tự chuyển sang giảm sáng phần mềm."
                    : "Hardware DDC not responding; fell back to software dimming.")
            }
        case .ddc:
            if isDDCSupported {
                return (.ddc, isVi ? "Đang điều khiển phần cứng DDC/CI." : "DDC/CI hardware control active.")
            } else {
                return (.software, isVi
                    ? "Đã chọn DDC phần cứng nhưng màn hình không phản hồi; chuyển sang giảm sáng phần mềm."
                    : "Hardware DDC forced but not responding; fell back to software dimming.")
            }
        case .software:
            return (.software, isVi ? "Người dùng chọn giảm sáng phần mềm." : "Software dimming selected by user.")
        case .builtIn:
            return (.software, isVi
                ? "Là màn hình ngoài; tự chuyển sang giảm sáng phần mềm."
                : "Display is external; fell back to software dimming.")
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
