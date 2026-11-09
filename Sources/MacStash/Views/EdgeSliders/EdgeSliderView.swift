import SwiftUI
import MacStashCore

/// EdgeBar vertical slider view that slides out from the physical screen edge.
/// When configured for Volume action, seamlessly hosts the vertical Now Playing
/// media controller directly below the slider with artwork, dancing visualizer,
/// and vertical playback controls, styled with Apple Liquid Glass aesthetics.
public struct EdgeSliderView: View {
    @ObservedObject var appState: AppState
    public let displayID: CGDirectDisplayID
    public let edge: EdgePosition

    @State private var isDragging: Bool = false
    @State private var dragValue: Float = 0.5

    private let sliderWidth: CGFloat = 50

    public init(appState: AppState, displayID: CGDirectDisplayID = 0, edge: EdgePosition = .right) {
        self.appState = appState
        self.displayID = displayID
        self.edge = edge
    }

    private var action: ControlAction {
        appState.activeProfile.rightEdgeAction
    }

    private var shouldShowMediaControls: Bool {
        action == .volume && appState.settings.edgeBarShowMediaControls
    }

    private var containerHeight: CGFloat {
        shouldShowMediaControls ? 418 : 250
    }

    private var currentValue: Float {
        if isDragging {
            return dragValue
        }
        if action == .volume && appState.audio.isMuted {
            return 0.0
        }
        if let live = appState.liveEdgeSliderValue {
            return live
        }
        return Float(appState.getValue(for: action, displayID: displayID))
    }

    public var body: some View {
        let isVisible = appState.isEnabled && appState.isEdgeSlidersEnabled && action != .none
        let isExpanded = isDragging || (appState.isRightSliderActive && (appState.activeDisplayID == displayID || appState.activeDisplayID == 0))

        ZStack(alignment: edge == .right ? .trailing : .leading) {
            if isVisible {
                // Smoothly slides into view when activated and glides off-screen when dismissed
                sliderContent(isExpanded: isExpanded)
                    .offset(x: isExpanded ? -8 : (edge == .right ? 85 : -85))
                    .opacity(isExpanded ? 1.0 : 0.0)
                    .animation(.spring(response: 0.28, dampingFraction: 0.82), value: isExpanded)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: edge == .right ? .trailing : .leading)
        .onHover { hovering in
            if !hovering && !isDragging && appState.isRightSliderActive {
                ScreenManager.shared.scheduleRightEdgeHideTimer()
            }
        }
    }

    @ViewBuilder
    private func sliderContent(isExpanded: Bool) -> some View {
        VStack(spacing: 0) {
            // 1. Primary Slider Section (Volume / Brightness / Keyboard / Timer)
            VStack(spacing: 10) {
                // Action Icon (Tap to toggle mute / silent for volume)
                Button(action: {
                    if action == .volume {
                        appState.audio.toggleMute()
                        HapticManager.shared.performDetentTick()
                        SoundEffectManager.shared.playAccent()
                    }
                }) {
                    Image(systemName: (action == .volume && appState.audio.isMuted) ? "speaker.slash.fill" : action.systemImage)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(
                            (action == .volume && appState.audio.isMuted)
                                ? AnyShapeStyle(Color.red)
                                : AnyShapeStyle(LinearGradient(colors: action.accentColors, startPoint: .top, endPoint: .bottom))
                        )
                        .frame(width: 32, height: 32)
                        .circularLiquidGlass(
                            tint: (action == .volume && appState.audio.isMuted) ? .red : (action.accentColors.first ?? .clear),
                            specularIntensity: 0.8,
                            causticOpacity: 0.15
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help((action == .volume && appState.audio.isMuted) ? appState.localized("menubar.unmute") : appState.localized("menubar.mute"))
                .padding(.top, 8)

                // Precision Crystal Tube Liquid Track
                GeometryReader { geo in
                    let trackH = max(1, geo.size.height)

                    ZStack {
                        // High-fidelity liquid track
                        LiquidVerticalTrack(
                            progress: Double(currentValue),
                            primaryTint: action.accentColors.first ?? .cyan,
                            secondaryTint: action.accentColors.last ?? .blue,
                            trackWidth: 15,
                            isMuted: action == .volume && appState.audio.isMuted
                        )

                        // Full-width hit zone so gesture never slips off
                        Color.clear
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { gesture in
                                isDragging = true
                                let progress = 1.0 - (gesture.location.y / trackH)
                                let clamped = max(0.0, min(1.0, Float(progress)))
                                dragValue = clamped
                                appState.liveEdgeSliderValue = clamped
                                appState.setValue(for: action, value: Double(clamped), displayID: displayID)
                            }
                            .onEnded { _ in
                                isDragging = false
                                appState.liveEdgeSliderValue = nil
                                appState.saveSettings()
                            }
                    )
                }
                .frame(width: 44, height: shouldShowMediaControls ? 110 : 140)
                .padding(.horizontal, 3)

                // Percentage / MUTE label with monospaced tabular figures
                if action == .volume && appState.audio.isMuted {
                    Text("MUTE")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.red)
                        .padding(.bottom, shouldShowMediaControls ? 6 : 12)
                } else {
                    Text("\(Int(currentValue * 100))%")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.primary)
                        .padding(.bottom, shouldShowMediaControls ? 6 : 12)
                }
            }

            // 2. Vertical Media Controller (Shown directly beneath the volume slider)
            if shouldShowMediaControls {
                // Subtle glass divider
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.2), Color.white.opacity(0.02)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 32, height: 1)
                    .padding(.vertical, 4)

                EdgeMediaControlView(appState: appState)
                    .padding(.bottom, 8)
            }
        }
        .frame(width: sliderWidth, height: containerHeight)
        .liquidGlass(
            cornerRadius: 18,
            tint: action.accentColors.first ?? .clear,
            specularIntensity: 1.1,
            causticOpacity: 0.18,
            shadowRadius: 16
        )
    }
}
