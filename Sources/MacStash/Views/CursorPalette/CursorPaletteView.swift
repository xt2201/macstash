import SwiftUI
import AppKit
import MacStashCore

/// Floating radial palette that blooms directly at the current mouse cursor location.
/// Designed for Ultrawide monitors and power users to adjust Volume, Brightness,
/// Keep-Awake, and Pomodoro Timer without moving the mouse all the way to screen corners.
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
            // Backdrop Disc
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: paletteRadius * 2, height: paletteRadius * 2)
                .shadow(color: Color.black.opacity(0.35), radius: 18, x: 0, y: 6)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.28), Color.white.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )

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

            // Center Badge: Dismiss / Stash Anchor
            Button(action: {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                    appState.isCursorPalettePresented = false
                }
            }) {
                ZStack {
                    Circle()
                        .fill(.ultraThickMaterial)
                        .frame(width: 44, height: 44)
                        .overlay(Circle().stroke(Color.white.opacity(0.18), lineWidth: 1))
                        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)

                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)
            .help("Close Palette (Esc)")
        }
        .frame(width: paletteRadius * 2 + 20, height: paletteRadius * 2 + 20)
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

                Text(title)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(.primary)
            }
            .frame(width: 52, height: 42)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isHovered ? Color.white.opacity(0.15) : Color.clear)
            )
            .scaleEffect(isHovered ? 1.08 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isHovered)
        }
        .buttonStyle(.plain)
        .offset(offset)
        .onHover { hovering in
            hoveredSector = hovering ? sector : nil
        }
    }
}
