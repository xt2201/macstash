import SwiftUI
import AppKit
import MacStashCore
import MacStashDesignSystem

public struct CenterActionBadge: View {
    @Environment(\.colorScheme) private var colorScheme
    public let action: ControlAction
    public let corner: CornerPosition
    public let value: Double
    public let dialSize: CGFloat
    public let isExpanded: Bool
    public let formattedTimer: String
    public let isPomodoroRunning: Bool
    public let isPomodoroPaused: Bool
    public let pomodoroMode: PomodoroMode
    public let completedRounds: Int
    public let totalRounds: Int
    public let isMuted: Bool
    public let isKeyboardSupported: Bool
    public let formattedKeepAwake: String
    public let stashItemCount: Int
    public let tint: Color
    public let gradientColors: [Color]?
    public let mediaTimeText: String?

    @State private var isHovered: Bool = false

    public init(
        action: ControlAction,
        corner: CornerPosition,
        value: Double,
        dialSize: CGFloat,
        isExpanded: Bool,
        formattedTimer: String,
        isPomodoroRunning: Bool,
        isPomodoroPaused: Bool,
        pomodoroMode: PomodoroMode,
        completedRounds: Int,
        totalRounds: Int,
        isMuted: Bool,
        isKeyboardSupported: Bool,
        formattedKeepAwake: String,
        stashItemCount: Int,
        tint: Color,
        gradientColors: [Color]? = nil,
        mediaTimeText: String? = nil
    ) {
        self.action = action
        self.corner = corner
        self.value = value
        self.dialSize = dialSize
        self.isExpanded = isExpanded
        self.formattedTimer = formattedTimer
        self.isPomodoroRunning = isPomodoroRunning
        self.isPomodoroPaused = isPomodoroPaused
        self.pomodoroMode = pomodoroMode
        self.completedRounds = completedRounds
        self.totalRounds = totalRounds
        self.isMuted = isMuted
        self.isKeyboardSupported = isKeyboardSupported
        self.formattedKeepAwake = formattedKeepAwake
        self.stashItemCount = stashItemCount
        self.tint = tint
        self.gradientColors = gradientColors
        self.mediaTimeText = mediaTimeText
    }

    private var reduceMotion: Bool {
        NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
    }

    private var accessibleDescription: String {
        let actionName = action.localizedDisplayName()
        if action == .timer {
            return "\(actionName): \(formattedTimer)"
        } else if action == .volume && isMuted {
            return "\(actionName): \(LocalizationService.shared.localized("dial.mute"))"
        } else if action == .keepAwake {
            return "\(actionName): \(formattedKeepAwake)"
        } else if action == .stashShelf {
            return "\(actionName): \(stashItemCount) \(LocalizationService.shared.localized("dial.items"))"
        } else {
            return "\(actionName): \(Int(round(value * 100))) percent"
        }
    }

