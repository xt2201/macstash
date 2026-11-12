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
    @State private var isRewindHovered: Bool = false
    @State private var isForwardHovered: Bool = false
    @State private var isScrubbing: Bool = false
    @State private var scrubFraction: Double = 0.0

    public init(appState: AppState) {
        self.appState = appState
    }

    private var activeProgress: Double {
        if isScrubbing {
            return scrubFraction
        }
        return nowPlaying.progressFraction
    }

    public var body: some View {
        VStack(spacing: 6) {
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

            // 3. Audio Scrubber Bar with Time Label
            scrubberView

            // 4. Transport Controls & Seeking
            VStack(spacing: 5) {
                // Previous Track Button (Top)
                Button(action: { nowPlaying.previousTrack() }) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(isPrevHovered ? .primary : .secondary)
                        .frame(width: 24, height: 22)
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

                // Quick Skip Backward 10s Button
                Button(action: { nowPlaying.skipBackward(seconds: 10) }) {
                    Image(systemName: "gobackward.10")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(isRewindHovered ? nowPlaying.artworkTint : .secondary)
                        .frame(width: 28, height: 22)
                        .circularLiquidGlass(
                            tint: isRewindHovered ? nowPlaying.artworkTint : .clear,
                            specularIntensity: 0.9,
                            causticOpacity: 0.20,
                            isHighlighted: isRewindHovered
                        )
                }
                .buttonStyle(.plain)
                .help(appState.localized("corners.media.seekBackward"))
                .onHover { isRewindHovered = $0 }

                // Play / Pause Toggle Button (Center)
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

                // Quick Skip Forward 10s Button
                Button(action: { nowPlaying.skipForward(seconds: 10) }) {
                    Image(systemName: "goforward.10")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(isForwardHovered ? nowPlaying.artworkTint : .secondary)
                        .frame(width: 28, height: 22)
                        .circularLiquidGlass(
                            tint: isForwardHovered ? nowPlaying.artworkTint : .clear,
                            specularIntensity: 0.9,
                            causticOpacity: 0.20,
                            isHighlighted: isForwardHovered
                        )
                }
                .buttonStyle(.plain)
                .help(appState.localized("corners.media.seekForward"))
                .onHover { isForwardHovered = $0 }

                // Next Track Button (Bottom)
                Button(action: { nowPlaying.nextTrack() }) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(isNextHovered ? .primary : .secondary)
                        .frame(width: 24, height: 22)
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

    // MARK: - Scrubber View

    @ViewBuilder
    private var scrubberView: some View {
        VStack(spacing: 3) {
            GeometryReader { geo in
                let w = max(1, geo.size.width)
                let h = geo.size.height
                let thumbFrame: CGFloat = 9.0
                let thumbRadius = thumbFrame * 0.5
                let usableW = max(1.0, w - thumbFrame)
                let thumbCenterX = thumbRadius + usableW * CGFloat(activeProgress)
                let fillWidth = max(thumbRadius, thumbCenterX)

                ZStack(alignment: .leading) {
                    // Track background
                    Capsule()
                        .fill(Color.primary.opacity(0.14))
                        .frame(width: w, height: 5)

                    // Active progress fill
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [nowPlaying.artworkTint, nowPlaying.artworkSecondaryTint],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: fillWidth, height: 5)

                    // Scrubber thumb
                    Circle()
                        .fill(Color.white)
                        .frame(width: thumbFrame, height: thumbFrame)
                        .shadow(color: Color.black.opacity(0.35), radius: 2, x: 0, y: 1)
                        .scaleEffect(isScrubbing ? 1.15 : 0.80)
                        .animation(.spring(response: 0.18, dampingFraction: 0.75), value: isScrubbing)
                        .position(x: thumbCenterX, y: h * 0.5)
                }
                .frame(width: w, height: h, alignment: .leading)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            isScrubbing = true
                            let fraction = max(0.0, min(1.0, (value.location.x - thumbRadius) / usableW))
                            scrubFraction = fraction
                            nowPlaying.previewInteractiveScrub(toFraction: fraction)
                        }
                        .onEnded { value in
                            let fraction = max(0.0, min(1.0, (value.location.x - thumbRadius) / usableW))
                            scrubFraction = fraction
                            isScrubbing = false
                            if nowPlaying.duration > 0.0 {
                                nowPlaying.previewInteractiveScrub(toFraction: fraction)
                                nowPlaying.commitInteractiveScrub()
                            }
                        }
                )
            }
            .frame(width: 44, height: 12)

            // Time readout
            Text(nowPlaying.duration > 0 ? "\(nowPlaying.formattedElapsedTime) / \(nowPlaying.formattedDuration)" : nowPlaying.formattedElapsedTime)
                .font(.system(size: 7.5, weight: .bold, design: .monospaced))
                .monospacedDigit()
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .help(appState.localized("corners.media.scrubber"))
        .padding(.vertical, 2)
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
