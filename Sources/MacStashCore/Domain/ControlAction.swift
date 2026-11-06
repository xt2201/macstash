import Foundation

public enum ControlAction: String, CaseIterable, Identifiable, Codable, Sendable {
    case volume
    case brightness
    case keyboardBrightness
    case timer
    case keepAwake
    case stashShelf
    case scratchpad
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
        case .keepAwake: return isVi ? "Giữ máy luôn thức (Caffeine)" : "Keep Awake (Caffeine)"
        case .stashShelf: return isVi ? "Kệ thả tệp Stash Shelf" : "Stash Drop Shelf"
        case .scratchpad: return isVi ? "Ghi chú nhanh Scratchpad" : "Quick Scratchpad"
        case .none: return isVi ? "Không gán (Tắt)" : "Disabled"
        }
    }

    public var shortTitle: String {
        switch self {
        case .volume: return "VOLUME"
        case .brightness: return "BRIGHTNESS"
        case .keyboardBrightness: return "KEYBOARD"
        case .timer: return "TIMER"
        case .keepAwake: return "AWAKE"
        case .stashShelf: return "STASH"
        case .scratchpad: return "NOTES"
        case .none: return "OFF"
        }
    }

    public var systemImageName: String {
        switch self {
        case .volume: return "speaker.wave.3.fill"
        case .brightness: return "sun.max.fill"
        case .keyboardBrightness: return "keyboard.fill"
        case .timer: return "timer"
        case .keepAwake: return "cup.and.saucer.fill"
        case .stashShelf: return "tray.2.fill"
        case .scratchpad: return "note.text"
        case .none: return "slash.circle"
        }
    }
}
