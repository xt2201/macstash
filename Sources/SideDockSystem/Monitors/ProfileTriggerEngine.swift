import AppKit
import SideDockCore

@MainActor
public final class ProfileTriggerEngine {
    private let evaluator = ProfileTriggerEvaluator()
    private nonisolated(unsafe) var observers: [NSObjectProtocol] = []

    public init() {}

    deinit {
        for obs in observers {
            NSWorkspace.shared.notificationCenter.removeObserver(obs)
            NotificationCenter.default.removeObserver(obs)
        }
    }

    public func start(
        profilesProvider: @escaping @Sendable @MainActor () -> [DockProfile],
        activeProfileIDProvider: @escaping @Sendable @MainActor () -> UUID,
        onMatchProfile: @escaping @Sendable @MainActor (UUID) -> Void
    ) {
        stop()

        let wsObs = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notif in
            let bundleID = (notif.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication)?.bundleIdentifier
            Task { @MainActor in
                guard let self else { return }
                self.evaluate(
                    frontmostBundleID: bundleID,
                    profiles: profilesProvider(),
                    currentActiveID: activeProfileIDProvider(),
                    onMatchProfile: onMatchProfile
                )
            }
        }

        let screenObs = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                let frontID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
                self.evaluate(
                    frontmostBundleID: frontID,
                    profiles: profilesProvider(),
                    currentActiveID: activeProfileIDProvider(),
                    onMatchProfile: onMatchProfile
                )
            }
        }

        observers = [wsObs, screenObs]
    }

    public func stop() {
        for obs in observers {
            NSWorkspace.shared.notificationCenter.removeObserver(obs)
            NotificationCenter.default.removeObserver(obs)
        }
        observers.removeAll()
    }

    private func evaluate(
        frontmostBundleID: String?,
        profiles: [DockProfile],
        currentActiveID: UUID,
        onMatchProfile: @MainActor (UUID) -> Void
    ) {
        guard frontmostBundleID != Bundle.main.bundleIdentifier else { return }
        if let matched = evaluator.matchingProfileID(
            profiles: profiles,
            frontmostBundleID: frontmostBundleID,
            displayCount: NSScreen.screens.count
        ), matched != currentActiveID {
            onMatchProfile(matched)
        }
    }
}
