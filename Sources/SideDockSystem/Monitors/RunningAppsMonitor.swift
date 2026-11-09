import AppKit
import SideDockCore

public final class RunningAppsMonitor: @unchecked Sendable {
    public static let shared = RunningAppsMonitor()

    private var observers: [NSObjectProtocol] = []
    private var onChange: (([RunningAppInfo]) -> Void)?

    public init() {
        setupObservers()
    }

    deinit {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
    }

    public func setChangeHandler(_ handler: @escaping ([RunningAppInfo]) -> Void) {
        self.onChange = handler
        handler(currentRunningApps())
    }

    public func currentRunningApps() -> [RunningAppInfo] {
        let apps = NSWorkspace.shared.runningApplications
        return apps
            .filter { $0.activationPolicy == .regular && $0.bundleIdentifier != Bundle.main.bundleIdentifier }
            .map { app in
                RunningAppInfo(
                    processIdentifier: app.processIdentifier,
                    bundleIdentifier: app.bundleIdentifier,
                    localizedName: app.localizedName ?? "App",
                    bundleURL: app.bundleURL,
                    isHidden: app.isHidden,
                    isActive: app.isActive
                )
            }
    }

    private func setupObservers() {
        let center = NSWorkspace.shared.notificationCenter
        let notifs = [
            NSWorkspace.didLaunchApplicationNotification,
            NSWorkspace.didTerminateApplicationNotification,
            NSWorkspace.didActivateApplicationNotification,
            NSWorkspace.didHideApplicationNotification,
            NSWorkspace.didUnhideApplicationNotification
        ]

        for notif in notifs {
            let obs = center.addObserver(forName: notif, object: nil, queue: .main) { [weak self] _ in
                guard let self = self else { return }
                self.onChange?(self.currentRunningApps())
            }
            observers.append(obs)
        }
    }
}
