import SwiftUI
import AppKit
import MacStashCore

public struct CornerDialView: View {
    @ObservedObject var appState: AppState
    public let corner: CornerPosition
    public let displayID: CGDirectDisplayID

    @State private var isDragging: Bool = false
    @State private var dragValue: Double = 0.5
    @State private var isResetHovered: Bool = false
    @State private var isSkipHovered: Bool = false

    private var dialSize: CGFloat {
        appState.settings.dialRadiusPoints
    }

    private var totalSize: CGFloat {
        dialSize + Defaults.HotCorner.cornerWindowPaddingPoints
    }

    public init(appState: AppState, corner: CornerPosition, displayID: CGDirectDisplayID = 0) {
        self.appState = appState
        self.corner = corner
        self.displayID = displayID
    }

    private var action: ControlAction {
        appState.action(for: corner)
    }

    private var actionColors: [Color] {
        if action == .timer && appState.pomodoroMode != .focus {
            return [Color(red: 0.2, green: 0.85, blue: 0.5), Color(red: 0.1, green: 0.65, blue: 0.35)]
        }
        return action.accentColors
    }

    private var currentValue: Double {
        if isDragging {
            return dragValue
        }
        if action == .volume && appState.audio.isMuted {
            return 0.0
        }
        return appState.getValue(for: action, displayID: displayID)
    }

    public var body: some View {
        let isVisible = appState.isEnabled && appState.isCornerDialsEnabled && action != .none

        ZStack(alignment: alignment(for: corner)) {
            if isVisible {
                let geom = RadialDialGeometry(
                    corner: corner,
                    size: CGSize(width: dialSize, height: dialSize),
                    outerRadius: dialSize - 15,
                    innerRadius: 55
                )

                let isExpanded = isDragging || (appState.activeCorner == corner && appState.activeDisplayID == displayID)

                ZStack {
                    // 1. Sculpted Liquid Glass Quarter-Circle Backdrop Disc
                    QuarterCircleGlassBackdrop(
                        corner: corner,
                        dialSize: dialSize,
                        tint: actionColors.first ?? .clear
                    )

                    // 2. Laser-etched tick marks with liquid glow illumination
                    DialTicksView(
                        geometry: geom,
                        value: currentValue,
                        accentColor: actionColors.first ?? .accentColor
                    )

                    // 3. Precision Luminous Fluid Arc with meniscus droplet
                    DialArcShape(
                        geometry: geom,
                        value: currentValue,
                        gradientColors: actionColors
                    )

                    // 4. Satellite micro-controls for Pomodoro (Floating liquid mercury droplets)
                    if action == .timer && isExpanded {
                        let resetPt = geom.point(radius: 96, angleDegrees: geom.angle(for: 0.14))
                        Button(action: {
                            appState.resetPomodoro()
                        }) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.primary)
                                .frame(width: 24, height: 24)
                                .circularLiquidGlass(
                                    tint: .purple,
                                    specularIntensity: 1.0,
                                    causticOpacity: 0.25,
                                    isHighlighted: isResetHovered
                                )
                                .scaleEffect(isResetHovered ? 1.15 : 1.0)
                                .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isResetHovered)
                        }
                        .buttonStyle(.plain)
                        .help(appState.localized("menubar.reset"))
                        .onHover { isResetHovered = $0 }
                        .position(x: resetPt.x, y: resetPt.y)

                        let skipPt = geom.point(radius: 96, angleDegrees: geom.angle(for: 0.86))
                        Button(action: {
                            appState.skipPomodoroMode()
                        }) {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(appState.pomodoroMode == .focus ? .purple : .green)
                                .frame(width: 24, height: 24)
                                .circularLiquidGlass(
                                    tint: appState.pomodoroMode == .focus ? .purple : .green,
                                    specularIntensity: 1.0,
                                    causticOpacity: 0.25,
                                    isHighlighted: isSkipHovered
                                )
                                .scaleEffect(isSkipHovered ? 1.15 : 1.0)
                                .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isSkipHovered)
                        }
                        .buttonStyle(.plain)
                        .help(appState.localized("menubar.skip"))
                        .onHover { isSkipHovered = $0 }
                        .position(x: skipPt.x, y: skipPt.y)
                    }

