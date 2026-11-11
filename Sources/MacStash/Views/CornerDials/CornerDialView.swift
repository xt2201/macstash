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
    @State private var isRewindHovered: Bool = false
    @State private var isPlayPauseHovered: Bool = false
    @State private var isForwardHovered: Bool = false
    @State private var isActionSat1Hovered: Bool = false
    @State private var isActionSat2Hovered: Bool = false

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
                    innerRadius: max(42, dialSize * 0.38)
                )

                let isExpanded = isDragging || (appState.activeCorner == corner && appState.activeDisplayID == displayID)
                let satelliteRadius = max(72, (dialSize - 35) * 0.87)
                let shouldReduceMotion = appState.settings.respectReduceMotion && NSWorkspace.shared.accessibilityDisplayShouldReduceMotion

                ZStack {
                    // 1. Sculpted Liquid Glass Quarter-Circle Backdrop Disc
                    QuarterCircleGlassBackdrop(
                        corner: corner,
                        dialSize: dialSize,
                        tint: actionColors.first ?? .clear
                    )
                    .opacity(appState.settings.dialOpacity)

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

                    // 4. Satellite micro-controls (Floating liquid mercury droplets)
                    if isExpanded {
                        if action == .timer {
                            let resetPt = geom.point(radius: satelliteRadius, angleDegrees: geom.angle(for: 0.14))
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

                            let skipPt = geom.point(radius: satelliteRadius, angleDegrees: geom.angle(for: 0.86))
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
                        } else if action == .volume && appState.nowPlaying.hasMedia {
                            // Audio Scrubbing: Skip Backward 10s (0.14)
                            let rwdPt = geom.point(radius: satelliteRadius, angleDegrees: geom.angle(for: 0.14))
                            Button(action: {
                                appState.nowPlaying.skipBackward(seconds: 10)
                            }) {
                                Image(systemName: "gobackward.10")
                                    .font(.system(size: 9.5, weight: .bold))
                                    .foregroundColor(appState.nowPlaying.artworkTint)
                                    .frame(width: 24, height: 24)
                                    .circularLiquidGlass(
                                        tint: appState.nowPlaying.artworkTint,
                                        specularIntensity: 1.0,
                                        causticOpacity: 0.25,
                                        isHighlighted: isRewindHovered
                                    )
                                    .scaleEffect(isRewindHovered ? 1.15 : 1.0)
                                    .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isRewindHovered)
                            }
                            .buttonStyle(.plain)
                            .help(appState.localized("corners.media.seekBackward"))
                            .onHover { isRewindHovered = $0 }
                            .position(x: rwdPt.x, y: rwdPt.y)

                            // Audio Play/Pause (0.50)
                            let ppPt = geom.point(radius: satelliteRadius, angleDegrees: geom.angle(for: 0.50))
                            Button(action: {
                                appState.nowPlaying.togglePlayPause()
                            }) {
                                Image(systemName: appState.nowPlaying.isPlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.primary)
                                    .frame(width: 24, height: 24)
                                    .circularLiquidGlass(
                                        tint: appState.nowPlaying.isPlaying ? appState.nowPlaying.artworkTint : .clear,
                                        specularIntensity: 1.0,
                                        causticOpacity: 0.25,
                                        isHighlighted: isPlayPauseHovered
                                    )
                                    .scaleEffect(isPlayPauseHovered ? 1.15 : 1.0)
                                    .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPlayPauseHovered)
                            }
                            .buttonStyle(.plain)
                            .help(appState.nowPlaying.isPlaying ? appState.localized("corners.media.pause") : appState.localized("corners.media.play"))
                            .onHover { isPlayPauseHovered = $0 }
                            .position(x: ppPt.x, y: ppPt.y)

                            // Audio Scrubbing: Skip Forward 10s (0.86)
                            let fwdPt = geom.point(radius: satelliteRadius, angleDegrees: geom.angle(for: 0.86))
                            Button(action: {
                                appState.nowPlaying.skipForward(seconds: 10)
                            }) {
                                Image(systemName: "goforward.10")
                                    .font(.system(size: 9.5, weight: .bold))
                                    .foregroundColor(appState.nowPlaying.artworkTint)
                                    .frame(width: 24, height: 24)
                                    .circularLiquidGlass(
                                        tint: appState.nowPlaying.artworkTint,
                                        specularIntensity: 1.0,
                                        causticOpacity: 0.25,
                                        isHighlighted: isForwardHovered
                                    )
                                    .scaleEffect(isForwardHovered ? 1.15 : 1.0)
                                    .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isForwardHovered)
                            }
                            .buttonStyle(.plain)
                            .help(appState.localized("corners.media.seekForward"))
                            .onHover { isForwardHovered = $0 }
                            .position(x: fwdPt.x, y: fwdPt.y)
                        } else if action == .keepAwake {
                            // Indefinite Keep Awake (0.14)
                            let infPt = geom.point(radius: satelliteRadius, angleDegrees: geom.angle(for: 0.14))
                            Button(action: {
                                appState.keepAwake.activate(minutes: -1)
                            }) {
                                Image(systemName: "infinity")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.orange)
                                    .frame(width: 24, height: 24)
                                    .circularLiquidGlass(
                                        tint: .orange,
                                        specularIntensity: 1.0,
                                        causticOpacity: 0.25,
                                        isHighlighted: isActionSat1Hovered
                                    )
                                    .scaleEffect(isActionSat1Hovered ? 1.15 : 1.0)
                                    .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isActionSat1Hovered)
                            }
                            .buttonStyle(.plain)
                            .help("Indefinite Keep Awake")
                            .onHover { isActionSat1Hovered = $0 }
                            .position(x: infPt.x, y: infPt.y)

                            // Deactivate Keep Awake (0.86)
                            let offPt = geom.point(radius: satelliteRadius, angleDegrees: geom.angle(for: 0.86))
                            Button(action: {
                                appState.keepAwake.deactivate()
                            }) {
                                Image(systemName: "power")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.secondary)
                                    .frame(width: 24, height: 24)
                                    .circularLiquidGlass(
                                        tint: .clear,
                                        specularIntensity: 0.8,
                                        causticOpacity: 0.15,
                                        isHighlighted: isActionSat2Hovered
                                    )
                                    .scaleEffect(isActionSat2Hovered ? 1.15 : 1.0)
                                    .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isActionSat2Hovered)
                            }
                            .buttonStyle(.plain)
                            .help("Turn Off Keep Awake")
                            .onHover { isActionSat2Hovered = $0 }
                            .position(x: offPt.x, y: offPt.y)
                        } else if action == .stashShelf {
                            // Open Shelf Drawer (0.14)
                            let shelfPt = geom.point(radius: satelliteRadius, angleDegrees: geom.angle(for: 0.14))
                            Button(action: {
                                appState.toggleAction(.stashShelf, displayID: displayID)
                            }) {
                                Image(systemName: "tray.full.fill")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.cyan)
                                    .frame(width: 24, height: 24)
                                    .circularLiquidGlass(
                                        tint: .cyan,
                                        specularIntensity: 1.0,
                                        causticOpacity: 0.25,
                                        isHighlighted: isActionSat1Hovered
                                    )
                                    .scaleEffect(isActionSat1Hovered ? 1.15 : 1.0)
                                    .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isActionSat1Hovered)
                            }
                            .buttonStyle(.plain)
                            .help(appState.localized("corners.action.openShelf"))
                            .onHover { isActionSat1Hovered = $0 }
                            .position(x: shelfPt.x, y: shelfPt.y)

                            // Clear Stash Shelf (0.86)
                            let clearPt = geom.point(radius: satelliteRadius, angleDegrees: geom.angle(for: 0.86))
                            Button(action: {
                                appState.stashShelf.clearAll()
                            }) {
                                Image(systemName: "trash")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.secondary)
                                    .frame(width: 24, height: 24)
                                    .circularLiquidGlass(
                                        tint: .clear,
                                        specularIntensity: 0.8,
                                        causticOpacity: 0.15,
                                        isHighlighted: isActionSat2Hovered
                                    )
                                    .scaleEffect(isActionSat2Hovered ? 1.15 : 1.0)
                                    .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isActionSat2Hovered)
                            }
                            .buttonStyle(.plain)
                            .help(appState.localized("general.clearAll"))
                            .onHover { isActionSat2Hovered = $0 }
                            .position(x: clearPt.x, y: clearPt.y)
                        } else if action == .scratchpad {
                            // Open Scratchpad Drawer (0.14)
                            let padPt = geom.point(radius: satelliteRadius, angleDegrees: geom.angle(for: 0.14))
                            Button(action: {
                                appState.toggleAction(.scratchpad, displayID: displayID)
                            }) {
                                Image(systemName: "note.text.badge.plus")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.green)
                                    .frame(width: 24, height: 24)
                                    .circularLiquidGlass(
                                        tint: .green,
                                        specularIntensity: 1.0,
                                        causticOpacity: 0.25,
                                        isHighlighted: isActionSat1Hovered
                                    )
                                    .scaleEffect(isActionSat1Hovered ? 1.15 : 1.0)
                                    .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isActionSat1Hovered)
                            }
                            .buttonStyle(.plain)
                            .help(appState.localized("corners.action.openScratchpad"))
                            .onHover { isActionSat1Hovered = $0 }
                            .position(x: padPt.x, y: padPt.y)

                            // Copy Notes (0.86)
                            let copyPt = geom.point(radius: satelliteRadius, angleDegrees: geom.angle(for: 0.86))
                            Button(action: {
                                appState.scratchpad.copyAll()
                            }) {
                                Image(systemName: "doc.on.doc")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.secondary)
                                    .frame(width: 24, height: 24)
                                    .circularLiquidGlass(
                                        tint: .clear,
                                        specularIntensity: 0.8,
                                        causticOpacity: 0.15,
                                        isHighlighted: isActionSat2Hovered
                                    )
                                    .scaleEffect(isActionSat2Hovered ? 1.15 : 1.0)
                                    .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isActionSat2Hovered)
                            }
                            .buttonStyle(.plain)
                            .help(appState.localized("scratchpad.copyAll"))
                            .onHover { isActionSat2Hovered = $0 }
                            .position(x: copyPt.x, y: copyPt.y)
                        }
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
                            tint: actionColors.first ?? .clear,
                            mediaTimeText: appState.nowPlaying.hasMedia ? appState.nowPlaying.formattedElapsedTime : nil
                        )
                    }
                    .buttonStyle(.plain)
                }
                .frame(width: dialSize, height: dialSize)
                .scaleEffect(isExpanded ? 1.0 : 0.05, anchor: unitPoint(for: corner))
                .opacity(isExpanded ? 1.0 : 0.0)
                .animation(
                    shouldReduceMotion
                        ? .easeInOut(duration: 0.1)
                        : .spring(response: 0.30 * appState.settings.animationSpeedMultiplier, dampingFraction: 0.76),
                    value: isExpanded
                )
                .macStashTheme(appState.resolvedColorScheme)
                .gesture(
                    DragGesture(minimumDistance: 4)
                        .onChanged { gesture in
                            let center = geom.center
                            let loc = gesture.location
                            let dist = hypot(loc.x - center.x, loc.y - center.y)

                            // Ignore touches on center badge or outside dial perimeter
                            let centerDeadRadius = max(44, dialSize * 0.38)
                            guard dist >= centerDeadRadius && dist <= dialSize + 30 else {
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
                            } else if action == .keepAwake {
                                let snapped: Double
                                switch norm {
                                case ..<0.1: snapped = 0.0
                                case ..<0.3: snapped = 0.2
                                case ..<0.5: snapped = 0.4
                                case ..<0.7: snapped = 0.6
                                case ..<0.9: snapped = 0.8
                                default: snapped = 1.0
                                }
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
        .onDrop(of: ["public.file-url"], isTargeted: nil) { providers in
            guard action == .stashShelf else { return false }
            final class Collector: @unchecked Sendable {
                let lock = NSLock()
                var urls: [URL] = []
                func add(_ u: URL) {
                    lock.lock()
                    urls.append(u)
                    lock.unlock()
                }
            }
            let collector = Collector()
            let group = DispatchGroup()
            for provider in providers {
                group.enter()
                _ = provider.loadObject(ofClass: URL.self) { url, _ in
                    if let u = url { collector.add(u) }
                    group.leave()
                }
            }
            group.notify(queue: .main) {
                let result = collector.urls
                if !result.isEmpty {
                    appState.stashShelf.addFileURLs(result)
                    appState.haptics.performBoundaryClick(intensity: appState.effectiveHapticIntensity)
                    appState.sound.playAccent(enabled: appState.isSoundEnabled)
                }
            }
            return true
        }
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
    @Environment(\.colorScheme) private var colorScheme
    public let corner: CornerPosition
    public let dialSize: CGFloat
    public let tint: Color

    public init(corner: CornerPosition, dialSize: CGFloat, tint: Color) {
        self.corner = corner
        self.dialSize = dialSize
        self.tint = tint
    }

    public var body: some View {
        let isDark = colorScheme == .dark
        ZStack {
            // Layer 1: Frosted refractive glass substrate
            QuarterCircleBackdrop(corner: corner)
                .fill(.ultraThinMaterial)

            QuarterCircleBackdrop(corner: corner)
                .fill(isDark ? Color.black.opacity(0.16) : Color.white.opacity(0.28))

            // Layer 2: Caustic ambient reflection originating from screen vertex
            QuarterCircleBackdrop(corner: corner)
                .fill(
                    RadialGradient(
                        colors: [
                            tint.opacity(0.22),
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
                            .init(color: Color.white.opacity(isDark ? 0.12 : 0.35), location: 0.0),
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
                            .init(color: Color.white.opacity(isDark ? 0.55 : 0.85), location: 0.0),
                            .init(color: Color.primary.opacity(0.14), location: 0.45),
                            .init(color: Color.primary.opacity(0.05), location: 0.8),
                            .init(color: tint.opacity(0.32), location: 1.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.2
                )
        }
        .frame(width: dialSize, height: dialSize)
        .shadow(color: Color.black.opacity(isDark ? 0.32 : 0.16), radius: 14, x: 0, y: 5)
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
    public let mediaTimeText: String?

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
        self.mediaTimeText = mediaTimeText
    }

    public var body: some View {
        let offset = badgeOffset(for: corner, in: dialSize)
        let badgeSide = max(54.0, min(72.0, dialSize * (64.0 / 145.0)))
        let isDark = colorScheme == .dark

        VStack(spacing: 2) {
            actionIconView

            actionReadoutView
        }
        .frame(width: badgeSide, height: badgeSide)
        .background(
            ZStack {
                Circle().fill(.ultraThinMaterial)
                Circle().fill(isDark ? Color.black.opacity(0.38) : Color.white.opacity(0.62))
                if tint != .clear {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [tint.opacity(isExpanded ? 0.32 : 0.18), Color.clear],
                                center: .center,
                                startRadius: 2,
                                endRadius: badgeSide * 0.5
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
                            .init(color: Color.white.opacity(isExpanded ? (isDark ? 0.85 : 0.95) : 0.65), location: 0.0),
                            .init(color: Color.primary.opacity(0.16), location: 0.5),
                            .init(color: (tint == .clear ? Color.primary : tint).opacity(0.40), location: 1.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: isExpanded ? 1.4 : 1.15
                )
        )
        .shadow(color: Color.black.opacity(isDark ? 0.35 : 0.15), radius: 7, x: 0, y: 3)
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
        } else if action == .volume, let time = mediaTimeText, !time.isEmpty {
            Text(time)
                .font(.system(size: 9.5, weight: .heavy, design: .monospaced))
                .monospacedDigit()
                .foregroundColor(.primary)
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
        // Mathematically centered along the 45° line of symmetry (39pt at 145pt dial size => 19pt edge clearance)
        let offsetDist: CGFloat = size * (39.0 / 145.0)
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
    @Environment(\.colorScheme) private var colorScheme
    public let geometry: RadialDialGeometry
    public let value: Double
    public let gradientColors: [Color]

    public init(geometry: RadialDialGeometry, value: Double, gradientColors: [Color]) {
        self.geometry = geometry
        self.value = value
        self.gradientColors = gradientColors
    }

    public var body: some View {
        let isDark = colorScheme == .dark
        Canvas { context, _ in
            let trackRadius = geometry.outerRadius - 20
            let guideRadius = max(56, geometry.size.width * (106.0 / 145.0))
            let startDeg = geometry.angle(for: 0.0)
            let fullDeg = geometry.angle(for: 1.0)
            let isClockwise = geometry.corner == .bottomLeft || geometry.corner == .topLeft

            // 0. Inner concentric guide arc (framing the central hub into the dial)
            var guidePath = Path()
            guidePath.addArc(
                center: geometry.center,
                radius: guideRadius,
                startAngle: .degrees(startDeg),
                endAngle: .degrees(fullDeg),
                clockwise: isClockwise
            )
            context.stroke(
                guidePath,
                with: .color(isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.08)),
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
                with: .color(isDark ? Color.white.opacity(0.10) : Color.black.opacity(0.10)),
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
