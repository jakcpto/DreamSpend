import Foundation
import UserNotifications

@MainActor
final class NotificationService {
    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func requestPermissionIfNeeded() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func scheduleDailyReminder(hour: Int, minute: Int) async {
        await clearPendingReminders()
        let content = UNMutableNotificationContent()
        content.title = "DreamSpend"
        content.body = "Заполни список трат за день"
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "daily-reminder", content: content, trigger: trigger)
        try? await center.add(request)
    }

    func clearPendingReminders() async {
        center.removePendingNotificationRequests(withIdentifiers: ["daily-reminder"])
    }
}
