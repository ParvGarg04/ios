import Foundation
import SwiftUI

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published var submissions:     [TaskSubmission] = []
    @Published var waterLogs:       [WaterLog]       = []
    @Published var isLoading        = false
    @Published var selectedFilter: HistoryFilter = .all

    private let firestore = FirestoreService.shared
    private let auth      = AuthService.shared

    enum HistoryFilter: String, CaseIterable {
        case all           = "All"
        case pending       = "Pending"
        case verified      = "Verified"
        case rejected      = "Rejected"
        case hydration     = "Hydration"
        case tasks         = "Tasks"
    }

    // MARK: - Timeline Entry
    struct TimelineEntry: Identifiable {
        let id:           String
        let title:        String
        let subtitle:     String?
        let date:         Date
        let status:       VerificationStatus
        let imageURL:     String?
        let adminComment: String?
        let kind:         Kind

        enum Kind { case task, water }

        var typeIcon: String {
            kind == .water ? "drop.fill" : "checkmark.circle.fill"
        }
        var typeColor: Color {
            kind == .water ? .blue : Color("AccentColor")
        }
    }

    // MARK: - Filtered timeline
    var filteredTimeline: [TimelineEntry] {
        var entries: [TimelineEntry] = []

        let includeWater = selectedFilter == .all || selectedFilter == .hydration
        let includeTasks = selectedFilter == .all || selectedFilter == .tasks ||
                           selectedFilter == .pending || selectedFilter == .verified ||
                           selectedFilter == .rejected

        if includeTasks {
            let filtered: [TaskSubmission]
            switch selectedFilter {
            case .pending:  filtered = submissions.filter { $0.verificationStatus == .pendingReview }
            case .verified: filtered = submissions.filter { $0.verificationStatus == .verified }
            case .rejected: filtered = submissions.filter { $0.verificationStatus == .rejected }
            default:        filtered = submissions
            }
            for s in filtered {
                entries.append(TimelineEntry(
                    id: "task_\(s.submissionId)",
                    title: s.taskTitle,
                    subtitle: s.note,
                    date: s.submittedAt,
                    status: s.verificationStatus,
                    imageURL: s.imageURL,
                    adminComment: s.adminComment,
                    kind: .task
                ))
            }
        }

        if includeWater {
            for log in waterLogs {
                entries.append(TimelineEntry(
                    id: "water_\(log.logId)",
                    title: "Hydration Log",
                    subtitle: log.note,
                    date: log.uploadedAt,
                    status: log.status,
                    imageURL: log.imageURL,
                    adminComment: log.adminComment,
                    kind: .water
                ))
            }
        }

        return entries.sorted { $0.date > $1.date }
    }

    // Grouped by day label
    var groupedTimeline: [(String, [TimelineEntry])] {
        var groups: [String: [TimelineEntry]] = [:]
        for entry in filteredTimeline {
            let label = entry.date.dayLabel
            groups[label, default: []].append(entry)
        }
        return groups
            .sorted { a, b in
                let aDate = a.value.first!.date
                let bDate = b.value.first!.date
                return aDate > bDate
            }
    }

    var isEmpty: Bool { filteredTimeline.isEmpty }

    // MARK: - Load
    func loadHistory() async {
        guard let userId = auth.currentUser?.uid else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            submissions = try await firestore.fetchSubmissions(for: userId)
            waterLogs   = try await firestore.fetchWaterLogs(for: userId)
        } catch {
            print("History load error: \(error)")
        }
    }
}
