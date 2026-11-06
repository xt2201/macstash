import Foundation

public enum ControlAction: String, CaseIterable, Identifiable, Codable, Sendable {
    case volume
    case brightness
    case keyboardBrightness
    case timer
    case none

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .volume: return "Volume & Audio Output"
        case .brightness: return "Display Brightness"
        case .keyboardBrightness: return "Keyboard Backlight"
        case .timer: return "Focus / Quick Timer (0-60m)"
        case .none: return "Disabled"
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
