import SwiftUI
import MacStashCore

/// EdgeBar vertical slider view that slides out from the physical screen edge.
/// Dynamically supports both Left and Right screen edges independently (Dual Edge Bars),
/// integrates the Dynamic Island horizontal media expansion capsule, and supports dedicated
/// media playback scrubbing.
public struct EdgeSliderView: View {
    @ObservedObject var appState: AppState
    public let edge: EdgePosition
    public let displayID: CGDirectDisplayID

    @State private var isDragging: Bool = false
    @State private var dragValue: Float = 0.5
    @State private var isTopHovered: Bool = false

    private let sliderWidth: CGFloat = 56

    public init(appState: AppState, edge: EdgePosition = .right, displayID: CGDirectDisplayID = 0) {
        self.appState = appState
        self.edge = edge
        self.displayID = displayID
    }

    private var action: ControlAction {
        edge == .left ? appState.activeProfile.leftEdgeAction : appState.activeProfile.rightEdgeAction
    }

    private var shouldShowMediaIsland: Bool {
        (action == .volume && appState.settings.edgeBarShowMediaControls) || action == .mediaPlayback
    }

    private var containerHeight: CGFloat {
        shouldShowMediaIsland ? 304 : 254
    }

    private var currentValue: Float {
        if isDragging {
            return dragValue
        }
        if action == .volume && appState.audio.isMuted {
            return 0.0
        }
        if let live = (edge == .left ? appState.liveLeftSliderValue : appState.liveRightSliderValue) {
            return live
        }
        return Float(appState.getValue(for: action, displayID: displayID))
    }

    private var isExpanded: Bool {
        let active = edge == .left ? appState.isLeftSliderActive : appState.isRightSliderActive
        return isDragging || (active && (appState.activeDisplayID == displayID || appState.activeDisplayID == 0))
    }

