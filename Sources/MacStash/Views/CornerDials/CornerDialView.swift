import SwiftUI
import AppKit
import MacStashCore
import MacStashDesignSystem

public struct CornerDialView: View {
    @ObservedObject var appState: AppState
    public let corner: CornerPosition
    public let displayID: CGDirectDisplayID

    @State private var isDragging: Bool = false
    @State private var dragValue: Double = 0.5

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
            return DSColor.timerBreakGradient
        }
        return DSColor.actionGradient(for: action, isMuted: action == .volume && appState.audio.isMuted)
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
                let metrics = CornerDialMetrics(dialSize: dialSize)
                let geom = RadialDialGeometry(
                    corner: corner,
                    size: CGSize(width: dialSize, height: dialSize),
                    outerRadius: metrics.tickOuterRadius,
                    innerRadius: metrics.badgeOuterRadius
                )

                let isExpanded = isDragging || (appState.activeCorner == corner && appState.activeDisplayID == displayID)
                let hasVisibleSatellites = isExpanded && (
                    action == .timer
                    || action == .keepAwake
                    || action == .stashShelf
                    || action == .scratchpad
                    || action == .mediaPlayback
                    || (action == .volume && appState.nowPlaying.hasMedia)
                )
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

                    // 3. Precision Luminous Fluid Arc with concentric orbital framing & meniscus knob
                    DialArcShape(
                        geometry: geom,
                        value: currentValue,
                        gradientColors: actionColors,
                        showOrbitalTrack: hasVisibleSatellites
                    )

                    // 4. Floating Glass Jewel Center Action Hub
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
                            gradientColors: actionColors,
                            mediaTimeText: (action == .mediaPlayback && appState.nowPlaying.hasMedia)
                                || (action == .volume && appState.nowPlaying.hasMedia && appState.nowPlaying.isPlaying && !isDragging)
                                ? appState.nowPlaying.formattedElapsedTime
                                : nil
                        )
                    }
                    .buttonStyle(.plain)

                    // 5. Satellite micro-controls
                    if isExpanded {
                        DialSatelliteCluster(
                            appState: appState,
                            action: action,
                            geometry: geom,
                            satelliteRadius: metrics.satelliteRadius,
                            satSize: metrics.satelliteDiameter,
                            displayID: displayID
                        )
                    }
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

                            // Ignore touches on center hub or outside dial perimeter
                            let centerDeadRadius = metrics.badgeOuterRadius
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
                            } else if action == .mediaPlayback {
                                dragValue = norm
                                appState.nowPlaying.previewInteractiveScrub(toFraction: norm)
                            } else {
                                dragValue = norm
                                appState.setValue(for: action, value: norm, displayID: displayID)
                            }
                        }
                        .onEnded { _ in
                            if isDragging {
                                isDragging = false
                                if action == .mediaPlayback {
                                    appState.nowPlaying.previewInteractiveScrub(toFraction: dragValue)
                                    appState.nowPlaying.commitInteractiveScrub()
                                } else {
                                    appState.setValue(for: action, value: dragValue, displayID: displayID)
                                }
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
