import AppKit
import SideDockWidgets

public final class LazyPermissionManager: @unchecked Sendable {
    public static let shared = LazyPermissionManager()

    public func explainAndRequestPermission(
        for permission: WidgetPermission,
        featureName: String,
        completion: @Sendable @escaping (Bool) -> Void
    ) {
        let (title, message) = explanationContent(for: permission, feature: featureName)

        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = title
            alert.informativeText = message
            alert.alertStyle = .informational
            alert.addButton(withTitle: "Continue")
            alert.addButton(withTitle: "Cancel")

            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                completion(true)
            } else {
                completion(false)
            }
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
