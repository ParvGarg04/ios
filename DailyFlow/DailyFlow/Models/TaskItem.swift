import Foundation
import FirebaseFirestore
import SwiftUI

enum TaskType: String, Codable, CaseIterable {
    case simple
    case proofRequired

    var displayName: String {
        switch self {
        case .simple: return "Simple Completion"
        case .proofRequired: return "Attachment Required"
        }
    }
}

enum TaskPriority: String, Codable, CaseIterable {
    case normal
    case important
    case urgent

    var displayName: String { rawValue.capitalized }

    var colorName: String {
        switch self {
        case .normal: return "PriorityNormal"
        case .important: return "PriorityImportant"
        case .urgent: return "PriorityUrgent"
        }
    }

    var icon: String {
        switch self {
        case .normal: return "circle"
        case .important: return "exclamationmark.circle.fill"
        case .urgent: return "exclamationmark.triangle.fill"
        }
    }
}

enum RepeatInterval: String, Codable, CaseIterable {
    case none
    case daily
    case weekly
    case hourly
    case custom

    var displayName: String {
        switch self {
        case .none: return "One-time"
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .hourly: return "Every Hour"
        case .custom: return "Custom"
        }
    }
}

struct TaskItem: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var taskId: String
    var userId: String
    var title: String
    var description: String
    var type: TaskType
    var dueTime: Date?
    var repeatInterval: RepeatInterval
    var customRepeatMinutes: Int?
    var priority: TaskPriority
    var requiresProof: Bool
    var isActive: Bool
    var createdAt: Date
    var assignedBy: String

    init(
        id: String? = nil,
        taskId: String = UUID().uuidString,
        userId: String,
        title: String,
        description: String = "",
        type: TaskType = .simple,
        dueTime: Date? = nil,
        repeatInterval: RepeatInterval = .none,
        customRepeatMinutes: Int? = nil,
        priority: TaskPriority = .normal,
        requiresProof: Bool = false,
        isActive: Bool = true,
        createdAt: Date = Date(),
        assignedBy: String
    ) {
        self.id = id
        self.taskId = taskId
        self.userId = userId
        self.title = title
        self.description = description
        self.type = type
        self.dueTime = dueTime
        self.repeatInterval = repeatInterval
        self.customRepeatMinutes = customRepeatMinutes
        self.priority = priority
        self.requiresProof = requiresProof
        self.isActive = isActive
        self.createdAt = createdAt
        self.assignedBy = assignedBy
    }

    var isOverdue: Bool {
        guard let dueTime else { return false }
        return dueTime < Date()
    }

    var isDueToday: Bool {
        guard let dueTime else { return true }
        return Calendar.current.isDateInToday(dueTime)
    }
}
