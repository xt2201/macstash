import AppKit

public enum HapticIntensity: String, CaseIterable, Identifiable, Codable {
    case off = "Off"
    case subtle = "Subtle"
    case medium = "Medium"
    case strong = "Strong"

    public var id: String { rawValue }
}

/// Provides tactile trackpad feedback for dial rotations and slider steps
@MainActor
public final class HapticManager {
    public static let shared = HapticManager()

    private init() {}

    /// Perform a tactile click when crossing an increment notch
    public func performDetentTick(intensity: HapticIntensity = .medium) {
        guard intensity != .off else { return }

        switch intensity {
        case .subtle:
            NSHapticFeedbackManager.defaultPerformer.perform(
                .alignment,
                performanceTime: .now
            )
        case .medium:
            NSHapticFeedbackManager.defaultPerformer.perform(
                .levelChange,
                performanceTime: .now
            )
        case .strong:
            NSHapticFeedbackManager.defaultPerformer.perform(
                .levelChange,
                performanceTime: .now
            )
        case .off:
            break
        }
    }

    /// Perform a pronounced click when hitting minimum or maximum bounds
    public func performBoundaryClick(intensity: HapticIntensity = .medium) {
        guard intensity != .off else { return }
        NSHapticFeedbackManager.defaultPerformer.perform(
            .alignment,
            performanceTime: .now
        )
    }
}
