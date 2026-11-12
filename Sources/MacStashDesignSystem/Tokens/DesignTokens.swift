import SwiftUI
import AppKit
import MacStashCore

/// Single Source of Truth for visual design tokens across MacStash and SideDock.
public enum DSSpacing {
    public static let xxs: CGFloat = 2.0
    public static let xs: CGFloat = 4.0
    public static let sm: CGFloat = 8.0
    public static let md: CGFloat = 12.0
    public static let lg: CGFloat = 16.0
    public static let xl: CGFloat = 24.0
    public static let xxl: CGFloat = 32.0
}

/// Continuous curve corner radii conforming to Apple Human Interface Guidelines.
public enum DSRadius {
    public static let xs: CGFloat = 5.0
    public static let sm: CGFloat = 8.0
    public static let md: CGFloat = 12.0
    public static let lg: CGFloat = 16.0
    public static let xl: CGFloat = 20.0
    public static let pill: CGFloat = 999.0
}

/// Standardized typography scale with minimum readable thresholds.
public enum DSTypography {
    public static let micro: CGFloat = 10.0
    public static let caption: CGFloat = 11.0
    public static let bodySmall: CGFloat = 12.0
    public static let body: CGFloat = 13.0
    public static let subheadline: CGFloat = 14.0
    public static let headline: CGFloat = 15.0
    public static let title: CGFloat = 18.0
    public static let hero: CGFloat = 22.0
}

/// Motion curves and springs with automatic Reduce Motion handling.
public enum DSMotion {
    @MainActor
    public static func spring(
        response: Double = 0.24,
        damping: Double = 0.78,
        speedMultiplier: Double = 1.0,
        respectReduceMotion: Bool = true
    ) -> Animation? {
        if respectReduceMotion && NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            return .easeInOut(duration: 0.12)
        }
        return .spring(response: response * speedMultiplier, dampingFraction: damping)
    }

    @MainActor
    public static func snappy(speedMultiplier: Double = 1.0) -> Animation? {
        spring(response: 0.18, damping: 0.74, speedMultiplier: speedMultiplier)
    }

    @MainActor
    public static func interactive(speedMultiplier: Double = 1.0) -> Animation? {
        spring(response: 0.28, damping: 0.82, speedMultiplier: speedMultiplier)
    }

    @MainActor
    public static func gentle(speedMultiplier: Double = 1.0) -> Animation? {
        spring(response: 0.35, damping: 0.86, speedMultiplier: speedMultiplier)
    }
}

/// Semantic functional colors and gradients.
public enum DSColor {
    // Action Gradient Tokens
    public static let volumeGradient: [Color] = [
        Color(red: 0.18, green: 0.62, blue: 1.0),
        Color(red: 0.05, green: 0.38, blue: 0.95)
    ]
    public static let brightnessGradient: [Color] = [
        Color(red: 1.0, green: 0.76, blue: 0.18),
        Color(red: 1.0, green: 0.48, blue: 0.0)
    ]
    public static let keyboardGradient: [Color] = [
        Color(red: 0.22, green: 0.85, blue: 0.78),
        Color(red: 0.1, green: 0.6, blue: 0.75)
    ]
    public static let timerFocusGradient: [Color] = [
        Color(red: 0.78, green: 0.42, blue: 1.0),
        Color(red: 0.48, green: 0.22, blue: 0.95)
    ]
    public static let timerBreakGradient: [Color] = [
        Color(red: 0.25, green: 0.85, blue: 0.55),
        Color(red: 0.1, green: 0.65, blue: 0.38)
    ]
    public static let keepAwakeGradient: [Color] = [
        Color(red: 1.0, green: 0.62, blue: 0.18),
        Color(red: 0.95, green: 0.34, blue: 0.08)
    ]
    public static let stashShelfGradient: [Color] = [
        Color(red: 0.0, green: 0.82, blue: 1.0),
        Color(red: 0.04, green: 0.52, blue: 1.0)
    ]
    public static let scratchpadGradient: [Color] = [
        Color(red: 0.32, green: 0.88, blue: 0.55),
        Color(red: 0.1, green: 0.68, blue: 0.38)
    ]
    public static let mediaPlaybackGradient: [Color] = [
        Color(red: 1.0, green: 0.28, blue: 0.52),
        Color(red: 0.85, green: 0.12, blue: 0.42)
    ]
    public static let defaultMutedGradient: [Color] = [
        Color(red: 1.0, green: 0.35, blue: 0.35),
        Color(red: 0.85, green: 0.15, blue: 0.15)
    ]

    public static func actionGradient(for action: ControlAction, isMuted: Bool = false) -> [Color] {
        if action == .volume && isMuted {
            return defaultMutedGradient
        }
        switch action {
        case .volume: return volumeGradient
        case .brightness: return brightnessGradient
        case .keyboardBrightness: return keyboardGradient
        case .timer: return timerFocusGradient
        case .keepAwake: return keepAwakeGradient
        case .stashShelf: return stashShelfGradient
        case .scratchpad: return scratchpadGradient
        case .mediaPlayback: return mediaPlaybackGradient
        case .none: return [Color.secondary, Color.secondary.opacity(0.7)]
        }
    }

    public static func actionPrimaryTint(for action: ControlAction, isMuted: Bool = false) -> Color {
        actionGradient(for: action, isMuted: isMuted).first ?? .accentColor
    }
}