    public var body: some View {
        let isPlacementActive = appState.settings.edgeSliderPlacement == .both
            || (edge == .left && appState.settings.edgeSliderPlacement == .left)
            || (edge == .right && appState.settings.edgeSliderPlacement == .right)
        let isVisible = appState.isEnabled && appState.isEdgeSlidersEnabled && isPlacementActive && action != .none
        let shouldReduceMotion = appState.settings.respectReduceMotion && NSWorkspace.shared.accessibilityDisplayShouldReduceMotion

        ZStack(alignment: edge == .right ? .trailing : .leading) {
            if isVisible {
                sliderContent(isExpanded: isExpanded)
                    .offset(x: isExpanded ? (edge == .right ? -8 : 8) : (edge == .right ? 88 : -88))
                    .opacity(isExpanded ? 1.0 : 0.0)
                    .animation(
                        shouldReduceMotion
                            ? .easeInOut(duration: 0.12)
                            : .spring(response: 0.28 * appState.settings.animationSpeedMultiplier, dampingFraction: 0.82),
                        value: isExpanded
                    )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: edge == .right ? .trailing : .leading)
        .onHover { hovering in
            if !hovering && !isDragging && isExpanded {
                ScreenManager.shared.scheduleEdgeHideTimer(edge: edge)
            }
        }
        .macStashTheme(appState.resolvedColorScheme)
    }

    @ViewBuilder
    private func sliderContent(isExpanded: Bool) -> some View {
        let isMuted = action == .volume && appState.audio.isMuted
        let accentTint = isMuted ? Color.red : (action.accentColors.first ?? .clear)

        VStack(spacing: 8) {
            // 1. Primary Slider Section (Glass Column)
            VStack(spacing: 8) {
                // Action Toggle Button
                Button(action: {
                    appState.toggleAction(action, displayID: displayID)
                }) {
                    Image(systemName: iconName(isMuted: isMuted))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(
                            isMuted
                                ? AnyShapeStyle(Color.red)
                                : AnyShapeStyle(LinearGradient(colors: action.accentColors, startPoint: .top, endPoint: .bottom))
                        )
                        .frame(width: 34, height: 34)
                        .circularLiquidGlass(
                            tint: accentTint,
                            specularIntensity: 0.9,
                            causticOpacity: 0.18,
                            isHighlighted: isTopHovered
                        )
                        .scaleEffect(isTopHovered ? 1.06 : 1.0)
                        .animation(.spring(response: 0.18, dampingFraction: 0.72), value: isTopHovered)
                }
                .buttonStyle(.plain)
                .onHover { isTopHovered = $0 }
                .help(topHelpText(isMuted: isMuted))
                .padding(.top, 8)

                if action == .scratchpad {
                    Button(action: {
                        appState.toggleAction(.scratchpad, displayID: displayID)
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "note.text")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(LinearGradient(colors: action.accentColors, startPoint: .top, endPoint: .bottom))
                            Text(appState.scratchpad.text.isEmpty ? appState.localized("dial.notes") : "\(appState.scratchpad.wordCount)w")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            Text(appState.localized("corners.action.openScratchpad"))
                                .font(.system(size: 8.5, weight: .medium))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                        .frame(width: 48, height: 144)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.primary.opacity(0.06))
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 4)

                    readoutLabel(isMuted: isMuted)
                        .padding(.bottom, 10)
                } else if action == .stashShelf {
                    Button(action: {
                        appState.toggleAction(.stashShelf, displayID: displayID)
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "tray.2.fill")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(LinearGradient(colors: action.accentColors, startPoint: .top, endPoint: .bottom))
                            Text("\(appState.stashShelf.items.count)")
                                .font(.system(size: 14, weight: .heavy, design: .rounded))
                                .foregroundColor(.primary)
                            Text(appState.localized("corners.action.openShelf"))
                                .font(.system(size: 8.5, weight: .medium))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                        .frame(width: 48, height: 144)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.primary.opacity(0.06))
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 4)

                    readoutLabel(isMuted: isMuted)
                        .padding(.bottom, 10)
                } else {
                    // Precision Crystal Tube Liquid Track
                    GeometryReader { geo in
                        let trackH = max(1, geo.size.height)

                        ZStack {
                            LiquidVerticalTrack(
                                progress: Double(currentValue),
                                primaryTint: action.accentColors.first ?? .cyan,
                                secondaryTint: action.accentColors.last ?? .blue,
                                trackWidth: 16,
                                isMuted: isMuted
                            )

                            Color.clear
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { gesture in
                                    isDragging = true
                                    let progress = 1.0 - (gesture.location.y / trackH)
                                    let clamped: Float
                                    if action == .keepAwake {
                                        switch progress {
                                        case ..<0.1: clamped = 0.0
                                        case ..<0.3: clamped = 0.2
                                        case ..<0.5: clamped = 0.4
                                        case ..<0.7: clamped = 0.6
                                        case ..<0.9: clamped = 0.8
                                        default: clamped = 1.0
                                        }
                                    } else {
                                        clamped = max(0.0, min(1.0, Float(progress)))
                                    }
                                    dragValue = clamped
                                    if edge == .left {
                                        appState.liveLeftSliderValue = clamped
                                    } else {
                                        appState.liveRightSliderValue = clamped
                                    }
                                    appState.setValue(for: action, value: Double(clamped), displayID: displayID)
                                }
                                .onEnded { _ in
                                    isDragging = false
                                    if edge == .left {
                                        appState.liveLeftSliderValue = nil
                                    } else {
                                        appState.liveRightSliderValue = nil
                                    }
                                    appState.saveSettings()
                                }
                        )
                    }
                    .frame(width: 48, height: 138)
                    .padding(.horizontal, 4)

                    readoutLabel(isMuted: isMuted)
                        .padding(.bottom, 10)
                }
            }
            .frame(width: sliderWidth)
            .liquidGlass(
                cornerRadius: 20,
                tint: action.accentColors.first ?? .clear,
                specularIntensity: 1.1,
                causticOpacity: 0.18,
                shadowRadius: 16,
                backdropOpacity: appState.settings.dialOpacity
            )

            // 2. Dynamic Island Expandable Audio Controller
            if shouldShowMediaIsland {
                EdgeMediaIslandView(appState: appState, edge: edge)
            }
        }
        .frame(width: isExpanded ? 280 : sliderWidth, alignment: edge == .right ? .trailing : .leading)
    }

    @ViewBuilder
    private func readoutLabel(isMuted: Bool) -> some View {
        if isMuted {
            Text(appState.localized("dial.mute"))
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(.red)
        } else if action == .timer {
            Text(appState.formattedTimerTime)
                .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                .monospacedDigit()
                .foregroundColor(.primary)
        } else if action == .keepAwake {
            Text(appState.keepAwake.formattedRemaining)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(appState.keepAwake.isActive ? .orange : .secondary)
        } else if action == .stashShelf {
            Text("\(appState.stashShelf.items.count)")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .monospacedDigit()
                .foregroundColor(.primary)
        } else if action == .scratchpad {
            Text(appState.localized("dial.notes"))
                .font(.system(size: 9.5, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
        } else if action == .mediaPlayback {
            Text(appState.nowPlaying.formattedElapsedTime)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .monospacedDigit()
                .foregroundColor(.primary)
        } else {
            Text("\(Int(round(currentValue * 100)))%")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .monospacedDigit()
                .foregroundColor(.primary)
        }
    }

    private func iconName(isMuted: Bool) -> String {
        if isMuted { return "speaker.slash.fill" }
        if action == .timer {
            return appState.isPomodoroRunning ? "pause.fill" : "play.fill"
        }
        if action == .mediaPlayback {
            return appState.nowPlaying.isPlaying ? "pause.fill" : "play.fill"
        }
        return action.systemImage
    }

    private func topHelpText(isMuted: Bool) -> String {
        if action == .volume {
            return isMuted ? appState.localized("menubar.unmute") : appState.localized("menubar.mute")
        }
        if action == .timer {
            return appState.isPomodoroRunning ? appState.localized("menubar.pause") : appState.localized("menubar.start")
        }
        if action == .mediaPlayback {
            return appState.nowPlaying.isPlaying ? appState.localized("corners.media.pause") : appState.localized("corners.media.play")
        }
        return "\(action.localizedDisplayName(using: appState.effectiveLanguage)) — \(appState.localized("edge.toggleAction"))"
    }
}
