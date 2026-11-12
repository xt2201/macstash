import SwiftUI
import AppKit
import MacStashCore

/// Dynamic Island style horizontal expandable media controller for the Edge Bar.
/// Morphs outward horizontally when hovering the artwork capsule, revealing track details,
/// a live audio visualizer, an interactive scrubber bar (supports both drag and vertical two-finger swipe),
/// and 5 transport controls plus an edge-most Volume Logo button.
public struct EdgeMediaIslandView: View {
    @ObservedObject private var nowPlaying = NowPlayingManager.shared
    @ObservedObject private var audio = AudioManager.shared
    @ObservedObject var appState: AppState
    public let edge: EdgePosition

    @Binding var isVolumeHovered: Bool

    @State private var isPrevHovered: Bool = false
    @State private var isRewindHovered: Bool = false
    @State private var isPlayHovered: Bool = false
    @State private var isForwardHovered: Bool = false
    @State private var isNextHovered: Bool = false
    @State private var isVolBtnHovered: Bool = false

    @State private var isScrubbing: Bool = false
    @State private var scrubFraction: Double = 0.0

    public init(
        appState: AppState,
        edge: EdgePosition = .right,
        isVolumeHovered: Binding<Bool>
    ) {
        self.appState = appState
        self.edge = edge
        self._isVolumeHovered = isVolumeHovered
    }

    private var activeProgress: Double {
        if isScrubbing {
            return scrubFraction
        }
        if nowPlaying.isInteractiveScrubbing && nowPlaying.duration > 0.0 {
            return max(0.0, min(1.0, nowPlaying.liveScrubTime / nowPlaying.duration))
        }
        if nowPlaying.duration > 0.0 {
            return max(0.0, min(1.0, nowPlaying.elapsedTime / nowPlaying.duration))
        }
        return 0.0
    }

    public var body: some View {
        expandedIslandView
            .onAppear {
                nowPlaying.pollLivePlaybackPosition()
            }
    }

    // MARK: - Expanded Dynamic Island View (312x98)

