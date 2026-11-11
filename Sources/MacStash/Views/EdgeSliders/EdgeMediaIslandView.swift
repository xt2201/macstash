import SwiftUI
import AppKit
import MacStashCore

/// Dynamic Island style horizontal expandable media controller for the Edge Bar.
/// In collapsed state: compact 44x44 album artwork capsule with live dancing visualizer pulse.
/// On hover: smoothly expands horizontally outward (Dynamic Island morph) revealing track details,
/// an interactive audio scrubber, and complete 5-button transport controls.
public struct EdgeMediaIslandView: View {
    @ObservedObject private var nowPlaying = NowPlayingManager.shared
    @ObservedObject private var audio = AudioManager.shared
    @ObservedObject var appState: AppState
    public let edge: EdgePosition

    @State private var isIslandExpanded: Bool = false
    @State private var collapseWorkItem: DispatchWorkItem?

    @State private var isPrevHovered: Bool = false
    @State private var isRewindHovered: Bool = false
    @State private var isPlayHovered: Bool = false
    @State private var isForwardHovered: Bool = false
    @State private var isNextHovered: Bool = false

    @State private var isScrubbing: Bool = false
    @State private var scrubFraction: Double = 0.0

    public init(appState: AppState, edge: EdgePosition = .right) {
        self.appState = appState
        self.edge = edge
    }

    private var activeProgress: Double {
        if isScrubbing {
            return scrubFraction
        }
        return nowPlaying.progressFraction
    }