                    // 5. Floating Glass Jewel Center Action Badge
                    Button(action: {
                        appState.toggleAction(action, displayID: displayID)
                    }) {
                        CenterActionBadge(
                            action: action,
                            corner: corner,
                            value: currentValue,
                            dialSize: dialSize,
                            isExpanded: isExpanded,
                            formattedTimer: appState.formattedTimerTime,
                            isPomodoroRunning: appState.isPomodoroRunning,
                            isPomodoroPaused: appState.isPomodoroPaused,
                            pomodoroMode: appState.pomodoroMode,
                            completedRounds: appState.pomodoroCompletedRounds,
                            totalRounds: appState.pomodoroTotalRounds,
                            isMuted: appState.audio.isMuted,
                            isKeyboardSupported: appState.keyboard.isSupported,
                            formattedKeepAwake: appState.keepAwake.formattedRemaining,
                            stashItemCount: appState.stashShelf.items.count,
                            tint: actionColors.first ?? .clear
                        )
                    }
                    .buttonStyle(.plain)
                }
                .frame(width: dialSize, height: dialSize)
                .scaleEffect(isExpanded ? 1.0 : 0.05, anchor: unitPoint(for: corner))
                .opacity(isExpanded ? appState.settings.dialOpacity : 0.0)
                .animation(
                    NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
                        ? .easeInOut(duration: 0.1)
                        : .spring(response: 0.30 * appState.settings.animationSpeedMultiplier, dampingFraction: 0.76),
                    value: isExpanded
                )
                .gesture(
                    DragGesture(minimumDistance: 4)
                        .onChanged { gesture in
                            let center = geom.center
                            let loc = gesture.location
                            let dist = hypot(loc.x - center.x, loc.y - center.y)

                            // Ignore touches on center badge (dist < 58) or outside dial perimeter
                            guard dist >= 58 && dist <= dialSize + 30 else {
                                return
                            }

                            if action == .timer && appState.isPomodoroRunning {
                                return
                            }

                            let angle = calculateAngle(from: center, to: loc, corner: corner)
                            let norm = normalizeAngle(angle, for: corner)

                            if !isDragging {
                                isDragging = true
                            }

                            if action == .timer {
                                let mins = max(1, min(60, Int(round(norm * 60.0))))
                                let snapped = Double(mins) / 60.0
                                dragValue = snapped
                                appState.setValue(for: action, value: snapped, displayID: displayID)
                            } else {
                                dragValue = norm
                                appState.setValue(for: action, value: norm, displayID: displayID)
                            }
                        }
                        .onEnded { _ in
                            if isDragging {
                                isDragging = false
                                appState.setValue(for: action, value: dragValue, displayID: displayID)
                                appState.saveSettings()
                            }
                        }
                )
            }
        }
        .frame(width: totalSize, height: totalSize, alignment: alignment(for: corner))
    }

    private func alignment(for corner: CornerPosition) -> Alignment {
        switch corner {
        case .topLeft: return .topLeading
        case .topRight: return .topTrailing
        case .bottomLeft: return .bottomLeading
        case .bottomRight: return .bottomTrailing
        }
    }

    private func unitPoint(for corner: CornerPosition) -> UnitPoint {
        switch corner {
        case .topLeft: return .topLeading
        case .topRight: return .topTrailing
        case .bottomLeft: return .bottomLeading
        case .bottomRight: return .bottomTrailing
        }
    }

    private func calculateAngle(from center: CGPoint, to point: CGPoint, corner: CornerPosition) -> Double {
        let dx = Double(point.x - center.x)
        let dy = Double(point.y - center.y)
        var rad = atan2(dy, dx)
        if rad < 0 { rad += 2 * .pi }
        return rad * 180.0 / .pi
    }

    private func normalizeAngle(_ degrees: Double, for corner: CornerPosition) -> Double {
        switch corner {
        case .bottomRight:
            let clamped = max(180.0, min(270.0, degrees))
            return (clamped - 180.0) / 90.0
        case .bottomLeft:
            var deg = degrees
            if deg < 180.0 { deg += 360.0 }
            let clamped = max(270.0, min(360.0, deg))
            return (360.0 - clamped) / 90.0
        case .topRight:
            let clamped = max(90.0, min(180.0, degrees))
            return (clamped - 90.0) / 90.0
        case .topLeft:
            let clamped = max(0.0, min(90.0, degrees))
            return (90.0 - clamped) / 90.0
        }
    }
}