    @ViewBuilder
    private var expandedIslandView: some View {
        VStack(spacing: 6) {
            // Row 1: Artwork + Track Details + Waveform Visualizer
            HStack(spacing: 8) {
                // Album artwork thumbnail
                Button(action: { nowPlaying.activateCurrentApp() }) {
                    ZStack {
                        if let artwork = nowPlaying.artworkImage {
                            Image(nsImage: artwork)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 34, height: 34)
                                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                        } else {
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .fill(Color.primary.opacity(0.12))
                                .frame(width: 34, height: 34)
                                .overlay(
                                    Image(systemName: "music.note")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.secondary)
                                )
                        }
                    }
                }
                .buttonStyle(.plain)
                .help(appState.localized("corners.media.openApp"))

                // Title and Artist
                VStack(alignment: .leading, spacing: 1) {
                    Text(nowPlaying.title.isEmpty ? appState.localized("edge.noMedia") : nowPlaying.title)
                        .font(.system(size: 11.5, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Text(nowPlaying.artist.isEmpty ? "MacStash" : nowPlaying.artist)
                        .font(.system(size: 9.5, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 4)

                // Dancing audio visualizer waveform
                if appState.settings.edgeBarVisualizerEnabled {
                    DancingVisualizerView(
                        isPlaying: nowPlaying.isPlaying,
                        volumeFraction: audio.volume,
                        levels: nowPlaying.audioLevels,
                        primaryTint: nowPlaying.artworkTint,
                        secondaryTint: nowPlaying.artworkSecondaryTint
                    )
                    .frame(width: 22, height: 16)
                }
            }

            // Row 2: Audio Scrubber Bar with Time Readouts
            islandScrubberView

            // Row 3: Transport Controls + Extreme Edge Volume Logo Button
            HStack(spacing: 8) {
                if edge == .left {
                    volumeButton
                    Spacer(minLength: 2)
                } else {
                    Spacer(minLength: 2)
                }

                // Previous Track
                Button(action: { nowPlaying.previousTrack() }) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(isPrevHovered ? .primary : .secondary)
                        .frame(width: 24, height: 24)
                        .circularLiquidGlass(tint: .clear, specularIntensity: 0.8, causticOpacity: 0.15, isHighlighted: isPrevHovered)
                }
                .buttonStyle(.plain)
                .help(appState.localized("corners.media.previous"))
                .onHover { isPrevHovered = $0 }

                // Quick Skip Backward 10s
                Button(action: { nowPlaying.skipBackward(seconds: 10) }) {
                    Image(systemName: "gobackward.10")
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundColor(isRewindHovered ? nowPlaying.artworkTint : .secondary)
                        .frame(width: 26, height: 24)
                        .circularLiquidGlass(tint: isRewindHovered ? nowPlaying.artworkTint : .clear, specularIntensity: 0.9, causticOpacity: 0.20, isHighlighted: isRewindHovered)
                }
                .buttonStyle(.plain)
                .help(appState.localized("corners.media.seekBackward"))
                .onHover { isRewindHovered = $0 }

                // Play / Pause Toggle
                Button(action: { nowPlaying.togglePlayPause() }) {
                    Image(systemName: nowPlaying.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.primary)
                        .offset(x: nowPlaying.isPlaying ? 0 : 0.8)
                        .frame(width: 30, height: 30)
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

                // Quick Skip Forward 10s
                Button(action: { nowPlaying.skipForward(seconds: 10) }) {
                    Image(systemName: "goforward.10")
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundColor(isForwardHovered ? nowPlaying.artworkTint : .secondary)
                        .frame(width: 26, height: 24)
                        .circularLiquidGlass(tint: isForwardHovered ? nowPlaying.artworkTint : .clear, specularIntensity: 0.9, causticOpacity: 0.20, isHighlighted: isForwardHovered)
                }
                .buttonStyle(.plain)
                .help(appState.localized("corners.media.seekForward"))
                .onHover { isForwardHovered = $0 }

                // Next Track
                Button(action: { nowPlaying.nextTrack() }) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(isNextHovered ? .primary : .secondary)
                        .frame(width: 24, height: 24)
                        .circularLiquidGlass(tint: .clear, specularIntensity: 0.8, causticOpacity: 0.15, isHighlighted: isNextHovered)
                }
                .buttonStyle(.plain)
                .help(appState.localized("corners.media.next"))
                .onHover { isNextHovered = $0 }

                if edge == .right {
                    Spacer(minLength: 2)
                    volumeButton
                } else {
                    Spacer(minLength: 2)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(width: 312, height: 98)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.ultraThinMaterial)

                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                nowPlaying.artworkTint.opacity(0.20),
                                Color.black.opacity(0.38)
                            ],
                            startPoint: edge == .right ? .trailing : .leading,
                            endPoint: edge == .right ? .leading : .trailing
                        )
                    )
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.45),
                            nowPlaying.artworkTint.opacity(0.35),
                            Color.white.opacity(0.12)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.1
                )
        )
        .shadow(color: Color.black.opacity(0.40), radius: 14, x: 0, y: 6)
    }

    // MARK: - Edge Volume Logo Button

    @ViewBuilder
    private var volumeButton: some View {
        let isHighlighted = isVolumeHovered
        Button(action: {
            appState.audio.toggleMute()
        }) {
            Image(systemName: appState.audio.isMuted ? "speaker.slash.fill" : (audio.volume > 0.5 ? "speaker.wave.2.fill" : (audio.volume > 0.01 ? "speaker.wave.1.fill" : "speaker.fill")))
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(isHighlighted ? .white : nowPlaying.artworkTint)
                .scaleEffect(isHighlighted ? 1.08 : 1.0)
                .animation(.easeInOut(duration: 0.14), value: isHighlighted)
                .frame(width: 28, height: 26)
                .circularLiquidGlass(
                    tint: nowPlaying.artworkTint,
                    specularIntensity: 1.2,
                    causticOpacity: 0.30,
                    isHighlighted: isHighlighted
                )
        }
        .buttonStyle(.plain)
        .frame(width: 28, height: 26)
        .contentShape(Rectangle())
        .help(appState.audio.isMuted ? appState.localized("menubar.unmute") : appState.localized("menubar.mute"))
        .onHover { hovering in
            isVolBtnHovered = hovering
            isVolumeHovered = hovering
        }
    }

    private var displayedElapsedText: String {
        if isScrubbing && nowPlaying.duration > 0.0 {
            let secs = scrubFraction * nowPlaying.duration
            let m = Int(secs) / 60
            let s = Int(secs) % 60
            return String(format: "%d:%02d", m, s)
        }
        if nowPlaying.isInteractiveScrubbing {
            let secs = nowPlaying.liveScrubTime
            let m = Int(secs) / 60
            let s = Int(secs) % 60
            return String(format: "%d:%02d", m, s)
        }
        return nowPlaying.formattedElapsedTime
    }

    // MARK: - Scrubber View

    @ViewBuilder
    private var islandScrubberView: some View {
        let isScrubbingActive = isScrubbing || nowPlaying.isInteractiveScrubbing

        HStack(spacing: 6) {
            Text(displayedElapsedText)
                .font(.system(size: 8.5, weight: isScrubbingActive ? .heavy : .bold, design: .monospaced))
                .monospacedDigit()
                .foregroundColor(isScrubbingActive ? nowPlaying.artworkTint : .secondary)
                .frame(width: 32, alignment: .leading)

            GeometryReader { geo in
                let w = max(1, geo.size.width)
                let h = geo.size.height
                let thumbFrame: CGFloat = 10.0
                let thumbRadius = thumbFrame * 0.5
                let usableW = max(1.0, w - thumbFrame)
                let thumbCenterX = thumbRadius + usableW * CGFloat(activeProgress)
                let fillWidth = max(thumbRadius, thumbCenterX)

                ZStack(alignment: .leading) {
                    // Track background
                    Capsule()
                        .fill(Color.primary.opacity(0.16))
                        .frame(width: w, height: 5)

                    // Active progress fill aligned cleanly to thumb center
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [nowPlaying.artworkTint, nowPlaying.artworkSecondaryTint],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: fillWidth, height: 5)

                    // Scrubber thumb: scaleEffect precedes position so center coordinate is never scaled
                    Circle()
                        .fill(Color.white)
                        .frame(width: thumbFrame, height: thumbFrame)
                        .overlay(
                            Circle()
                                .stroke(nowPlaying.artworkTint.opacity(isScrubbingActive ? 0.90 : 0.0), lineWidth: 1.5)
                        )
                        .shadow(
                            color: isScrubbingActive ? nowPlaying.artworkTint.opacity(0.65) : Color.black.opacity(0.40),
                            radius: isScrubbingActive ? 4 : 2,
                            x: 0,
                            y: 1
                        )
                        .scaleEffect(isScrubbingActive ? 1.15 : 0.82)
                        .animation(.spring(response: 0.18, dampingFraction: 0.75), value: isScrubbingActive)
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
            .frame(height: 14)

            Text(nowPlaying.duration > 0 ? nowPlaying.formattedDuration : "--:--")
                .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                .monospacedDigit()
                .foregroundColor(.secondary)
                .frame(width: 32, alignment: .trailing)
        }
        .frame(height: 16)
        .help(appState.localized("corners.media.scrubber"))
    }
}
