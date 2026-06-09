import Foundation
import SwiftUI

// MARK: - Date Extensions
extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay) ?? self
    }

    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }

    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: self)
    }

    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }

    var dateTimeString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }

    var relativeString: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(self) {
            return "Today, \(timeString)"
        } else if calendar.isDateInYesterday(self) {
            return "Yesterday, \(timeString)"
        } else {
            return dateTimeString
        }
    }

    var dayLabel: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(self) { return "Today" }
        if calendar.isDateInYesterday(self) { return "Yesterday" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: self)
    }
}

// MARK: - String Extensions
extension String {
    var isValidEmail: Bool {
        let pattern = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return range(of: pattern, options: .regularExpression) != nil
    }

    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
    var isBlank: Bool { trimmed.isEmpty }
}

// MARK: - Color Extensions
extension VerificationStatus {
    var color: Color {
        switch self {
        case .pendingReview: return AppTheme.warning
        case .verified: return AppTheme.success
        case .rejected: return AppTheme.danger
        }
    }
}

extension TaskPriority {
    var color: Color {
        switch self {
        case .normal: return Color("PriorityNormal")
        case .important: return Color("PriorityImportant")
        case .urgent: return Color("PriorityUrgent")
        }
    }
}

// MARK: - View Extensions
extension View {
    func toast(message: String, isPresented: Binding<Bool>, isSuccess: Bool = true) -> some View {
        self.overlay(
            Group {
                if isPresented.wrappedValue {
                    VStack {
                        Spacer()
                        ToastBanner(message: message, isSuccess: isSuccess)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .padding(.bottom, 90)
                    }
                }
            }
            .animation(.spring(response: 0.35), value: isPresented.wrappedValue)
        )
    }
}
