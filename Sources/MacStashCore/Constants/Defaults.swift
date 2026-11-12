import Foundation
import CoreGraphics

public enum Defaults {
    public static let schemaVersion: Int = 1

    public static var appVersion: String {
        if let ver = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return ver
        }
        var current = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        for _ in 0..<5 {
            let path = current.appendingPathComponent("VERSION").path
            if let str = try? String(contentsOfFile: path, encoding: .utf8) {
                let trimmed = str.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty { return trimmed }
            }
            current = current.deletingLastPathComponent()
        }
        return "2.16.3"
    }

    public enum HotCorner {
        public static let defaultHitZoneSizePoints: CGFloat = 10.0
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
        public static let cornerWindowPaddingPoints: CGFloat = 20.0
        public static let defaultAnimationDurationSeconds: TimeInterval = 0.18
        public static let defaultCornerDisplayTarget: HotCornerDisplayTarget = .builtIn
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

    public enum KeepAwake {
        public static let defaultPresetMinutes: [Int] = [15, 30, 60, 120, -1]
        public static let defaultDurationMinutes: Int = 30
    }

    public enum StashShelf {
        public static let defaultEnabled: Bool = false
        public static let maxItems: Int = 50
        public static let defaultWidthPoints: CGFloat = 310.0
    }

    public enum Scratchpad {
        public static let defaultEnabled: Bool = false
        public static let defaultWidthPoints: CGFloat = 340.0
        public static let defaultHeightPoints: CGFloat = 400.0
    }

    public enum EdgeSliders {
        public static let defaultPosition: EdgePosition = .right
        /// Interactive panel width; must fully contain the expanded Dynamic Island (312pt) plus its screen-edge inset.
        public static let panelWidthPoints: CGFloat = 340.0
        /// Interactive panel height; must fully contain the tallest bar layout (vertical transport controls + artwork capsule) plus shadow bleed.
        public static let panelHeightPoints: CGFloat = 440.0
        /// Vertical margin kept between the panel and the top of the screen when sharing an edge with a drawer.
        public static let drawerClearancePoints: CGFloat = 10.0
    }

    public enum LeftEdgeDrawer {
        public static let defaultPosition: EdgePosition = .left
        public static let tabBarWidthPoints: CGFloat = 36.0
        public static let spacingPoints: CGFloat = 6.0
        public static let panelWidthPoints: CGFloat = 410.0
        public static let panelHeightPoints: CGFloat = 520.0
        public static let shelfTotalWidthPoints: CGFloat = 352.0
        public static let shelfTotalHeightPoints: CGFloat = 485.0
        public static let scratchpadTotalWidthPoints: CGFloat = 382.0
        public static let scratchpadTotalHeightPoints: CGFloat = 410.0
    }
}
