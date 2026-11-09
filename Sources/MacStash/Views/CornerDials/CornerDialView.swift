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

    private let dialSize: CGFloat = Defaults.HotCorner.defaultDialRadiusPoints

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

        ZStack {
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
        .frame(width: dialSize, height: dialSize)
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

        VStack(spacing: 1.5) {
            if action == .timer {
                HStack(spacing: 3) {
                    Image(systemName: isPomodoroRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(pomodoroMode == .focus ? .purple : .green)

                    Image(systemName: pomodoroMode == .focus ? "brain.head.profile" : "cup.and.saucer.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(pomodoroMode == .focus ? .purple : .green)
                }

                Text(formattedTimer)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.primary)

                if totalRounds > 0 {
                    HStack(spacing: 2.5) {
                        ForEach(0..<min(totalRounds, 6), id: \.self) { roundIndex in
                            Circle()
                                .fill(roundIndex < completedRounds ? (pomodoroMode == .focus ? Color.purple : Color.green) : Color.secondary.opacity(0.35))
                                .frame(width: 3.5, height: 3.5)
                        }
                    }
                    .padding(.top, 0.5)
                }
            } else if action == .keepAwake {
                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(value > 0 ? (action.accentColors.first ?? .orange) : .secondary)

                Text(formattedKeepAwake)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(value > 0 ? .primary : .secondary)
            } else if action == .stashShelf {
                Image(systemName: "tray.2.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(action.accentColors.first ?? .cyan)

                Text("\(stashItemCount)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.primary)
            } else if action == .scratchpad {
                Image(systemName: "note.text")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(action.accentColors.first ?? .green)

                Text("NOTES")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.primary)
            } else if action == .volume {
                Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(isMuted ? .red : (action.accentColors.first ?? .accentColor))

                Text(isMuted ? "MUTE" : "\(Int(round(value * 100)))%")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(isMuted ? .red : .primary)
            } else if action == .keyboardBrightness && !isKeyboardSupported {
                Image(systemName: "keyboard.badge.ellipsis")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.secondary)

                Text("N/A")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.secondary)
            } else {
                Image(systemName: action.systemImage)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(action.accentColors.first ?? .accentColor)

                Text("\(Int(round(value * 100)))%")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.primary)
            }
        }
        .frame(width: 58, height: 58)
        .circularLiquidGlass(
            tint: tint,
            specularIntensity: 1.0,
            causticOpacity: 0.22,
            isHighlighted: isExpanded
        )
        .offset(x: offset.x, y: offset.y)
    }

    private func badgeOffset(for corner: CornerPosition, in size: CGFloat) -> CGPoint {
        let dist: CGFloat = 52
        switch corner {
        case .topLeft:
            return CGPoint(x: dist - (size / 2), y: dist - (size / 2))
        case .topRight:
            return CGPoint(x: (size / 2) - dist, y: dist - (size / 2))
        case .bottomLeft:
            return CGPoint(x: dist - (size / 2), y: (size / 2) - dist)
        case .bottomRight:
            return CGPoint(x: (size / 2) - dist, y: (size / 2) - dist)
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
                style: StrokeStyle(lineWidth: 10, lineCap: .round)
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
                with: .color(primaryColor.opacity(0.35)),
                style: StrokeStyle(lineWidth: 14, lineCap: .round)
            )

            // 3. Vibrant liquid core
            context.stroke(
                liquidPath,
                with: .linearGradient(
                    Gradient(colors: gradientColors),
                    startPoint: geometry.point(radius: trackRadius, angleDegrees: startDeg),
                    endPoint: geometry.point(radius: trackRadius, angleDegrees: endDeg)
                ),
                style: StrokeStyle(lineWidth: 7.5, lineCap: .round)
            )

            // 4. Fluid meniscus head (Droplet bulb with specular highlight)
            let tipPoint = geometry.point(radius: trackRadius, angleDegrees: endDeg)
            let tipBulb = Path(ellipseIn: CGRect(x: tipPoint.x - 6.5, y: tipPoint.y - 6.5, width: 13, height: 13))
            context.fill(tipBulb, with: .color(primaryColor))

            let specularDrop = Path(ellipseIn: CGRect(x: tipPoint.x - 3.5, y: tipPoint.y - 3.5, width: 7, height: 7))
            context.fill(specularDrop, with: .color(Color.white))
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
