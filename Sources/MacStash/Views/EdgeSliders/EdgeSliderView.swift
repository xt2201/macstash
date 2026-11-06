import SwiftUI
import MacStashCore

/// EdgeBar vertical slider view that slides out from the physical screen edge.
/// When configured for Volume action, seamlessly hosts the vertical Now Playing
/// media controller directly below the slider with artwork, dancing visualizer,
/// and vertical playback controls.
public struct EdgeSliderView: View {
    @ObservedObject var appState: AppState
    public let displayID: CGDirectDisplayID
    public let edge: EdgePosition

    @State private var isHovered: Bool = false
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
        return Float(appState.getValue(for: action, displayID: displayID))
    }

    public var body: some View {
        let isVisible = appState.isEnabled && appState.isEdgeSlidersEnabled && action != .none
        let isExpanded = isHovered || isDragging || appState.isRightSliderActive

        ZStack(alignment: edge == .right ? .trailing : .leading) {
            if isVisible {
                // Completely hidden when idle, smoothly slides into view on hover
                sliderContent(isExpanded: isExpanded)
                    .offset(x: isExpanded ? 0 : (edge == .right ? (sliderWidth + 24) : -(sliderWidth + 24)))
                    .opacity(isExpanded ? 1.0 : 0.0)
                    .animation(.spring(response: 0.32, dampingFraction: 0.78), value: isExpanded)

                // Invisible touch sensor strip along physical screen edge
                Color.clear
                    .frame(width: 14)
                    .contentShape(Rectangle())
            }
        }
        .frame(width: isExpanded ? 260 : (sliderWidth + 10), alignment: edge == .right ? .trailing : .leading)
        .onHover { hovering in
            isHovered = hovering
            appState.isRightSliderActive = hovering
        }
    }

    @ViewBuilder
    private func sliderContent(isExpanded: Bool) -> some View {
        VStack(spacing: 0) {
            // 1. Primary Slider Section (Volume / Brightness / Keyboard / Timer)
            VStack(spacing: 10) {
                // Action Icon
                Image(systemName: action.systemImage)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: action.accentColors,
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .padding(.top, 12)

                // Vertical Track Bar
                GeometryReader { geo in
                    let trackH = geo.size.height
                    let fillH = trackH * CGFloat(currentValue)

                    ZStack(alignment: .bottom) {
                        // Track background
                        Capsule()
                            .fill(Color.white.opacity(0.12))

                        // Fill level
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: action.accentColors,
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(height: max(6, fillH))

                        // Thumb indicator
                        Circle()
                            .fill(Color.white)
                            .frame(width: 14, height: 14)
                            .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 1)
                            .offset(y: -(fillH - 7))
                    }
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { gesture in
                                isDragging = true
                                let progress = 1.0 - (gesture.location.y / trackH)
                                let clamped = max(0.0, min(1.0, Float(progress)))
                                dragValue = clamped
                                appState.setValue(for: action, value: Double(clamped), displayID: displayID)
                            }
                            .onEnded { _ in
                                isDragging = false
                            }
                    )
                }
                .frame(width: 14, height: shouldShowMediaControls ? 110 : 140)
                .padding(.horizontal, 16)

                // Percentage label
                Text("\(Int(currentValue * 100))%")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .padding(.bottom, shouldShowMediaControls ? 6 : 12)
            }

            // 2. Vertical Media Controller (Shown directly beneath the volume slider)
            if shouldShowMediaControls {
                // Subtle glass divider
                Rectangle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 32, height: 1)
                    .padding(.vertical, 4)

                EdgeMediaControlView(appState: appState)
                    .padding(.bottom, 8)
            }
        }
        .frame(width: sliderWidth, height: containerHeight)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.32), radius: 14, x: edge == .right ? -4 : 4, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.3), Color.white.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
}