    public var body: some View {
        let isExpanded = isIslandExpanded
        let alignment: Alignment = edge == .left ? .leading : .trailing

        ZStack(alignment: alignment) {
            if isExpanded {
                expandedIslandView
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.85, anchor: unitPoint(for: edge)).combined(with: .opacity),
                        removal: .scale(scale: 0.85, anchor: unitPoint(for: edge)).combined(with: .opacity)
                    ))
            } else {
                collapsedCapsuleView
                    .transition(.opacity)
            }
        }
        .frame(width: isExpanded ? 280 : 44, height: isExpanded ? 98 : 44, alignment: alignment)
        .animation(.spring(response: 0.32, dampingFraction: 0.78), value: isExpanded)
        .onHover { hovering in
            if hovering {
                collapseWorkItem?.cancel()
                collapseWorkItem = nil
                withAnimation(.spring(response: 0.30, dampingFraction: 0.76)) {
                    isIslandExpanded = true
                }
            } else {
                scheduleCollapse()
            }
        }
    }

    private func unitPoint(for edge: EdgePosition) -> UnitPoint {
        edge == .left ? .leading : .trailing
    }

    private func scheduleCollapse() {
        collapseWorkItem?.cancel()
        let item = DispatchWorkItem {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                isIslandExpanded = false
            }
        }
        collapseWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: item)
    }

    // MARK: - Collapsed Capsule View (44x44)

    @ViewBuilder
    private var collapsedCapsuleView: some View {
        ZStack {
            if let artwork = nowPlaying.artworkImage {
                Image(nsImage: artwork)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(
                                nowPlaying.isPlaying ? nowPlaying.artworkTint.opacity(0.65) : Color.white.opacity(0.20),
                                lineWidth: 1.2
                            )
                    )
                    .shadow(
                        color: nowPlaying.isPlaying ? nowPlaying.artworkTint.opacity(0.40) : Color.black.opacity(0.30),
                        radius: 6,
                        x: 0,
                        y: 2
                    )
            } else {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.16, green: 0.18, blue: 0.24),
                                Color(red: 0.08, green: 0.10, blue: 0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.70))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.white.opacity(0.16), lineWidth: 1)
                    )
            }

            // Subtle animated playback pulse indicator on corner
            if nowPlaying.isPlaying {
                Circle()
                    .fill(nowPlaying.artworkTint)
                    .frame(width: 7, height: 7)
                    .shadow(color: nowPlaying.artworkTint, radius: 3)
                    .offset(x: 14, y: -14)
            }
        }
        .frame(width: 44, height: 44)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.30, dampingFraction: 0.76)) {
                isIslandExpanded.toggle()
            }
        }
        .help(nowPlaying.hasMedia ? "\(nowPlaying.title) • \(nowPlaying.artist)" : appState.localized("edge.noMedia"))
    }

    // MARK: - Expanded Dynamic Island View (280x98)

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

            // Row 3: 5 Transport Controls (Prev, -10s, Play/Pause, +10s, Next)
            HStack(spacing: 12) {
                Spacer()

                // Previous Track
                Button(action: { nowPlaying.previousTrack() }) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 10.5, weight: .bold))
                        .foregroundColor(isPrevHovered ? .primary : .secondary)
                        .frame(width: 26, height: 24)
                        .circularLiquidGlass(tint: .clear, specularIntensity: 0.8, causticOpacity: 0.15, isHighlighted: isPrevHovered)
                }
                .buttonStyle(.plain)
                .help(appState.localized("corners.media.previous"))
                .onHover { isPrevHovered = $0 }

                // Quick Skip Backward 10s
                Button(action: { nowPlaying.skipBackward(seconds: 10) }) {
                    Image(systemName: "gobackward.10")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(isRewindHovered ? nowPlaying.artworkTint : .secondary)
                        .frame(width: 28, height: 24)
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
                        .frame(width: 32, height: 32)
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
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(isForwardHovered ? nowPlaying.artworkTint : .secondary)
                        .frame(width: 28, height: 24)
                        .circularLiquidGlass(tint: isForwardHovered ? nowPlaying.artworkTint : .clear, specularIntensity: 0.9, causticOpacity: 0.20, isHighlighted: isForwardHovered)
                }
                .buttonStyle(.plain)
                .help(appState.localized("corners.media.seekForward"))
                .onHover { isForwardHovered = $0 }

                // Next Track
                Button(action: { nowPlaying.nextTrack() }) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 10.5, weight: .bold))
                        .foregroundColor(isNextHovered ? .primary : .secondary)
                        .frame(width: 26, height: 24)
                        .circularLiquidGlass(tint: .clear, specularIntensity: 0.8, causticOpacity: 0.15, isHighlighted: isNextHovered)
                }
                .buttonStyle(.plain)
                .help(appState.localized("corners.media.next"))
                .onHover { isNextHovered = $0 }

                Spacer()
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(width: 280, height: 98)
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

    // MARK: - Scrubber View

    @ViewBuilder
    private var islandScrubberView: some View {
        HStack(spacing: 6) {
            Text(nowPlaying.formattedElapsedTime)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 28, alignment: .leading)

            GeometryReader { geo in
                let w = max(1, geo.size.width)
                ZStack(alignment: .leading) {
                    // Track background
                    Capsule()
                        .fill(Color.primary.opacity(0.16))
                        .frame(height: 5)

                    // Active progress fill
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [nowPlaying.artworkTint, nowPlaying.artworkSecondaryTint],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(4, w * CGFloat(activeProgress)), height: 5)

                    // Scrubber thumb
                    Circle()
                        .fill(Color.white)
                        .frame(width: isScrubbing ? 9 : 7, height: isScrubbing ? 9 : 7)
                        .shadow(color: Color.black.opacity(0.4), radius: 2, x: 0, y: 1)
                        .offset(x: max(0, min(w - 7, (w * CGFloat(activeProgress)) - 3.5)))
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            isScrubbing = true
                            let fraction = max(0.0, min(1.0, value.location.x / w))
                            scrubFraction = fraction
                        }
                        .onEnded { value in
                            let fraction = max(0.0, min(1.0, value.location.x / w))
                            nowPlaying.seekToProgress(fraction: fraction)
                            isScrubbing = false
                        }
                )
            }
            .frame(height: 8)

            Text(nowPlaying.formattedDuration)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 28, alignment: .trailing)
        }
        .frame(height: 12)
        .help(appState.localized("corners.media.scrubber"))
    }
}
