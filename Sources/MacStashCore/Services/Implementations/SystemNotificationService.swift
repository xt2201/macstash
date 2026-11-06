import Foundation
import UserNotifications

public final class SystemNotificationService: NotificationServiceProtocol {
    public init() {}

    public func requestAuthorization() async -> Bool {
        do {
            let center = UNUserNotificationCenter.current()
            let granted = try await center.requestAuthorization(options: [.alert, .sound])
            return granted
        } catch {
            AppLogger.lifecycle.warning("User notification authorization failed: \(error.localizedDescription)")
            return false
        }
    }

    public func deliverNotification(title: String, body: String, sound: Bool) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        if sound {
            content.sound = .default
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            AppLogger.lifecycle.warning("Failed to schedule notification: \(error.localizedDescription)")
        }
    }
}
