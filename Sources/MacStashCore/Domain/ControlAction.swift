import Foundation

public enum ControlAction: String, CaseIterable, Identifiable, Codable, Sendable {
    case volume
    case brightness
    case keyboardBrightness
    case timer
    case none

    public var id: String { rawValue }

    public var displayName: String {
        localizedDisplayName()
    }

    public func localizedDisplayName(using language: String? = nil) -> String {
        let lang = language ?? LocalizationService.shared.effectiveLanguage
        let isVi = lang == "vi"
        switch self {
        case .volume: return isVi ? "Âm lượng & Thiết bị âm thanh" : "Volume & Audio Output"
        case .brightness: return isVi ? "Độ sáng màn hình" : "Display Brightness"
        case .keyboardBrightness: return isVi ? "Đèn nền bàn phím" : "Keyboard Backlight"
        case .timer: return isVi ? "Đồng hồ tập trung Pomodoro" : "Focus / Quick Timer (0-60m)"
        case .none: return isVi ? "Không gán (Tắt)" : "Disabled"
        }
    }

    public var shortTitle: String {
        switch self {
        case .volume: return "VOLUME"
        case .brightness: return "BRIGHTNESS"
        case .keyboardBrightness: return "KEYBOARD"
        case .timer: return "TIMER"
        case .none: return "OFF"
        }
    }

    public var systemImageName: String {
        switch self {
        case .volume: return "speaker.wave.3.fill"
        case .brightness: return "sun.max.fill"
        case .keyboardBrightness: return "keyboard.fill"
        case .timer: return "timer"
        case .none: return "slash.circle"
        }
    }
}
