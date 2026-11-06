import SwiftUI

public struct CornerDialView: View {
    @ObservedObject var appState: AppState
    public let corner: CornerPosition
    public var onExpansionChange: ((Bool) -> Void)?

    @State private var isHovered: Bool = false
    @State private var isDragging: Bool = false
    @State private var dragValue: Double = 0.5
    @State private var hoverTask: DispatchWorkItem?

    private let dialSize: CGFloat = 145

    public init(appState: AppState, corner: CornerPosition, onExpansionChange: ((Bool) -> Void)? = nil) {
        self.appState = appState
        self.corner = corner
        self.onExpansionChange = onExpansionChange
    }

    private var action: ControlAction {
        appState.action(for: corner)
    }

    private var currentValue: Double {
        if isDragging {
            return dragValue
        }
        if action == .timer {
            return appState.timer.progress
        }
        return Double(appState.getValue(for: action))
    }

    public var body: some View {
        let isVisible = appState.isEnabled && appState.isCornerDialsEnabled && action != .none

        ZStack {
            if isVisible {
                let geom = RadialDialGeometry(
                    corner: corner,
                    size: CGSize(width: dialSize, height: dialSize),
                    outerRadius: 130,
                    innerRadius: 55
                )

                let isExpanded = isHovered || isDragging || appState.activeCorner == corner

                ZStack {
                    // Quarter-circle backdrop disc
                    QuarterCircleBackdrop(corner: corner)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            QuarterCircleBorder(corner: corner)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.4),
                                            Color.white.opacity(0.1),
                                            Color.clear
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: Color.black.opacity(0.35), radius: 18, x: 0, y: 6)

                    // Track & Radial Ticks
                    DialTicksView(
                        geometry: geom,
                        value: currentValue,
                        accentColor: action.accentColors.first ?? .blue
                    )

                    // Active Value Arc
                    ActiveArcView(
                        geometry: geom,
                        value: currentValue,
                        gradientColors: action.accentColors
                    )

                    // Center Knob & Status Info
                    CenterKnobView(
                        geometry: geom,
                        corner: corner,
                        action: action,
                        value: currentValue,
                        appState: appState,
                        isExpanded: isExpanded,
                        onTap: {
                            appState.toggleAction(action)
                        }
                    )
                }
                .frame(width: dialSize, height: dialSize)
                .scaleEffect(isExpanded ? 1.0 : 0.35, anchor: unitPointAnchor(for: corner))
                .opacity(isExpanded ? 1.0 : 0.35)
                .animation(.spring(response: 0.32, dampingFraction: 0.72), value: isExpanded)
                .contentShape(QuarterCircleHitShape(corner: corner))
                .gesture(
                    DragGesture(minimumDistance: 1)
                        .onChanged { gesture in
                            if !isDragging {
                                isDragging = true
                                appState.activeCorner = corner
                                onExpansionChange?(true)
                            }
                            let newVal = geom.value(for: gesture.location)
                            dragValue = newVal
                            appState.setValue(for: action, value: Float(newVal))
                        }
                        .onEnded { _ in
                            isDragging = false
                            if !isHovered {
                                appState.activeCorner = nil
                                onExpansionChange?(false)
                            }
                        }
                )
                .onHover { hovering in
                    hoverTask?.cancel()
                    if hovering {
                        // Apply dwell delay to prevent accidental activation
                        let task = DispatchWorkItem {
                            isHovered = true
                            appState.activeCorner = corner
                            onExpansionChange?(true)
                        }
                        hoverTask = task
                        DispatchQueue.main.asyncAfter(deadline: .now() + appState.cornerDwellDelay, execute: task)
                    } else {
                        hoverTask?.cancel()
                        if !isDragging {
                            isHovered = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                if !self.isHovered && !self.isDragging && self.appState.activeCorner == self.corner {
                                    self.appState.activeCorner = nil
                                    self.onExpansionChange?(false)
                                }
                            }
                        }
                    }
                }
                .popover(isPresented: $appState.isAudioDevicePickerPresented, arrowEdge: .top) {
                    if action == .volume {
                        AudioDevicePickerPopover(appState: appState)
                    }
                }
            }
        }
        .frame(width: dialSize, height: dialSize)
    }

    private func unitPointAnchor(for corner: CornerPosition) -> UnitPoint {
        switch corner {
        case .topLeft: return .topLeading
        case .topRight: return .topTrailing
        case .bottomLeft: return .bottomLeading
        case .bottomRight: return .bottomTrailing
        }
    }
}

// MARK: - Center Knob View

private struct CenterKnobView: View {
    let geometry: RadialDialGeometry
    let corner: CornerPosition
    let action: ControlAction
    let value: Double
    @ObservedObject var appState: AppState
    let isExpanded: Bool
    let onTap: () -> Void

