import Foundation
import FirebaseFirestore

enum UserRole: String, Codable {
    case member = "member"
    case admin  = "admin"
}

struct UserProfile: Identifiable, Codable {
    @DocumentID var id: String?
    var name:              String
    var email:             String
    var role:              UserRole
    var streak:            Int
    var lastActiveDate:    Date?
    var createdAt:         Date
    var notificationsEnabled: Bool

    var isAdmin: Bool { role == .admin }

    var initials: String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
}
