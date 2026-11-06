import SwiftUI

/// Actions aligned with stashformac.com core controls
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

    public var systemImage: String {
        switch self {
        case .volume: return "speaker.wave.3.fill"
        case .brightness: return "sun.max.fill"
        case .keyboardBrightness: return "keyboard.fill"
        case .timer: return "timer"
        case .none: return "slash.circle"
        }
    }

    public var accentColors: [Color] {
        switch self {
        case .volume:
            return [Color(red: 0.18, green: 0.62, blue: 1.0), Color(red: 0.05, green: 0.38, blue: 0.95)]
        case .brightness:
            return [Color(red: 1.0, green: 0.76, blue: 0.18), Color(red: 1.0, green: 0.48, blue: 0.0)]
        case .keyboardBrightness:
            return [Color(red: 0.22, green: 0.85, blue: 0.78), Color(red: 0.1, green: 0.6, blue: 0.75)]
        case .timer:
            return [Color(red: 0.78, green: 0.42, blue: 1.0), Color(red: 0.48, green: 0.22, blue: 0.95)]
        case .none:
            return [Color.gray, Color.secondary]
        }
    }
}