    public var body: some View {
        let metrics = CornerDialMetrics(dialSize: dialSize)
        let offset = metrics.badgeOffset(for: corner)
        let badgeSide = metrics.badgeDiameter
        let scale = metrics.contentScale
        let isDark = colorScheme == .dark
        let clampedValue = max(0.0, min(1.0, value))
        let ringColors: [Color] = {
            if action == .volume && isMuted {
                return [Color.red, Color.red.opacity(0.65)]
            }
            if let explicit = gradientColors, !explicit.isEmpty {
                return explicit
            }
            return tint == .clear ? [Color.accentColor, Color.accentColor.opacity(0.7)] : [tint, tint.opacity(0.72)]
        }()
        let ringWidth = max(1.8, 2.2 * scale)
        let ringInset = max(2.8, 3.2 * scale)
        let hoverScale: CGFloat = (isHovered && !reduceMotion) ? 1.045 : 1.0

        VStack(spacing: 1.5 * scale) {
            actionIconView(scale: scale)

            actionReadoutView(scale: scale)
        }
        .frame(width: badgeSide, height: badgeSide)
        .contentShape(Circle())
        .background(
            ZStack {
                Circle().fill(.ultraThinMaterial)
                Circle().fill(isDark ? Color.black.opacity(0.36) : Color.white.opacity(0.64))
                if tint != .clear {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [tint.opacity(isHovered ? 0.38 : (isExpanded ? 0.30 : 0.18)), Color.clear],
                                center: .center,
                                startRadius: 2,
                                endRadius: badgeSide * 0.52
                            )
                        )
                }
            }
        )
        .overlay(
            ZStack {
                Circle()
                    .inset(by: ringInset)
                    .stroke(
                        isDark ? Color.white.opacity(0.09) : Color.black.opacity(0.08),
                        lineWidth: ringWidth
                    )

                if clampedValue > 0.01 {
                    Circle()
                        .inset(by: ringInset)
                        .trim(from: 0, to: clampedValue)
                        .stroke(
                            LinearGradient(
                                colors: ringColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: ringWidth, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                }

                Circle()
                    .strokeBorder(
                        LinearGradient(
                            stops: [
                                .init(color: Color.white.opacity(isHovered ? 0.95 : (isExpanded ? (isDark ? 0.82 : 0.94) : 0.65)), location: 0.0),
                                .init(color: Color.primary.opacity(0.16), location: 0.5),
                                .init(color: (tint == .clear ? Color.primary : tint).opacity(isHovered ? 0.60 : 0.42), location: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isHovered ? 1.55 : (isExpanded ? 1.35 : 1.15)
                    )
            }
        )
        .shadow(color: Color.black.opacity(isDark ? 0.38 : 0.16), radius: max(5, 6 * scale), x: 0, y: 2.5)
        .scaleEffect(hoverScale)
        .animation(reduceMotion ? nil : .spring(response: 0.22, dampingFraction: 0.76), value: isHovered)
        .offset(x: offset.x, y: offset.y)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibleDescription)
        .accessibilityHint(LocalizationService.shared.localized("corners.action.toggle"))
        .accessibilityAddTraits(.isButton)
        .onHover { hovering in
            isHovered = hovering
        }
    }

    @ViewBuilder
    private func actionIconView(scale: CGFloat) -> some View {
        let iconSize = 16.5 * scale
        if action == .timer {
            HStack(spacing: 2.5 * scale) {
                Image(systemName: isPomodoroRunning ? "pause.fill" : "play.fill")
                    .font(.system(size: 7.5 * scale, weight: .bold))
                    .foregroundColor(pomodoroMode == .focus ? Color(red: 0.85, green: 0.45, blue: 1.0) : Color(red: 0.3, green: 0.9, blue: 0.55))

                Image(systemName: pomodoroMode == .focus ? "brain.head.profile" : "cup.and.saucer.fill")
                    .font(.system(size: 13.0 * scale, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(pomodoroMode == .focus ? Color.purple : Color.green)
            }
        } else if action == .keepAwake {
            Image(systemName: "cup.and.saucer.fill")
                .font(.system(size: iconSize, weight: .bold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(red: 1.0, green: 0.72, blue: 0.2), Color(red: 0.95, green: 0.45, blue: 0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        } else if action == .stashShelf {
            Image(systemName: "tray.2.fill")
                .font(.system(size: iconSize, weight: .bold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(red: 0.2, green: 0.85, blue: 1.0), Color(red: 0.0, green: 0.55, blue: 0.95)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        } else if action == .scratchpad {
            Image(systemName: "note.text")
                .font(.system(size: iconSize, weight: .bold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(red: 0.3, green: 0.9, blue: 0.55), Color(red: 0.1, green: 0.65, blue: 0.35)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        } else if action == .volume {
            Image(systemName: isMuted ? "speaker.slash.fill" : (value > 0.66 ? "speaker.wave.3.fill" : (value > 0.33 ? "speaker.wave.2.fill" : (value > 0.01 ? "speaker.wave.1.fill" : "speaker.fill"))))
                .font(.system(size: iconSize, weight: .bold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(
                    isMuted
                        ? LinearGradient(colors: [Color(red: 1.0, green: 0.35, blue: 0.35), Color(red: 0.85, green: 0.15, blue: 0.15)], startPoint: .top, endPoint: .bottom)
                        : LinearGradient(colors: [Color(red: 0.2, green: 0.8, blue: 1.0), Color(red: 0.05, green: 0.55, blue: 0.95)], startPoint: .top, endPoint: .bottom)
                )
        } else if action == .brightness {
            Image(systemName: "sun.max.fill")
                .font(.system(size: iconSize, weight: .bold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(red: 1.0, green: 0.84, blue: 0.20), Color(red: 1.0, green: 0.55, blue: 0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        } else if action == .keyboardBrightness {
            Image(systemName: isKeyboardSupported ? "keyboard.fill" : "keyboard.badge.ellipsis")
                .font(.system(size: iconSize, weight: .bold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(
                    isKeyboardSupported
                        ? LinearGradient(colors: [Color(red: 0.85, green: 0.92, blue: 1.0), Color(red: 0.5, green: 0.75, blue: 0.98)], startPoint: .top, endPoint: .bottom)
                        : LinearGradient(colors: [Color.secondary, Color.secondary.opacity(0.6)], startPoint: .top, endPoint: .bottom)
                )
        } else if action == .mediaPlayback {
            Image(systemName: "music.note")
                .font(.system(size: iconSize, weight: .bold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(red: 1.0, green: 0.32, blue: 0.58), Color(red: 0.88, green: 0.12, blue: 0.45)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        } else {
            Image(systemName: action.systemImage)
                .font(.system(size: iconSize, weight: .bold))
                .symbolRenderingMode(.hierarchical)
                .foregroundColor(action.accentColors.first ?? .accentColor)
        }
    }

    @ViewBuilder
    private func actionReadoutView(scale: CGFloat) -> some View {
        if action == .timer {
            VStack(spacing: 1.5 * scale) {
                Text(formattedTimer)
                    .font(.system(size: 10.5 * scale, weight: .bold, design: .monospaced))
                    .monospacedDigit()
                    .foregroundColor(.primary)

                if totalRounds > 0 {
                    HStack(spacing: 2.5 * scale) {
                        ForEach(0..<min(totalRounds, 6), id: \.self) { roundIndex in
                            Circle()
                                .fill(roundIndex < completedRounds ? (pomodoroMode == .focus ? Color.purple : Color.green) : Color.secondary.opacity(0.35))
                                .frame(width: 3.0 * scale, height: 3.0 * scale)
                        }
                    }
                }
            }
        } else if action == .keepAwake {
            Text(formattedKeepAwake)
                .font(.system(size: 10.0 * scale, weight: .heavy, design: .rounded))
                .foregroundColor(value > 0 ? .primary : .secondary)
        } else if action == .stashShelf {
            HStack(alignment: .firstTextBaseline, spacing: 2 * scale) {
                Text("\(stashItemCount)")
                    .font(.system(size: 12.5 * scale, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(.primary)
                Text(LocalizationService.shared.localized("dial.items"))
                    .font(.system(size: 7.5 * scale, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
            }
        } else if action == .scratchpad {
            Text(LocalizationService.shared.localized("dial.notes"))
                .font(.system(size: 9.5 * scale, weight: .heavy, design: .rounded))
                .foregroundColor(.primary)
        } else if action == .volume && isMuted {
            Text(LocalizationService.shared.localized("dial.mute"))
                .font(.system(size: 9.5 * scale, weight: .heavy, design: .rounded))
                .foregroundColor(.red)
        } else if (action == .volume || action == .mediaPlayback), let time = mediaTimeText, !time.isEmpty {
            Text(time)
                .font(.system(size: 9.5 * scale, weight: .heavy, design: .monospaced))
                .monospacedDigit()
                .foregroundColor(.primary)
        } else if action == .keyboardBrightness && !isKeyboardSupported {
            Text(LocalizationService.shared.localized("dial.na"))
                .font(.system(size: 10.0 * scale, weight: .heavy, design: .rounded))
                .foregroundColor(.secondary)
        } else {
            HStack(alignment: .firstTextBaseline, spacing: 1.0 * scale) {
                Text("\(Int(round(value * 100)))")
                    .font(.system(size: 13.0 * scale, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(.primary)

                Text("%")
                    .font(.system(size: 8.2 * scale, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
            }
        }
    }

    public static func badgeSide(for dialSize: CGFloat) -> CGFloat {
        CornerDialMetrics(dialSize: dialSize).badgeDiameter
    }

    public static func cornerMargin(for dialSize: CGFloat) -> CGFloat {
        CornerDialMetrics(dialSize: dialSize).edgeWallMargin
    }

    public static func offsetDist(for dialSize: CGFloat) -> CGFloat {
        CornerDialMetrics(dialSize: dialSize).badgeCenterOffsetDistance
    }

    public static func badgeOffset(for corner: CornerPosition, in size: CGFloat) -> CGPoint {
        CornerDialMetrics(dialSize: size).badgeOffset(for: corner)
    }

    public static func badgeOuterRadius(for dialSize: CGFloat) -> CGFloat {
        CornerDialMetrics(dialSize: dialSize).badgeOuterRadius
    }
}
