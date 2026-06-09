import SwiftUI

// MARK: - Status Badge
struct StatusBadge: View {
    let status: VerificationStatus

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.icon)
                .font(.system(size: 9, weight: .bold))
            Text(status.displayName)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(status.color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(status.color.opacity(0.12))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(status.color.opacity(0.2), lineWidth: 0.5)
        )
    }
}

// MARK: - Priority Badge
struct PriorityBadge: View {
    let priority: TaskPriority

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: priority.icon)
                .font(.system(size: 9, weight: .bold))
            Text(priority.displayName)
                .font(.caption2.weight(.bold))
        }
        .foregroundStyle(priority.color)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(priority.color.opacity(0.12))
        .clipShape(Capsule())
    }
}

// MARK: - Progress Ring
struct ProgressRing: View {
    let progress: Double   // 0 – 100
    let size: CGFloat
    var lineWidth: CGFloat = 8
    var color: Color = Color("AccentColor")

    var body: some View {
        ZStack {
            Circle()
                .stroke(AppTheme.softBorder.opacity(0.6), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(progress / 100, 1))
                .stroke(
                    AppTheme.gradient,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.7, dampingFraction: 0.75), value: progress)

            VStack(spacing: 2) {
                Text("\(Int(progress))%")
                    .font(.system(size: size * 0.22, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textDark)
                Text("Today")
                    .font(.system(size: size * 0.13))
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Empty State
struct EmptyStateView: View {
    let icon:    String
    let title:   String
    let message: String

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(AppTheme.lavender.opacity(0.15))
                    .frame(width: 88, height: 88)
                Image(systemName: icon)
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(AppTheme.accent.opacity(0.7))
            }
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(AppTheme.textDark)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }
        }
        .padding(36)
        .frame(maxWidth: .infinity)
    }
}
