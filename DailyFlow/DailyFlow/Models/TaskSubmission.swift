import Foundation
import FirebaseFirestore

enum VerificationStatus: String, Codable, CaseIterable {
    case pendingReview = "pending_review"
    case verified
    case rejected

    var displayName: String {
        switch self {
        case .pendingReview: return "Pending Review"
        case .verified: return "Verified"
        case .rejected: return "Rejected"
        }
    }

    var icon: String {
        switch self {
        case .pendingReview: return "clock.fill"
        case .verified: return "checkmark.seal.fill"
        case .rejected: return "xmark.seal.fill"
        }
    }
}

struct TaskSubmission: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var submissionId: String
    var taskId: String
    var userId: String
    var taskTitle: String
    var imageURL: String?
    var note: String?
    var submittedAt: Date
    var verificationStatus: VerificationStatus
    var adminComment: String?
    var verifiedAt: Date?

    init(
        id: String? = nil,
        submissionId: String = UUID().uuidString,
        taskId: String,
        userId: String,
        taskTitle: String,
        imageURL: String? = nil,
        note: String? = nil,
        submittedAt: Date = Date(),
        verificationStatus: VerificationStatus = .pendingReview,
        adminComment: String? = nil,
        verifiedAt: Date? = nil
    ) {
        self.id = id
        self.submissionId = submissionId
        self.taskId = taskId
        self.userId = userId
        self.taskTitle = taskTitle
        self.imageURL = imageURL
        self.note = note
        self.submittedAt = submittedAt
        self.verificationStatus = verificationStatus
        self.adminComment = adminComment
        self.verifiedAt = verifiedAt
    }
}