// MARK: - Sculpted Liquid Glass Quarter-Circle Backdrop

public struct QuarterCircleGlassBackdrop: View {
    public let corner: CornerPosition
    public let dialSize: CGFloat
    public let tint: Color

    public init(corner: CornerPosition, dialSize: CGFloat, tint: Color) {
        self.corner = corner
        self.dialSize = dialSize
        self.tint = tint
    }

    public var body: some View {
        ZStack {
            // Layer 1: Frosted refractive glass substrate
            QuarterCircleBackdrop(corner: corner)
                .fill(.ultraThinMaterial)

            // Layer 2: Caustic ambient reflection originating from screen vertex
            QuarterCircleBackdrop(corner: corner)
                .fill(
                    RadialGradient(
                        colors: [
                            tint.opacity(0.20),
                            tint.opacity(0.06),
                            Color.clear
                        ],
                        center: unitPoint(for: corner),
                        startRadius: 15,
                        endRadius: dialSize * 0.95
                    )
                )

            // Layer 3: Glass surface gloss sheen
            QuarterCircleBackdrop(corner: corner)
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity(0.12), location: 0.0),
                            .init(color: Color.white.opacity(0.02), location: 0.4),
                            .init(color: Color.clear, location: 0.7)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Layer 4: Dual-path specular perimeter bevel
            QuarterCircleBackdrop(corner: corner)
                .stroke(
                    LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity(0.55), location: 0.0),
                            .init(color: Color.white.opacity(0.15), location: 0.45),
                            .init(color: Color.white.opacity(0.04), location: 0.8),
                            .init(color: tint.opacity(0.3), location: 1.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.2
                )
        }
        .frame(width: dialSize, height: dialSize)
        .shadow(color: Color.black.opacity(0.32), radius: 14, x: 0, y: 5)
        .shadow(color: tint == .clear ? Color.clear : tint.opacity(0.15), radius: 10, x: 0, y: 0)
    }

    private func unitPoint(for corner: CornerPosition) -> UnitPoint {
        switch corner {
        case .topLeft: return .topLeading
        case .topRight: return .topTrailing
        case .bottomLeft: return .bottomLeading
        case .bottomRight: return .bottomTrailing
        }
    }
}

// MARK: - Center Floating Glass Jewel Badge

// MARK: - Tactical Pro HUD Center Action Hub

