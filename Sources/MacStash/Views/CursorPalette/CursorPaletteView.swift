import SwiftUI
import AppKit
import MacStashCore

/// Floating radial palette that blooms directly at the current mouse cursor location.
/// Designed for Ultrawide monitors and power users to adjust Volume, Brightness,
/// Keep-Awake, and Pomodoro Timer without moving the mouse all the way to screen corners,
/// elevated with Apple Liquid Glass optical shading.
public struct CursorPaletteView: View {
    @ObservedObject var appState: AppState

    @State private var hoveredSector: CursorSector? = nil

    private let paletteRadius: CGFloat = 110.0

    public enum CursorSector: CaseIterable {
        case top        // Brightness
        case right      // Volume
        case bottom     // Keep Awake
        case left       // Timer
    }

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        ZStack {
            // Liquid Glass Backdrop Compass Disc
            Circle()
                .fill(.clear)
                .frame(width: paletteRadius * 2, height: paletteRadius * 2)
                .circularLiquidGlass(
                    tint: activeCausticTint,
                    specularIntensity: 1.2,
                    causticOpacity: 0.22,
                    isHighlighted: hoveredSector != nil
                )
                .animation(.spring(response: 0.28, dampingFraction: 0.76), value: hoveredSector)

            // 4 Radial Sectors
            // 1. TOP: Brightness
            sectorButton(
                sector: .top,
                icon: "sun.max.fill",
                title: "\(Int(round(appState.getValue(for: .brightness) * 100)))%",
                colors: [Color(red: 1.0, green: 0.76, blue: 0.18), Color(red: 1.0, green: 0.48, blue: 0.0)],
                offset: CGSize(width: 0, height: -58)
            ) {
                appState.toggleAction(.brightness)
            }

            // 2. RIGHT: Volume
            sectorButton(
                sector: .right,
                icon: appState.audio.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill",
                title: appState.audio.isMuted ? "MUTE" : "\(Int(round(appState.getValue(for: .volume) * 100)))%",
                colors: [Color(red: 0.18, green: 0.62, blue: 1.0), Color(red: 0.05, green: 0.38, blue: 0.95)],
                offset: CGSize(width: 58, height: 0)
            ) {
                appState.toggleAction(.volume)
            }

            // 3. BOTTOM: Keep Awake
            sectorButton(
                sector: .bottom,
                icon: "cup.and.saucer.fill",
                title: appState.keepAwake.formattedRemaining,
                colors: [Color(red: 1.0, green: 0.62, blue: 0.18), Color(red: 0.95, green: 0.34, blue: 0.08)],
                offset: CGSize(width: 0, height: 58)
            ) {
                appState.toggleAction(.keepAwake)
            }

            // 4. LEFT: Focus / Timer
            sectorButton(
                sector: .left,
                icon: appState.isPomodoroRunning ? "pause.fill" : "timer",
                title: appState.formattedTimerTime,
                colors: [Color(red: 0.78, green: 0.42, blue: 1.0), Color(red: 0.48, green: 0.22, blue: 0.95)],
                offset: CGSize(width: -58, height: 0)
            ) {
                appState.toggleAction(.timer)
            }

            // Center Glass Jewel: Dismiss / Stash Anchor
            Button(action: {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                    appState.isCursorPalettePresented = false
                }
            }) {
                ZStack {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.secondary)
                }
                .frame(width: 44, height: 44)
                .circularLiquidGlass(
                    tint: .clear,
                    specularIntensity: 0.9,
                    causticOpacity: 0.15
                )
            }
            .buttonStyle(.plain)
            .help("Close Palette (Esc)")
        }
        .frame(width: paletteRadius * 2 + 24, height: paletteRadius * 2 + 24)
    }

    private var activeCausticTint: Color {
        switch hoveredSector {
        case .top: return Color.orange
        case .right: return Color.blue
        case .bottom: return Color.orange
        case .left: return Color.purple
        case .none: return Color.clear
        }
    }

    private func sectorButton(
        sector: CursorSector,
        icon: String,
        title: String,
        colors: [Color],
        offset: CGSize,
        action: @escaping () -> Void
    ) -> some View {
        let isHovered = hoveredSector == sector

        return Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: colors,
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: isHovered ? (colors.first ?? .clear).opacity(0.4) : .clear, radius: 4, x: 0, y: 0)

                Text(title)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(.primary)
            }
            .frame(width: 56, height: 46)
            .background(
                ZStack {
                    if isHovered {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.white.opacity(0.14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color.white.opacity(0.4), (colors.first ?? Color.white).opacity(0.3)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1.0
                                    )
                            )
                    }
                }
            )
            .scaleEffect(isHovered ? 1.10 : 1.0)
            .animation(.spring(response: 0.22, dampingFraction: 0.72), value: isHovered)
        }
        .buttonStyle(.plain)
        .offset(offset)
        .onHover { hovering in
            hoveredSector = hovering ? sector : nil
        }
    }
}
