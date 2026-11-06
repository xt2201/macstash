import SwiftUI

/// An animated audio equalizer waveform visualizer matching Apple's Dynamic Island style.
/// Displays 5 dancing vertical bars in a vibrant orange-amber gradient when media is playing,
/// and smoothly settles into an idle resting state when paused.
public struct DancingVisualizerView: View {
    public let isPlaying: Bool
    public let volumeFraction: Float

    private let barCount = 5
    private let barWidth: CGFloat = 3.0
    private let barSpacing: CGFloat = 2.2
    private let maxHeight: CGFloat = 16.0
    private let idleHeight: CGFloat = 3.0

    public init(isPlaying: Bool, volumeFraction: Float = 0.8) {
        self.isPlaying = isPlaying
        self.volumeFraction = volumeFraction
    }

    public var body: some View {
        TimelineView(.animation(minimumInterval: isPlaying ? 1.0 / 30.0 : 1.0)) { timeline in
            let date = timeline.date.timeIntervalSinceReferenceDate
            HStack(alignment: .center, spacing: barSpacing) {
                ForEach(0..<barCount, id: \.self) { index in
                    let h = computeBarHeight(index: index, time: date)
                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.35, blue: 0.0), // Deep energetic orange
                                    Color(red: 1.0, green: 0.65, blue: 0.1)  // Bright warm amber
                                ],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(width: barWidth, height: h)
                        .shadow(color: isPlaying ? Color(red: 1.0, green: 0.45, blue: 0.0).opacity(0.35) : .clear, radius: 2)
                        .animation(.spring(response: 0.25, dampingFraction: 0.65), value: h)
                }
            }
            .frame(height: maxHeight)
        }
    }

    private func computeBarHeight(index: Int, time: TimeInterval) -> CGFloat {
        guard isPlaying else { return idleHeight }

        // Frequency parameters per bar to simulate authentic audio spectrum bands (Bass -> Treble)
        let speeds: [Double] = [7.5, 9.2, 11.8, 10.4, 8.6]
        let phases: [Double] = [0.0, 1.4, 2.8, 4.1, 5.5]
        let baseAmps: [Double] = [0.85, 0.95, 1.0, 0.9, 0.75]

        let speed = speeds[index % speeds.count]
        let phase = phases[index % phases.count]
        let baseAmp = baseAmps[index % baseAmps.count]

        // Multi-frequency harmonic wave for organic rhythm
        let wave1 = sin(time * speed + phase)
        let wave2 = cos(time * (speed * 0.63) + phase * 1.3)
        let combined = (wave1 * 0.6 + wave2 * 0.4 + 1.0) / 2.0 // Normalized 0.0 ... 1.0

        // Scale by volume (clamped between 0.3 and 1.0 for aesthetic visibility even at low volume)
        let volScale = Double(max(0.35, min(1.0, volumeFraction)))
        let computed = idleHeight + CGFloat(combined * baseAmp * volScale) * (maxHeight - idleHeight)

        return max(idleHeight, min(maxHeight, computed))
    }
}
