import SwiftUI

/// An audio-reactive equalizer waveform visualizer styled after Apple's Dynamic Island & Vorssaint.
/// Renders 5 vertical bars that dance to the rhythm of the playing audio and dynamically adopt
/// the dominant color tint extracted from the current track's album artwork.
public struct DancingVisualizerView: View {
    public let isPlaying: Bool
    public let volumeFraction: Float
    public let levels: [CGFloat]
    public let primaryTint: Color
    public let secondaryTint: Color

    private let barCount = 5
    private let barWidth: CGFloat = 3.2
    private let barSpacing: CGFloat = 2.4
    private let maxHeight: CGFloat = 17.0
    private let idleHeight: CGFloat = 3.2

    public init(
        isPlaying: Bool,
        volumeFraction: Float = 0.8,
        levels: [CGFloat] = [0.2, 0.2, 0.2, 0.2, 0.2],
        primaryTint: Color = NowPlayingManager.defaultPrimaryTint,
        secondaryTint: Color = NowPlayingManager.defaultSecondaryTint
    ) {
        self.isPlaying = isPlaying
        self.volumeFraction = volumeFraction
        self.levels = levels
        self.primaryTint = primaryTint
        self.secondaryTint = secondaryTint
    }

    public var body: some View {
        HStack(alignment: .center, spacing: barSpacing) {
            ForEach(0..<barCount, id: \.self) { index in
                let h = computeBarHeight(index: index)
                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [primaryTint, secondaryTint],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: barWidth, height: h)
                    .shadow(
                        color: isPlaying ? primaryTint.opacity(0.45) : .clear,
                        radius: 2.5,
                        x: 0,
                        y: 0
                    )
                    .animation(.spring(response: 0.15, dampingFraction: 0.72), value: h)
                    .animation(.easeInOut(duration: 0.35), value: primaryTint)
            }
        }
        .frame(height: maxHeight)
    }

    private func computeBarHeight(index: Int) -> CGFloat {
        guard isPlaying else { return idleHeight }
        let level = index < levels.count ? levels[index] : 0.25
        let clampedLevel = max(0.0, min(1.0, level))
        let computed = idleHeight + clampedLevel * (maxHeight - idleHeight)
        return max(idleHeight, min(maxHeight, computed))
    }
}
