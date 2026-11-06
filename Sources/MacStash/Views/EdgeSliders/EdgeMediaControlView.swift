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

    @State private var isHoveringDetails: Bool = false
    @State private var isPrevHovered: Bool = false
    @State private var isPlayHovered: Bool = false
    @State private var isNextHovered: Bool = false

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        ZStack(alignment: .trailing) {
            // Floating Track Details Card (flies out to the left when hovering)
            if isHoveringDetails && nowPlaying.hasMedia {
                floatingTrackInfoCard
                    .offset(x: -64)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .trailing)),
                        removal: .opacity.combined(with: .move(edge: .trailing))
                    ))
            }

            // Main Vertical Media Controller Column
            VStack(spacing: 10) {
                // 1. Album Artwork / Cover
                artworkView
                    .onHover { hovering in
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                            isHoveringDetails = hovering
                        }
                    }

                // 2. Dancing Audio Visualizer (Waveform)
                if appState.settings.edgeBarVisualizerEnabled {
                    DancingVisualizerView(
                        isPlaying: nowPlaying.isPlaying,
                        volumeFraction: audio.volume
                    )
                    .padding(.vertical, 1)
                }

                // 3. Transport Controls in exact vertical order:
                // Previous (Top) -> Play/Pause (Middle) -> Next (Bottom)
                VStack(spacing: 8) {
                    // Previous Track Button (Top)
                    Button(action: { nowPlaying.previousTrack() }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(isPrevHovered ? .primary : .secondary)
                            .frame(width: 26, height: 26)
                            .background(
                                Circle()
                                    .fill(isPrevHovered ? Color.white.opacity(0.18) : Color.clear)
                            )
                    }
                    .buttonStyle(.plain)
                    .help(appState.localized("corners.media.previous"))
                    .onHover { isPrevHovered = $0 }

                    // Play / Pause Toggle Button (Middle)
                    Button(action: { nowPlaying.togglePlayPause() }) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(isPlayHovered ? 0.32 : 0.22),
                                            Color.white.opacity(isPlayHovered ? 0.16 : 0.08)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 34, height: 34)
                                .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 2)

                            Image(systemName: nowPlaying.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.primary)
                                .offset(x: nowPlaying.isPlaying ? 0 : 1) // optical alignment for play triangle
                        }
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
                            .background(
                                Circle()
                                    .fill(isNextHovered ? Color.white.opacity(0.18) : Color.clear)
                            )
                    }
                    .buttonStyle(.plain)
                    .help(appState.localized("corners.media.next"))
                    .onHover { isNextHovered = $0 }
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .frame(width: 50)
            .onAppear {
                nowPlaying.refreshNowPlaying()
            }
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
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.35), radius: 5, x: 0, y: 2)
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
    }

    // MARK: - Floating Track Info Tooltip

    private var floatingTrackInfoCard: some View {
        HStack(spacing: 12) {
            if let artwork = nowPlaying.artworkImage {
                Image(nsImage: artwork)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(nowPlaying.title.isEmpty ? "Now Playing" : nowPlaying.title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                if !nowPlaying.artist.isEmpty {
                    Text(nowPlaying.artist)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                if !nowPlaying.album.isEmpty {
                    Text(nowPlaying.album)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary.opacity(0.8))
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: 180, alignment: .leading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.35), radius: 10, x: -3, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
}
