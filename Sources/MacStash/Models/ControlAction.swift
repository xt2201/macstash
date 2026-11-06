import SwiftUI
import MacStashCore

extension ControlAction {
    public var systemImage: String { systemImageName }

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