public struct CenterActionBadge: View {
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
        tint: Color
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
    }

    public var body: some View {
        let offset = badgeOffset(for: corner, in: dialSize)

        VStack(spacing: 2) {
            actionIconView

            actionReadoutView
        }
        .frame(width: 64, height: 64)
        .background(
            ZStack {
                Circle().fill(.ultraThinMaterial)
                Circle().fill(Color.black.opacity(0.38))
                if tint != .clear {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [tint.opacity(isExpanded ? 0.32 : 0.18), Color.clear],
                                center: .center,
                                startRadius: 2,
                                endRadius: 32
                            )
                        )
                }
            }
        )
        .overlay(
            Circle()
                .strokeBorder(
                    LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity(isExpanded ? 0.85 : 0.65), location: 0.0),
                            .init(color: Color.white.opacity(0.20), location: 0.5),
                            .init(color: (tint == .clear ? Color.white : tint).opacity(0.40), location: 1.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: isExpanded ? 1.4 : 1.15
                )
        )
        .shadow(color: Color.black.opacity(0.35), radius: 7, x: 0, y: 3)
        .offset(x: offset.x, y: offset.y)
    }

    @ViewBuilder
    private var actionIconView: some View {
        if action == .timer {
            HStack(spacing: 3) {
                Image(systemName: isPomodoroRunning ? "pause.fill" : "play.fill")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(pomodoroMode == .focus ? Color(red: 0.85, green: 0.45, blue: 1.0) : Color(red: 0.3, green: 0.9, blue: 0.55))

                Image(systemName: pomodoroMode == .focus ? "brain.head.profile" : "cup.and.saucer.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(pomodoroMode == .focus ? Color.purple : Color.green)
            }
        } else if action == .keepAwake {
            Image(systemName: "cup.and.saucer.fill")
                .font(.system(size: 18, weight: .bold))
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
                .font(.system(size: 18, weight: .bold))
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
                .font(.system(size: 18, weight: .bold))
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
                .font(.system(size: 18, weight: .bold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(
                    isMuted
                        ? LinearGradient(colors: [Color(red: 1.0, green: 0.35, blue: 0.35), Color(red: 0.85, green: 0.15, blue: 0.15)], startPoint: .top, endPoint: .bottom)
                        : LinearGradient(colors: [Color(red: 0.2, green: 0.8, blue: 1.0), Color(red: 0.05, green: 0.55, blue: 0.95)], startPoint: .top, endPoint: .bottom)
                )
        } else if action == .brightness {
            Image(systemName: "sun.max.fill")
                .font(.system(size: 18, weight: .bold))
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
                .font(.system(size: 18, weight: .bold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(
                    isKeyboardSupported
                        ? LinearGradient(colors: [Color(red: 0.85, green: 0.92, blue: 1.0), Color(red: 0.5, green: 0.75, blue: 0.98)], startPoint: .top, endPoint: .bottom)
                        : LinearGradient(colors: [Color.secondary, Color.secondary.opacity(0.6)], startPoint: .top, endPoint: .bottom)
                )
        } else {
            Image(systemName: action.systemImage)
                .font(.system(size: 18, weight: .bold))
                .symbolRenderingMode(.hierarchical)
                .foregroundColor(action.accentColors.first ?? .accentColor)
        }
    }

    @ViewBuilder
    private var actionReadoutView: some View {
        if action == .timer {
            VStack(spacing: 1.5) {
                Text(formattedTimer)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.primary)

                if totalRounds > 0 {
                    HStack(spacing: 2.5) {
                        ForEach(0..<min(totalRounds, 6), id: \.self) { roundIndex in
                            Circle()
                                .fill(roundIndex < completedRounds ? (pomodoroMode == .focus ? Color.purple : Color.green) : Color.secondary.opacity(0.35))
                                .frame(width: 3.0, height: 3.0)
                        }
                    }
                }
            }
        } else if action == .keepAwake {
            Text(formattedKeepAwake)
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .foregroundColor(value > 0 ? .primary : .secondary)
        } else if action == .stashShelf {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(stashItemCount)")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(.primary)
                Text(LocalizationService.shared.localized("dial.items"))
                    .font(.system(size: 8, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
            }
        } else if action == .scratchpad {
            Text(LocalizationService.shared.localized("dial.notes"))
                .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                .foregroundColor(.primary)
        } else if action == .volume && isMuted {
            Text(LocalizationService.shared.localized("dial.mute"))
                .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                .foregroundColor(.red)
        } else if action == .keyboardBrightness && !isKeyboardSupported {
            Text(LocalizationService.shared.localized("dial.na"))
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .foregroundColor(.secondary)
        } else {
            HStack(alignment: .firstTextBaseline, spacing: 1) {
                Text("\(Int(round(value * 100)))")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(.primary)

                Text("%")
                    .font(.system(size: 8.5, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
            }
        }
    }

    private func badgeOffset(for corner: CornerPosition, in size: CGFloat) -> CGPoint {
        // Mathematically centered along the 45° line of symmetry (x = y = 51 from corner vertex)
        let offsetDist: CGFloat = 39.0
        switch corner {
        case .topLeft:
            return CGPoint(x: -offsetDist, y: -offsetDist)
        case .topRight:
            return CGPoint(x: offsetDist, y: -offsetDist)
        case .bottomLeft:
            return CGPoint(x: -offsetDist, y: offsetDist)
        case .bottomRight:
            return CGPoint(x: offsetDist, y: offsetDist)
        }
    }
}

// MARK: - Luminous Fluid Arc Shape with Meniscus Droplet

public struct DialArcShape: View {
    public let geometry: RadialDialGeometry
    public let value: Double
    public let gradientColors: [Color]

    public init(geometry: RadialDialGeometry, value: Double, gradientColors: [Color]) {
        self.geometry = geometry
        self.value = value
        self.gradientColors = gradientColors
    }

    public var body: some View {
        Canvas { context, _ in
            let trackRadius = geometry.outerRadius - 20
            let startDeg = geometry.angle(for: 0.0)
            let fullDeg = geometry.angle(for: 1.0)
            let isClockwise = geometry.corner == .bottomLeft || geometry.corner == .topLeft

            // 0. Inner concentric guide arc (framing the central hub into the dial)
            var guidePath = Path()
            guidePath.addArc(
                center: geometry.center,
                radius: 106,
                startAngle: .degrees(startDeg),
                endAngle: .degrees(fullDeg),
                clockwise: isClockwise
            )
            context.stroke(
                guidePath,
                with: .color(Color.white.opacity(0.06)),
                style: StrokeStyle(lineWidth: 1.0)
            )

            // 1. Concave glass trench groove (the channel where liquid flows)
            var trenchPath = Path()
            trenchPath.addArc(
                center: geometry.center,
                radius: trackRadius,
                startAngle: .degrees(startDeg),
                endAngle: .degrees(fullDeg),
                clockwise: isClockwise
            )
            context.stroke(
                trenchPath,
                with: .color(Color.white.opacity(0.08)),
                style: StrokeStyle(lineWidth: 9, lineCap: .round)
            )

            guard value > 0.01 else { return }
            let endDeg = geometry.angle(for: value)

            var liquidPath = Path()
            liquidPath.addArc(
                center: geometry.center,
                radius: trackRadius,
                startAngle: .degrees(startDeg),
                endAngle: .degrees(endDeg),
                clockwise: isClockwise
            )

            // 2. Soft luminous fluid bloom (glow under-layer)
            let primaryColor = gradientColors.first ?? .cyan
            context.stroke(
                liquidPath,
                with: .color(primaryColor.opacity(0.32)),
                style: StrokeStyle(lineWidth: 13, lineCap: .round)
            )

            // 3. Vibrant liquid core
            context.stroke(
                liquidPath,
                with: .linearGradient(
                    Gradient(colors: gradientColors),
                    startPoint: geometry.point(radius: trackRadius, angleDegrees: startDeg),
                    endPoint: geometry.point(radius: trackRadius, angleDegrees: endDeg)
                ),
                style: StrokeStyle(lineWidth: 7.0, lineCap: .round)
            )

            // 4. Precision tactile thumb knob (Apple concentric ring indicator)
            let tipPoint = geometry.point(radius: trackRadius, angleDegrees: endDeg)
            let outerKnob = Path(ellipseIn: CGRect(x: tipPoint.x - 7.5, y: tipPoint.y - 7.5, width: 15, height: 15))
            context.fill(outerKnob, with: .color(primaryColor))
            context.stroke(outerKnob, with: .color(Color.white.opacity(0.92)), lineWidth: 1.25)

            let innerCore = Path(ellipseIn: CGRect(x: tipPoint.x - 3.5, y: tipPoint.y - 3.5, width: 7, height: 7))
            context.fill(innerCore, with: .color(Color.white))
        }
    }
}

// MARK: - Shapes

public struct QuarterCircleBackdrop: Shape {
    public let corner: CornerPosition

    public init(corner: CornerPosition) {
        self.corner = corner
    }

    public func path(in rect: CGRect) -> Path {
        var path = Path()
        switch corner {
        case .topLeft:
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addArc(
                center: CGPoint(x: rect.minX, y: rect.minY),
                radius: rect.width,
                startAngle: .degrees(0),
                endAngle: .degrees(90),
                clockwise: false
            )
            path.closeSubpath()
        case .topRight:
            path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addArc(
                center: CGPoint(x: rect.maxX, y: rect.minY),
                radius: rect.width,
                startAngle: .degrees(180),
                endAngle: .degrees(90),
                clockwise: true
            )
            path.closeSubpath()
        case .bottomLeft:
            path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addArc(
                center: CGPoint(x: rect.minX, y: rect.maxY),
                radius: rect.width,
                startAngle: .degrees(270),
                endAngle: .degrees(360),
                clockwise: false
            )
            path.closeSubpath()
        case .bottomRight:
            path.move(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addArc(
                center: CGPoint(x: rect.maxX, y: rect.maxY),
                radius: rect.width,
                startAngle: .degrees(180),
                endAngle: .degrees(270),
                clockwise: false
            )
            path.closeSubpath()
        }
        return path
    }
}
