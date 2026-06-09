import Foundation
import UIKit
import SwiftUI    // ← add this line
import Firebase
@MainActor
final class TasksViewModel: ObservableObject {
    @Published var pendingTasks:   [TaskItem] = []
    @Published var completedTasks: [TaskItem] = []
    @Published var missedTasks:    [TaskItem] = []
    @Published var allSubmissions: [TaskSubmission] = []
    @Published var isLoading    = false
    @Published var isSubmitting = false
    @Published var errorMessage:   String?
    @Published var successMessage: String?
    @Published var showToast    = false
    @Published var toastSuccess = true

    private let firestore     = FirestoreService.shared
    private let storage       = StorageService.shared
    private let notifications = NotificationService.shared
    private let auth          = AuthService.shared

    // MARK: - Load
    func loadTasks() async {
        guard let userId = auth.currentUser?.uid else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let tasks       = try await firestore.fetchTasks(for: userId)
            let submissions = try await firestore.fetchSubmissions(for: userId)
            allSubmissions  = submissions

            var pending:   [TaskItem] = []
            var completed: [TaskItem] = []
            var missed:    [TaskItem] = []

            for task in tasks {
                let todaySub = submissions.first {
                    $0.taskId == task.taskId &&
                    $0.submittedAt.isSameDay(as: Date()) &&
                    $0.verificationStatus != .rejected
                }
                if todaySub != nil {
                    completed.append(task)
                } else if task.isOverdue {
                    missed.append(task)
                } else {
                    pending.append(task)
                }
            }

            pendingTasks   = pending
            completedTasks = completed
            missedTasks    = missed

            await notifications.rescheduleAllTaskReminders(tasks: pending)
        } catch {
            showError(error.localizedDescription)
        }
    }

    // MARK: - Complete (simple)
    func completeTask(_ task: TaskItem, image: UIImage? = nil, note: String? = nil) async {
        guard let userId = auth.currentUser?.uid else { return }
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        if task.requiresProof && image == nil {
            showError("This task requires an attachment.")
            return
        }

        do {
            var imageURL: String?
            if let image {
                imageURL = try await storage.uploadTaskAttachment(
                    image: image, userId: userId, taskId: task.taskId
                )
            }
            let submission = TaskSubmission(
                taskId: task.taskId,
                userId: userId,
                taskTitle: task.title,
                imageURL: imageURL,
                note: note,
                submittedAt: Date(),
                verificationStatus: .pendingReview
            )
            try await firestore.submitTask(submission)
            notifications.cancelTaskReminders(taskId: task.taskId)
            showSuccess("Task submitted! ✅")
            await loadTasks()
        } catch {
            showError(error.localizedDescription)
        }
    }

    // MARK: - Get today's submission for a task
    func todaySubmission(for taskId: String) -> TaskSubmission? {
        allSubmissions.first {
            $0.taskId == taskId &&
            $0.submittedAt.isSameDay(as: Date())
        }
    }

    // MARK: - Helpers
    private func showSuccess(_ msg: String) {
        successMessage = msg
        errorMessage   = nil
        toastSuccess   = true
        withAnimation { showToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
            withAnimation { self.showToast = false }
        }
    }

    private func showError(_ msg: String) {
        errorMessage   = msg
        successMessage = nil
        toastSuccess   = false
        withAnimation { showToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation { self.showToast = false }
        }
    }
}
