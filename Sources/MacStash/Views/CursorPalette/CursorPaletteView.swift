import SwiftUI
import AppKit
import MacStashCore

/// Floating radial palette that blooms directly at the current mouse cursor location.
/// Supports both click-to-toggle and hover + two-finger scroll scrubbing across
/// Brightness, Volume, Keep Awake, and Pomodoro Timer.
public struct CursorPaletteView: View {
    @ObservedObject var appState: AppState
    @Environment(\.colorScheme) private var colorScheme

    @State private var hoveredSector: CursorSector? = nil
    @State private var isCloseHovered: Bool = false

    private let paletteRadius: CGFloat = 122.0

    public enum CursorSector: CaseIterable {
        case top        // Brightness
        case right      // Volume
        case bottom     // Keep Awake
        case left       // Timer

        var action: ControlAction {
            switch self {
            case .top: return .brightness
            case .right: return .volume
            case .bottom: return .keepAwake
            case .left: return .timer
            }
        }
    }

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        let shouldReduceMotion = appState.settings.respectReduceMotion && NSWorkspace.shared.accessibilityDisplayShouldReduceMotion

        ZStack {
            // Liquid Glass Backdrop Compass Disc
            Circle()
                .fill(.clear)
                .frame(width: paletteRadius * 2, height: paletteRadius * 2)
                .circularLiquidGlass(
                    tint: activeCausticTint,
                    specularIntensity: 1.2,
                    causticOpacity: 0.24,
                    isHighlighted: hoveredSector != nil
                )
                .animation(
                    shouldReduceMotion ? .easeInOut(duration: 0.1) : .spring(response: 0.28, dampingFraction: 0.76),
                    value: hoveredSector
                )

            // Subtle crosshairs separating the 4 quadrants
            Canvas { context, size in
                let c = CGPoint(x: size.width / 2, y: size.height / 2)
                let inner: CGFloat = 34
                let outer: CGFloat = paletteRadius - 14
                let lineColor = Color.primary.opacity(colorScheme == .dark ? 0.12 : 0.10)
                for angleDeg in [45.0, 135.0, 225.0, 315.0] {
                    let rad = angleDeg * .pi / 180.0
                    var p = Path()
                    p.move(to: CGPoint(x: c.x + inner * cos(rad), y: c.y + inner * sin(rad)))
                    p.addLine(to: CGPoint(x: c.x + outer * cos(rad), y: c.y + outer * sin(rad)))
                    context.stroke(p, with: .color(lineColor), lineWidth: 0.8)
                }
            }
            .frame(width: paletteRadius * 2, height: paletteRadius * 2)
            .allowsHitTesting(false)

            // 1. TOP: Brightness
            sectorButton(
                sector: .top,
                icon: "sun.max.fill",
                label: appState.localized("palette.brightness"),
                readout: "\(Int(round(appState.getValue(for: .brightness) * 100)))%",
                progress: appState.getValue(for: .brightness),
                colors: [Color(red: 1.0, green: 0.76, blue: 0.18), Color(red: 1.0, green: 0.48, blue: 0.0)],
                offset: CGSize(width: 0, height: -68)
            ) {
                appState.toggleAction(.brightness)
            }

            // 2. RIGHT: Volume
            sectorButton(
                sector: .right,
                icon: appState.audio.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill",
                label: appState.localized("palette.volume"),
                readout: appState.audio.isMuted ? appState.localized("dial.mute") : "\(Int(round(appState.getValue(for: .volume) * 100)))%",
                progress: appState.audio.isMuted ? 0.0 : appState.getValue(for: .volume),
                colors: appState.audio.isMuted
                    ? [Color.red, Color.red.opacity(0.7)]
                    : [Color(red: 0.18, green: 0.62, blue: 1.0), Color(red: 0.05, green: 0.38, blue: 0.95)],
                offset: CGSize(width: 68, height: 0)
            ) {
                appState.toggleAction(.volume)
            }

            // 3. BOTTOM: Keep Awake
            sectorButton(
                sector: .bottom,
                icon: "cup.and.saucer.fill",
                label: appState.localized("palette.keepAwake"),
                readout: appState.keepAwake.formattedRemaining,
                progress: appState.keepAwake.dialProgress,
                colors: [Color(red: 1.0, green: 0.62, blue: 0.18), Color(red: 0.95, green: 0.34, blue: 0.08)],
                offset: CGSize(width: 0, height: 68)
            ) {
                appState.toggleAction(.keepAwake)
            }

            // 4. LEFT: Focus / Timer
            sectorButton(
                sector: .left,
                icon: appState.isPomodoroRunning ? "pause.fill" : "timer",
                label: appState.localized("palette.timer"),
                readout: appState.formattedTimerTime,
                progress: appState.getValue(for: .timer),
                colors: appState.pomodoroMode == .focus
                    ? [Color(red: 0.78, green: 0.42, blue: 1.0), Color(red: 0.48, green: 0.22, blue: 0.95)]
                    : [Color(red: 0.25, green: 0.85, blue: 0.55), Color(red: 0.1, green: 0.65, blue: 0.38)],
                offset: CGSize(width: -68, height: 0)
            ) {
                appState.toggleAction(.timer)
            }

            // Center Glass Jewel: Dismiss
            Button(action: {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                    appState.isCursorPalettePresented = false
                }
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(isCloseHovered ? .primary : .secondary)
                    .frame(width: 44, height: 44)
                    .circularLiquidGlass(
                        tint: isCloseHovered ? .red : .clear,
                        specularIntensity: 0.95,
                        causticOpacity: 0.18,
                        isHighlighted: isCloseHovered
                    )
                    .scaleEffect(isCloseHovered ? 1.08 : 1.0)
                    .animation(.spring(response: 0.18, dampingFraction: 0.7), value: isCloseHovered)
            }
            .buttonStyle(.plain)
            .help(appState.localized("palette.closeHint"))
            .onHover { isCloseHovered = $0 }
        }
        .background(
            PaletteScrollInterceptor(hoveredSector: $hoveredSector, appState: appState)
        )
        .frame(width: paletteRadius * 2 + 28, height: paletteRadius * 2 + 28)
        .macStashTheme(appState.resolvedColorScheme)
    }

    private var activeCausticTint: Color {
        switch hoveredSector {
        case .top: return Color.orange
        case .right: return appState.audio.isMuted ? Color.red : Color.blue
        case .bottom: return Color.orange
        case .left: return appState.pomodoroMode == .focus ? Color.purple : Color.green
        case .none: return Color.clear
        }
    }

    private func sectorButton(
        sector: CursorSector,
        icon: String,
        label: String,
        readout: String,
        progress: Double,
        colors: [Color],
        offset: CGSize,
        action: @escaping () -> Void
    ) -> some View {
        let isHovered = hoveredSector == sector
        let primaryColor = colors.first ?? .accentColor

        return Button(action: action) {
            VStack(spacing: 3) {
                ZStack {
                    // Radial progress ring around icon
                    Circle()
                        .stroke(Color.primary.opacity(0.12), lineWidth: 2.5)
                        .frame(width: 34, height: 34)

                    Circle()
                        .trim(from: 0, to: max(0.0, min(1.0, progress)))
                        .stroke(
                            LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing),
                            style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 34, height: 34)

                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
                        )
                }

                Text(readout)
                    .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                    .monospacedDigit()
                    .foregroundColor(.primary)

                Text(label)
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .frame(width: 68, height: 64)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isHovered ? primaryColor.opacity(0.14) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        isHovered ? primaryColor.opacity(0.45) : Color.clear,
                        lineWidth: 1.0
                    )
            )
            .scaleEffect(isHovered ? 1.08 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.72), value: isHovered)
        }
        .buttonStyle(.plain)
        .offset(offset)
        .help(appState.localized("palette.scrollHint"))
        .onHover { hovering in
            if hovering {
                hoveredSector = sector
            } else if hoveredSector == sector {
                hoveredSector = nil
            }
        }
    }
}

