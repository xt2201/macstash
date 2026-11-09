import SwiftUI
import AppKit
import MacStashCore

public struct CornerDialView: View {
    @ObservedObject var appState: AppState
    public let corner: CornerPosition
    public let displayID: CGDirectDisplayID

    @State private var isDragging: Bool = false
    @State private var dragValue: Double = 0.5

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
                    // Quarter-circle backdrop disc
                    QuarterCircleBackdrop(corner: corner)
                        .fill(.ultraThinMaterial)
                        .frame(width: dialSize, height: dialSize)
                        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 3)

                    // Tick marks
                    DialTicksView(
                        geometry: geom,
                        value: currentValue,
                        accentColor: actionColors.first ?? .accentColor
                    )

                    // Active progress ring arc
                    DialArcShape(
                        geometry: geom,
                        value: currentValue,
                        gradientColors: actionColors
                    )

                    // Satellite micro-controls for Pomodoro
                    if action == .timer && isExpanded {
                        let resetPt = geom.point(radius: 96, angleDegrees: geom.angle(for: 0.14))
                        Button(action: {
                            appState.resetPomodoro()
                        }) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.secondary)
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(.ultraThinMaterial))
                                .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                                .shadow(color: Color.black.opacity(0.25), radius: 2, x: 0, y: 1)
                        }
                        .buttonStyle(.plain)
                        .help(appState.localized("menubar.reset"))
                        .position(x: resetPt.x, y: resetPt.y)

                        let skipPt = geom.point(radius: 96, angleDegrees: geom.angle(for: 0.86))
                        Button(action: {
                            appState.skipPomodoroMode()
                        }) {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(appState.pomodoroMode == .focus ? .purple : .green)
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(.ultraThinMaterial))
                                .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                                .shadow(color: Color.black.opacity(0.25), radius: 2, x: 0, y: 1)
                        }
                        .buttonStyle(.plain)
                        .help(appState.localized("menubar.skip"))
                        .position(x: skipPt.x, y: skipPt.y)
                    }

                    // Center Action Icon & Value readout (Tap to toggle)
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
                            stashItemCount: appState.stashShelf.items.count
                        )
                    }
                    .buttonStyle(.plain)
                }
                .scaleEffect(isExpanded ? 1.0 : 0.05, anchor: unitPoint(for: corner))
                .opacity(isExpanded ? appState.settings.dialOpacity : 0.0)
                .animation(
                    NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
                        ? .easeInOut(duration: 0.1)
                        : .spring(response: 0.28 * appState.settings.animationSpeedMultiplier, dampingFraction: 0.72),
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

// MARK: - Subviews

private struct CenterActionBadge: View {
    let action: ControlAction
    let corner: CornerPosition
    let value: Double
    let dialSize: CGFloat
    let isExpanded: Bool
    let formattedTimer: String
    let isPomodoroRunning: Bool
    let isPomodoroPaused: Bool
    let pomodoroMode: PomodoroMode
    let completedRounds: Int
    let totalRounds: Int
    let isMuted: Bool
    let isKeyboardSupported: Bool
    let formattedKeepAwake: String
    let stashItemCount: Int

    var body: some View {
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
        .background(
            Circle()
                .fill(.ultraThickMaterial)
                .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
                .overlay(
                    Circle()
                        .strokeBorder(
                            action == .timer && (isPomodoroRunning || isPomodoroPaused)
                                ? (pomodoroMode == .focus ? Color.purple.opacity(0.7) : Color.green.opacity(0.7))
                                : Color.white.opacity(0.1),
                            lineWidth: 1.5
                        )
                )
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

private struct DialArcShape: View {
    let geometry: RadialDialGeometry
    let value: Double
    let gradientColors: [Color]

    var body: some View {
        Canvas { context, _ in
            guard value > 0.01 else { return }
            let trackRadius = geometry.outerRadius - 20
            let startDeg = geometry.angle(for: 0.0)
            let endDeg = geometry.angle(for: value)

            var path = Path()
            path.addArc(
                center: geometry.center,
                radius: trackRadius,
                startAngle: .degrees(startDeg),
                endAngle: .degrees(endDeg),
                clockwise: geometry.corner == .bottomLeft || geometry.corner == .topLeft
            )

            context.stroke(
                path,
                with: .linearGradient(
                    Gradient(colors: gradientColors),
                    startPoint: geometry.point(radius: trackRadius, angleDegrees: startDeg),
                    endPoint: geometry.point(radius: trackRadius, angleDegrees: endDeg)
                ),
                style: StrokeStyle(lineWidth: 6, lineCap: .round)
            )

            // Tip indicator
            let tipPoint = geometry.point(radius: trackRadius, angleDegrees: endDeg)
            let tipCircle = Path(ellipseIn: CGRect(x: tipPoint.x - 5, y: tipPoint.y - 5, width: 10, height: 10))
            context.fill(tipCircle, with: .color(Color.white))
        }
    }
}

// MARK: - Shapes

private struct QuarterCircleBackdrop: Shape {
    let corner: CornerPosition

    func path(in rect: CGRect) -> Path {
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
