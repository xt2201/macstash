import Foundation

/// Pure policy evaluator that determines which DockProfile matches the active app or display topology.
public struct ProfileTriggerEvaluator: Sendable {
    public init() {}

    public func matchingProfileID(
        profiles: [DockProfile],
        frontmostBundleID: String?,
        displayCount: Int
    ) -> UUID? {
        // First pass: specific app + optional display count match (highest specificity)
        if let bundleID = frontmostBundleID {
            for profile in profiles where profile.triggerRule.isEnabled {
                let apps = profile.triggerRule.activeAppBundleIDs
                guard !apps.isEmpty, apps.contains(bundleID) else { continue }
                if let requiredDisplays = profile.triggerRule.requiredDisplayCount,
                   requiredDisplays != displayCount {
                    continue
                }
                return profile.id
            }
        }

        // Second pass: display-count-only rules
        for profile in profiles where profile.triggerRule.isEnabled {
            guard profile.triggerRule.activeAppBundleIDs.isEmpty,
                  let requiredDisplays = profile.triggerRule.requiredDisplayCount,
                  requiredDisplays == displayCount else {
                continue
            }
            return profile.id
        }

        return nil
    }
}
