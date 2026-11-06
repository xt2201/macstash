import AppKit
import AudioToolbox

/// Manages subtle mechanical audio clicks for dial rotation and slider detents
@MainActor
public final class SoundEffectManager {
    public static let shared = SoundEffectManager()

    private var lastPlayTime: TimeInterval = 0
    private let minInterval: TimeInterval = 0.035 // Throttle to prevent audio stutter

    private init() {}

    /// Play a subtle tactile mechanical tick sound
    public func playTick(enabled: Bool = true, volume: Float = 0.5) {
        guard enabled, volume > 0 else { return }

        let now = ProcessInfo.processInfo.systemUptime
        guard now - lastPlayTime > minInterval else { return }
        lastPlayTime = now

        // AudioServices system sound 1104 is the classic Apple tactile click
        AudioServicesPlaySystemSound(1104)
    }

    /// Play an accent sound when toggling or reaching extreme limit
    public func playAccent(enabled: Bool = true) {
        guard enabled else { return }
        NSSound(named: "Pop")?.play()
    }
}
