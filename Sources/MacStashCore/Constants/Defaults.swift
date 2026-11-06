import Foundation
import CoreGraphics

public enum Defaults {
    public static let schemaVersion: Int = 1

    public enum HotCorner {
        public static let defaultHitZoneSizePoints: CGFloat = 5.0
        public static let minHitZoneSizePoints: CGFloat = 1.0
        public static let maxHitZoneSizePoints: CGFloat = 20.0

        public static let defaultDwellDelaySeconds: TimeInterval = 0.2
        public static let minDwellDelaySeconds: TimeInterval = 0.0
        public static let maxDwellDelaySeconds: TimeInterval = 1.0

        public static let defaultHideDelaySeconds: TimeInterval = 0.25
        public static let minHideDelaySeconds: TimeInterval = 0.05
        public static let maxHideDelaySeconds: TimeInterval = 1.0

        public static let defaultDialRadiusPoints: CGFloat = 145.0
        public static let defaultOuterPaddingPoints: CGFloat = 30.0
        public static let defaultAnimationDurationSeconds: TimeInterval = 0.18
    }

    public enum Brightness {
        public static let defaultLevel: Float = 0.75
        public static let minLevel: Float = 0.0
        public static let maxLevel: Float = 1.0
        public static let stepFraction: Float = 0.05
        public static let ddcTimeoutSeconds: TimeInterval = 0.1
        public static let debounceIntervalSeconds: TimeInterval = 0.05
    }

    public enum Pomodoro {
        public static let defaultFocusDurationSeconds: Int = 1500
        public static let defaultShortBreakDurationSeconds: Int = 300
        public static let defaultLongBreakDurationSeconds: Int = 900
        public static let defaultRoundsBeforeLongBreak: Int = 4
    }

    public enum Audio {
        public static let defaultVolume: Float = 0.5
        public static let defaultSoundVolume: Float = 0.6
        public static let minSoundIntervalSeconds: TimeInterval = 0.035
    }
}
