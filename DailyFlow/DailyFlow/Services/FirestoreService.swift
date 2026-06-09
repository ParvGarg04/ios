import Foundation
import FirebaseFirestore

@MainActor
final class FirestoreService: ObservableObject {
    static let shared = FirestoreService()

    private let db = Firestore.firestore()

    private init() {}

    // MARK: - Tasks

    func fetchTasks(for userId: String) async throws -> [TaskItem] {
        let snapshot = try await db.collection("tasks")
            .whereField("userId", isEqualTo: userId)
            .whereField("isActive", isEqualTo: true)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: TaskItem.self) }
            .sorted { ($0.dueTime ?? .distantFuture) < ($1.dueTime ?? .distantFuture) }
    }

    func fetchAllTasks() async throws -> [TaskItem] {
        let snapshot = try await db.collection("tasks")
            .order(by: "createdAt", descending: true)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: TaskItem.self) }
    }

    func createTask(_ task: TaskItem) async throws {
        try db.collection("tasks").document(task.taskId).setData(from: task)
    }

    func updateTask(_ task: TaskItem) async throws {
        try db.collection("tasks").document(task.taskId).setData(from: task, merge: true)
    }

    func deleteTask(taskId: String) async throws {
        try await db.collection("tasks").document(taskId).updateData(["isActive": false])
    }

    // MARK: - Submissions

    func fetchSubmissions(for userId: String) async throws -> [TaskSubmission] {
        let snapshot = try await db.collection("taskSubmissions")
            .whereField("userId", isEqualTo: userId)
            .order(by: "submittedAt", descending: true)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: TaskSubmission.self) }
    }

    func fetchAllSubmissions() async throws -> [TaskSubmission] {
        let snapshot = try await db.collection("taskSubmissions")
            .order(by: "submittedAt", descending: true)
            .limit(to: 200)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: TaskSubmission.self) }
    }

    func fetchPendingSubmissions() async throws -> [TaskSubmission] {
        let snapshot = try await db.collection("taskSubmissions")
            .whereField("verificationStatus", isEqualTo: VerificationStatus.pendingReview.rawValue)
            .order(by: "submittedAt", descending: true)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: TaskSubmission.self) }
    }

    func submitTask(_ submission: TaskSubmission) async throws {
        try db.collection("taskSubmissions").document(submission.submissionId).setData(from: submission)
    }

    func updateSubmission(
        submissionId: String,
        status: VerificationStatus,
        comment: String?
    ) async throws {
        var data: [String: Any] = [
            "verificationStatus": status.rawValue,
            "verifiedAt": Timestamp(date: Date())
        ]
        if let comment, !comment.isEmpty {
            data["adminComment"] = comment
        }
        try await db.collection("taskSubmissions").document(submissionId).updateData(data)
    }

    // MARK: - Water Logs

    func fetchWaterLogs(for userId: String) async throws -> [WaterLog] {
        let snapshot = try await db.collection("waterLogs")
            .whereField("userId", isEqualTo: userId)
            .order(by: "uploadedAt", descending: true)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: WaterLog.self) }
    }

    func fetchTodayWaterLogs(for userId: String) async throws -> [WaterLog] {
        let logs = try await fetchWaterLogs(for: userId)
        return logs.filter { $0.uploadedAt >= Date().startOfDay }
    }

    func fetchPendingWaterLogs() async throws -> [WaterLog] {
        let snapshot = try await db.collection("waterLogs")
            .whereField("status", isEqualTo: VerificationStatus.pendingReview.rawValue)
            .order(by: "uploadedAt", descending: true)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: WaterLog.self) }
    }

    func submitWaterLog(_ log: WaterLog) async throws {
        try db.collection("waterLogs").document(log.logId).setData(from: log)
    }

    func updateWaterLog(
        logId: String,
        status: VerificationStatus,
        comment: String?
    ) async throws {
        var data: [String: Any] = [
            "status": status.rawValue,
            "verifiedAt": Timestamp(date: Date())
        ]
        if let comment, !comment.isEmpty {
            data["adminComment"] = comment
        }
        try await db.collection("waterLogs").document(logId).updateData(data)
    }

    // MARK: - Users

    func fetchAllMembers() async throws -> [UserProfile] {
        let snapshot = try await db.collection("users")
            .whereField("role", isEqualTo: UserRole.member.rawValue)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: UserProfile.self) }
    }

    func fetchUser(uid: String) async throws -> UserProfile? {
        let document = try await db.collection("users").document(uid).getDocument()
        return try? document.data(as: UserProfile.self)
    }

    func updateStreak(_ streak: Int, for uid: String) async throws {
        try await db.collection("users").document(uid).updateData([
            "streak": streak,
            "lastActiveDate": Timestamp(date: Date())
        ])
    }

    // MARK: - Daily Stats

    func fetchDailyStats(for userId: String) async throws -> DailyStats {
        let tasks = try await fetchTasks(for: userId)
        let submissions = try await fetchSubmissions(for: userId)
        let waterLogs = try await fetchTodayWaterLogs(for: userId)
        let today = Date().startOfDay

        let todaySubmissions = submissions.filter { $0.submittedAt >= today }
        let completedToday = todaySubmissions.filter { $0.verificationStatus != .rejected }.count
        let pendingTasksList = tasks.filter { task in
            !submissions.contains {
                $0.taskId == task.taskId && $0.submittedAt.isSameDay(as: Date())
            }
        }
        let totalTasks = tasks.count
        let completionRate = totalTasks > 0
            ? Double(completedToday) / Double(totalTasks) * 100 : 0

        return DailyStats(
            completionRate: completionRate,
            pendingTasks: pendingTasksList.count,
            completedToday: completedToday,
            waterCount: waterLogs.count,
            missedTasks: pendingTasksList.filter { $0.isOverdue }.count
        )
    }
}

struct DailyStats {
    var completionRate: Double
    var pendingTasks: Int
    var completedToday: Int
    var waterCount: Int
    var missedTasks: Int
}
