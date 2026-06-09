import Foundation
import UserNotifications

final class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()

    private let center = UNUserNotificationCenter.current()

    static let waterCategoryId = "WATER_REMINDER"
    static let taskCategoryId  = "TASK_REMINDER"

    // Water window: 10 AM → 10 PM
    private let waterStartHour = 10
    private let waterEndHour   = 22

    private let waterMessages: [(title: String, body: String)] = [
        ("Hydration Reminder 💧", "Time to refresh and hydrate"),
        ("Stay Hydrated 💧",      "Daily wellness check — drink some water"),
        ("Wellness Reminder 💧",  "Friendly reminder to stay hydrated"),
        ("Daily Wellness 💧",     "Keep up your hydration routine"),
        ("Refresh Time 💧",       "A moment to hydrate and recharge"),
        ("Hydration Check 💧",    "Don't forget to drink water today"),
    ]

    private override init() {
        super.init()
        center.delegate = self
    }

    // MARK: - Categories
    func registerCategories() {
        let waterCategory = UNNotificationCategory(
            identifier: Self.waterCategoryId,
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        let taskCategory = UNNotificationCategory(
            identifier: Self.taskCategoryId,
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        center.setNotificationCategories([waterCategory, taskCategory])
    }

    // MARK: - Permission
    func requestPermission() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            if granted {
                await scheduleWaterReminders()
            }
            return granted
        } catch {
            return false
        }
    }

    func checkPermissionStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    // MARK: - Water Reminders (10 AM – 10 PM, every hour :00, :20, :40)
    func scheduleWaterReminders() async {
        await cancelWaterReminders()

        var notifIndex = 0

        for hour in waterStartHour...waterEndHour {
            // At exact hour
            let msg = waterMessages[notifIndex % waterMessages.count]
            await scheduleRepeatingWaterNotif(
                id: "water-\(hour)-0",
                title: msg.title,
                body:  msg.body,
                hour: hour,
                minute: 0
            )
            notifIndex += 1

            // :20 and :40 reminders only within the window (not AT end hour)
            if hour < waterEndHour {
                let msg20 = waterMessages[notifIndex % waterMessages.count]
                await scheduleRepeatingWaterNotif(
                    id: "water-\(hour)-20",
                    title: msg20.title,
                    body:  msg20.body,
                    hour: hour,
                    minute: 20
                )
                notifIndex += 1

                let msg40 = waterMessages[notifIndex % waterMessages.count]
                await scheduleRepeatingWaterNotif(
                    id: "water-\(hour)-40",
                    title: msg40.title,
                    body:  msg40.body,
                    hour: hour,
                    minute: 40
                )
                notifIndex += 1
            }
        }
    }

    // Uses repeating calendar trigger so reminders fire daily without rescheduling
    private func scheduleRepeatingWaterNotif(
        id: String, title: String, body: String, hour: Int, minute: Int
    ) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = Self.waterCategoryId

        var dc = DateComponents()
        dc.hour   = hour
        dc.minute = minute
        dc.second = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        try? await center.add(request)
    }

    // Cancel :20 and :40 for current hour after user logs water
    func cancelWaterRemindersForCurrentHour() {
        let now = Date()
        let cal = Calendar.current
        let hour   = cal.component(.hour,   from: now)
        let minute = cal.component(.minute, from: now)
        guard hour >= waterStartHour, hour <= waterEndHour else { return }

        var toCancel: [String] = []
        if minute < 20 {
            toCancel.append("water-\(hour)-20")
            toCancel.append("water-\(hour)-40")
        } else if minute < 40 {
            toCancel.append("water-\(hour)-40")
        }
        // Also cancel current-hour main if somehow still pending
        toCancel.append("water-\(hour)-0")
        center.removePendingNotificationRequests(withIdentifiers: toCancel)
    }

    func cancelWaterReminders() async {
        let pending = await center.pendingNotificationRequests()
        let ids = pending.map(\.identifier).filter { $0.hasPrefix("water-") }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    // MARK: - Task Reminders
    func scheduleTaskReminder(task: TaskItem) async {
        guard let dueTime = task.dueTime, dueTime > Date() else { return }

        let taskId = task.taskId
        let slots: [(Int, String)] = [(0, ""), (20, "Reminder: "), (40, "Don't forget: ")]

        for (offset, prefix) in slots {
            guard let fireDate = Calendar.current.date(
                byAdding: .minute, value: offset, to: dueTime
            ), fireDate > Date() else { continue }

            let content = UNMutableNotificationContent()
            content.title = task.priority == .urgent ? "⚠️ \(task.title)" : task.title
            content.body = prefix.isEmpty
                ? (task.description.isEmpty ? "Task reminder" : task.description)
                : "\(prefix)\(task.title)"
            content.sound = .default
            content.categoryIdentifier = Self.taskCategoryId

            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute], from: fireDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: "task-\(taskId)-\(offset)",
                content: content,
                trigger: trigger
            )
            try? await center.add(request)
        }
    }

    func cancelTaskReminders(taskId: String) {
        let ids = [0, 20, 40].map { "task-\(taskId)-\($0)" }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    func rescheduleAllTaskReminders(tasks: [TaskItem]) async {
        let pending = await center.pendingNotificationRequests()
        let old = pending.map(\.identifier).filter { $0.hasPrefix("task-") }
        center.removePendingNotificationRequests(withIdentifiers: old)
        for task in tasks where task.isActive {
            await scheduleTaskReminder(task: task)
        }
    }

    // MARK: - Cancel All
    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }
}

// MARK: - Delegate
extension NotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler handler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        handler([.banner, .sound])
    }
}
