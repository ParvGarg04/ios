import Foundation
import FirebaseFirestore

struct WaterLog: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var logId: String
    var userId: String
    var imageURL: String?
    var note: String?
    var uploadedAt: Date
    var status: VerificationStatus
    var verifiedAt: Date?
    var adminComment: String?

    init(
        id: String? = nil,
        logId: String = UUID().uuidString,
        userId: String,
        imageURL: String? = nil,
        note: String? = nil,
        uploadedAt: Date = Date(),
        status: VerificationStatus = .pendingReview,
        verifiedAt: Date? = nil,
        adminComment: String? = nil
    ) {
        self.id = id
        self.logId = logId
        self.userId = userId
        self.imageURL = imageURL
        self.note = note
        self.uploadedAt = uploadedAt
        self.status = status
        self.verifiedAt = verifiedAt
        self.adminComment = adminComment
    }

    var formattedTime: String {
        uploadedAt.timeString
    }
}
