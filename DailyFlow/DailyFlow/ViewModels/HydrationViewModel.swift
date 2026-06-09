import Foundation
import UIKit

@MainActor
final class HydrationViewModel: ObservableObject {
    @Published var todayLogs: [WaterLog] = []
    @Published var allLogs:   [WaterLog] = []
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

    var todayCount: Int { todayLogs.count }

    var lastLogTime: String? {
        todayLogs.first?.formattedTime
    }

    var hasLoggedThisHour: Bool {
        let cal = Calendar.current
        let now = Date()
        return todayLogs.contains {
            cal.isDate($0.uploadedAt, equalTo: now, toGranularity: .hour)
        }
    }

    // MARK: - Load
    func loadLogs() async {
        guard let userId = auth.currentUser?.uid else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            allLogs   = try await firestore.fetchWaterLogs(for: userId)
            todayLogs = allLogs.filter { $0.uploadedAt.isSameDay(as: Date()) }
        } catch {
            showError(error.localizedDescription)
        }
    }

    // MARK: - Log (no image)
    func logWater(note: String? = nil) async {
        guard let userId = auth.currentUser?.uid else { return }
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            let log = WaterLog(
                userId: userId,
                note: note,
                uploadedAt: Date(),
                status: .pendingReview
            )
            try await firestore.submitWaterLog(log)
            notifications.cancelWaterRemindersForCurrentHour()
            await loadLogs()
            showSuccess("Hydration logged! 💧")
        } catch {
            showError(error.localizedDescription)
        }
    }

    // MARK: - Log with image
    func logWaterWithImage(image: UIImage, note: String? = nil) async {
        guard let userId = auth.currentUser?.uid else { return }
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            let imageURL = try await storage.uploadWaterAttachment(image: image, userId: userId)
            let log = WaterLog(
                userId: userId,
                imageURL: imageURL,
                note: note,
                uploadedAt: Date(),
                status: .pendingReview
            )
            try await firestore.submitWaterLog(log)
            notifications.cancelWaterRemindersForCurrentHour()
            await loadLogs()
            showSuccess("Update submitted! 💧")
        } catch {
            showError(error.localizedDescription)
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