    var body: some View {
        let centerPoint = geometry.center
        let offset = knobOffset(for: corner)
        let knobSize: CGFloat = 62

        Button(action: onTap) {
            ZStack {
                Circle()
                    .fill(Color(nsColor: .windowBackgroundColor).opacity(0.88))
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.25), radius: 6, x: 0, y: 3)

                VStack(spacing: 2) {
                    Image(systemName: centerIcon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: action.accentColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text(centerText)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)

                    Text(action.shortTitle)
                        .font(.system(size: 7, weight: .semibold))
                        .foregroundColor(.secondary)
                        .tracking(0.5)
                }
            }
            .frame(width: knobSize, height: knobSize)
        }
        .buttonStyle(.plain)
        .position(x: centerPoint.x + offset.x, y: centerPoint.y + offset.y)
    }

    private var centerIcon: String {
        if action == .timer {
            return appState.timer.isRunning ? "pause.fill" : "play.fill"
        }
        return action.systemImage
    }

    private var centerText: String {
        if action == .timer {
            return appState.timer.formattedTime
        }
        return "\(Int(value * 100))%"
    }

    private func knobOffset(for corner: CornerPosition) -> CGPoint {
        let dist: CGFloat = 45
        let rad45 = 45.0 * .pi / 180.0
        let d = dist * cos(CGFloat(rad45))
        switch corner {
        case .topLeft: return CGPoint(x: d, y: d)
        case .topRight: return CGPoint(x: -d, y: d)
        case .bottomLeft: return CGPoint(x: d, y: -d)
        case .bottomRight: return CGPoint(x: -d, y: -d)
        }
    }
}

// MARK: - Audio Device Picker Popover

private struct AudioDevicePickerPopover: View {
    @ObservedObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Audio Output Devices")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 10)
                .padding(.top, 8)

            Divider()

            ForEach(appState.audio.outputDevices) { device in
                Button(action: {
                    appState.audio.selectOutputDevice(id: device.id)
                    appState.isAudioDevicePickerPresented = false
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: iconForDevice(device.name))
                            .foregroundColor(device.isDefault ? .accentColor : .secondary)
                            .frame(width: 16)

                        Text(device.name)
                            .font(.system(size: 12, weight: device.isDefault ? .bold : .regular))
                            .foregroundColor(.primary)

                        Spacer()

                        if device.isDefault {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.accentColor)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(device.isDefault ? Color.accentColor.opacity(0.12) : Color.clear)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .frame(width: 240)
    }

    private func iconForDevice(_ name: String) -> String {
        let lower = name.lowercased()
        if lower.contains("airpod") || lower.contains("buds") || lower.contains("headphone") {
            return "headphones"
        } else if lower.contains("display") || lower.contains("hdmi") {
            return "tv"
        }
        return "speaker.wave.2"
    }
}

// MARK: - Active Arc View

private struct ActiveArcView: View {
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
                clockwise: geometry.corner == .topRight || geometry.corner == .topLeft
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

            // Tip indicator glow
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
        let c = cornerCenter(in: rect, corner: corner)
        let r = max(rect.width, rect.height)

        path.move(to: c)
        let (start, end, clockwise) = angles(for: corner)
        path.addArc(center: c, radius: r, startAngle: start, endAngle: end, clockwise: clockwise)
        path.closeSubpath()
        return path
    }
}

private struct QuarterCircleBorder: Shape {
    let corner: CornerPosition

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let c = cornerCenter(in: rect, corner: corner)
        let r = max(rect.width, rect.height)
        let (start, end, clockwise) = angles(for: corner)
        path.addArc(center: c, radius: r, startAngle: start, endAngle: end, clockwise: clockwise)
        return path
    }
}

private struct QuarterCircleHitShape: Shape {
    let corner: CornerPosition

    func path(in rect: CGRect) -> Path {
        QuarterCircleBackdrop(corner: corner).path(in: rect)
    }
}

private func cornerCenter(in rect: CGRect, corner: CornerPosition) -> CGPoint {
    switch corner {
    case .topLeft: return CGPoint(x: rect.minX, y: rect.minY)
    case .topRight: return CGPoint(x: rect.maxX, y: rect.minY)
    case .bottomLeft: return CGPoint(x: rect.minX, y: rect.maxY)
    case .bottomRight: return CGPoint(x: rect.maxX, y: rect.maxY)
    }
}

private func angles(for corner: CornerPosition) -> (Angle, Angle, Bool) {
    switch corner {
    case .bottomRight:
        return (.degrees(180), .degrees(270), false)
    case .bottomLeft:
        return (.degrees(270), .degrees(360), false)
    case .topRight:
        return (.degrees(90), .degrees(180), false)
    case .topLeft:
        return (.degrees(0), .degrees(90), false)
    }
}
