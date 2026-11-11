import SwiftUI
import AppKit
import MacStashCore

/// Vertical media controller module positioned directly below the volume slider along the screen edge.
/// Displays album artwork, animated dancing visualizer bars, and vertical playback controls:
/// Previous (Top), Play/Pause (Middle), Next (Bottom).
public struct EdgeMediaControlView: View {
    @ObservedObject private var nowPlaying = NowPlayingManager.shared
    @ObservedObject private var audio = AudioManager.shared
    @ObservedObject var appState: AppState

    @State private var isPrevHovered: Bool = false
    @State private var isPlayHovered: Bool = false
    @State private var isNextHovered: Bool = false

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        VStack(spacing: 8) {
            // 1. Album Artwork / Cover
            artworkView
                .onTapGesture {
                    nowPlaying.activateCurrentApp()
                }

            // 2. Dancing Audio Visualizer (Waveform)
            if appState.settings.edgeBarVisualizerEnabled {
                DancingVisualizerView(
                    isPlaying: nowPlaying.isPlaying,
                    volumeFraction: audio.volume,
                    levels: nowPlaying.audioLevels,
                    primaryTint: nowPlaying.artworkTint,
                    secondaryTint: nowPlaying.artworkSecondaryTint
                )
                .padding(.vertical, 1)
            }

            // 3. Transport Controls in exact vertical order:
            // Previous (Top) -> Play/Pause (Middle) -> Next (Bottom)
            VStack(spacing: 6) {
                // Previous Track Button (Top)
                Button(action: { nowPlaying.previousTrack() }) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(isPrevHovered ? .primary : .secondary)
                        .frame(width: 26, height: 26)
                        .circularLiquidGlass(
                            tint: .clear,
                            specularIntensity: 0.8,
                            causticOpacity: 0.15,
                            isHighlighted: isPrevHovered
                        )
                }
                .buttonStyle(.plain)
                .help(appState.localized("corners.media.previous"))
                .onHover { isPrevHovered = $0 }

                // Play / Pause Toggle Button (Middle)
                Button(action: { nowPlaying.togglePlayPause() }) {
                    ZStack {
                        Image(systemName: nowPlaying.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.primary)
                            .offset(x: nowPlaying.isPlaying ? 0 : 1) // optical alignment for play triangle
                    }
                    .frame(width: 34, height: 34)
                    .circularLiquidGlass(
                        tint: nowPlaying.isPlaying ? nowPlaying.artworkTint : .clear,
                        specularIntensity: 1.2,
                        causticOpacity: 0.35,
                        isHighlighted: isPlayHovered
                    )
                }
                .buttonStyle(.plain)
                .help(nowPlaying.isPlaying ? appState.localized("corners.media.pause") : appState.localized("corners.media.play"))
                .onHover { isPlayHovered = $0 }

                // Next Track Button (Bottom)
                Button(action: { nowPlaying.nextTrack() }) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(isNextHovered ? .primary : .secondary)
                        .frame(width: 26, height: 26)
                        .circularLiquidGlass(
                            tint: .clear,
                            specularIntensity: 0.8,
                            causticOpacity: 0.15,
                            isHighlighted: isNextHovered
                        )
                }
                .buttonStyle(.plain)
                .help(appState.localized("corners.media.next"))
                .onHover { isNextHovered = $0 }
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 3)
        .frame(width: 56)
        .onAppear {
            nowPlaying.refreshNowPlaying()
        }
    }

    // MARK: - Album Artwork View

    @ViewBuilder
    private var artworkView: some View {
        ZStack {
            if let artwork = nowPlaying.artworkImage {
                Image(nsImage: artwork)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 36, height: 36)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(
                                nowPlaying.isPlaying ? nowPlaying.artworkTint.opacity(0.55) : Color.white.opacity(0.22),
                                lineWidth: 1.2
                            )
                    )
                    .shadow(
                        color: nowPlaying.isPlaying ? nowPlaying.artworkTint.opacity(0.42) : Color.black.opacity(0.35),
                        radius: 6,
                        x: 0,
                        y: 2
                    )
            } else {
                // Placeholder vinyl / musical note when no artwork is available
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.18, green: 0.22, blue: 0.3),
                                Color(red: 0.1, green: 0.12, blue: 0.18)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.65))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
            }
        }
        .help(nowPlaying.hasMedia ? "\(nowPlaying.title) • \(nowPlaying.artist)" : appState.localized("edge.noMedia"))
    }
}