private struct PaletteScrollInterceptor: NSViewRepresentable {
    @Binding var hoveredSector: CursorPaletteView.CursorSector?
    let appState: AppState

    func makeNSView(context: Context) -> ScrollCaptureNSView {
        let view = ScrollCaptureNSView()
        view.onScroll = handleScroll
        return view
    }

    func updateNSView(_ nsView: ScrollCaptureNSView, context: Context) {
        nsView.onScroll = handleScroll
    }

    @MainActor
    private func handleScroll(_ event: NSEvent) {
        guard appState.scrollAdjustmentEnabled,
              let sector = hoveredSector else { return }

        if event.hasPreciseScrollingDeltas && !event.momentumPhase.isEmpty {
            return
        }

        let rawY = event.hasPreciseScrollingDeltas ? event.scrollingDeltaY : (event.deltaY * 10.0)
        let rawX = event.hasPreciseScrollingDeltas ? event.scrollingDeltaX : (event.deltaX * 10.0)
        let physY = event.isDirectionInvertedFromDevice ? -Double(rawY) : Double(rawY)
        let physX = event.isDirectionInvertedFromDevice ? -Double(rawX) : Double(rawX)
        let delta = (physY + physX) * 0.005
        guard abs(delta) > 0.0001 else { return }

        let action = sector.action
        let current = appState.getValue(for: action)
        let next = max(0.0, min(1.0, current + delta))
        appState.setValue(for: action, value: next)
        if event.phase == .ended || event.phase == .cancelled {
            appState.saveSettings()
        }
    }

    final class ScrollCaptureNSView: NSView {
        var onScroll: ((NSEvent) -> Void)?

        override func scrollWheel(with event: NSEvent) {
            onScroll?(event)
        }
    }
}
