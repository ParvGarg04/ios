import Foundation
import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var pendingTasks: [TaskItem] = []
    @Published var stats        = DailyStats(completionRate:0, pendingTasks:0, completedToday:0, waterCount:0, missedTasks:0)
    @Published var streak       = 0
    @Published var isLoading    = false

    private let firestore     = FirestoreService.shared
    private let notifications = NotificationService.shared
    private let auth          = AuthService.shared

    func loadData() async {
        guard let userId = auth.currentUser?.uid else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            async let s     = firestore.fetchDailyStats(for: userId)
            async let user  = firestore.fetchUser(uid: userId)
            async let tasks = firestore.fetchTasks(for: userId)
            async let subs  = firestore.fetchSubmissions(for: userId)

            let (loadedStats, userProfile, allTasks, submissions) = try await (s, user, tasks, subs)

            stats   = loadedStats
            streak  = userProfile?.streak ?? 0

            let completedIds = Set(
                submissions.filter {
                    $0.submittedAt.isSameDay(as: Date()) &&
                    $0.verificationStatus != .rejected
                }.map(\.taskId)
            )
            pendingTasks = allTasks.filter { !completedIds.contains($0.taskId) && !$0.isOverdue }

            // Update streak
            try await firestore.updateStreak(streak, for: userId)
        } catch {
            print("HomeViewModel load error: \(error)")
        }
    }

    var nextReminderText: String {
        let cal  = Calendar.current
        let now  = Date()
        let hour = cal.component(.hour,   from: now)
        let min  = cal.component(.minute, from: now)

        guard hour >= 10, hour < 22 else {
            return hour < 10 ? "Reminders start at 10:00 AM" : "Resumes tomorrow at 10:00 AM"
        }

        let slots = [0, 20, 40]
        for slot in slots where min < slot {
            if let next = cal.date(bySettingHour: hour, minute: slot, second: 0, of: now) {
                let fmt = DateFormatter(); fmt.dateFormat = "h:mm a"
                return "Next reminder at \(fmt.string(from: next))"
            }
        }
        let nextHour = (hour + 1) % 24
        if let next = cal.date(bySettingHour: nextHour, minute: 0, second: 0, of: now) {
            let fmt = DateFormatter(); fmt.dateFormat = "h:mm a"
            return "Next reminder at \(fmt.string(from: next))"
        }
        return "Reminders active"
    }
}
