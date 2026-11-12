import AppKit
import SideDockWidgets

public enum SystemDockPermission: Sendable {
    case accessibility
    case screenRecording
}

public final class LazyPermissionManager: @unchecked Sendable {
    public static let shared = LazyPermissionManager()

    public func explainAndRequestPermission(
        for permission: WidgetPermission,
        featureName: String,
        completion: @Sendable @escaping (Bool) -> Void
    ) {
        let (title, message) = explanationContent(for: permission, feature: featureName)
        presentModal(title: title, message: message, completion: completion)
    }

    public func explainAndRequestSystemPermission(
        _ permission: SystemDockPermission,
        completion: @Sendable @escaping (Bool) -> Void
    ) {
        let title: String
        let message: String
        switch permission {
        case .accessibility:
            title = "Accessibility Access Required"
            message = "Second Dock uses Accessibility to read notification badges, arrange windows for Reserve Space, and run menu-click actions."
        case .screenRecording:
            title = "Screen Recording Access (Optional)"
            message = "Second Dock uses Screen Recording strictly on-device via ScreenCaptureKit to render live window preview thumbnails. Everything stays local."
        }
        presentModal(title: title, message: message, completion: completion)
    }

    private func presentModal(title: String, message: String, completion: @Sendable @escaping (Bool) -> Void) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = title
            alert.informativeText = message
            alert.alertStyle = .informational
            alert.addButton(withTitle: "Continue")
            alert.addButton(withTitle: "Cancel")

            let response = alert.runModal()
            completion(response == .alertFirstButtonReturn)
        }
    }

    private func explanationContent(for permission: WidgetPermission, feature: String) -> (String, String) {
        switch permission {
        case .calendar:
            return (
                "Calendar Access Required",
                "SideDock needs permission to read your Calendar events to display upcoming meetings and countdowns on the '\(feature)' widget. No data ever leaves your Mac."
            )
        case .reminders:
            return (
                "Reminders Access Required",
                "SideDock requires access to Apple Reminders to list and check off your tasks on the '\(feature)' widget."
            )
        case .appleEvents:
            return (
                "Automation Permission Required",
                "SideDock uses Apple Events to communicate directly with Music or Spotify for player controls on the '\(feature)' widget."
            )
        case .location:
            return (
                "Location Services (Optional)",
                "SideDock can use your location to automatically fetch local weather. You can also manually choose any city without granting location access."
            )
        case .notifications:
            return (
                "Desktop Notifications",
                "SideDock delivers desktop alerts when Pomodoro focus sprints or break timers finish."
            )
        case .none:
            return ("Permission", "No additional permissions required.")
        }
    }
}
