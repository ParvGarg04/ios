import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        heroCard
                        progressRow
                        statsRow
                        nextReminderCard
                        if !viewModel.pendingTasks.isEmpty {
                            pendingSection
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 28)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(AppTheme.accent)
                        Text("DailyFlow")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.textDark)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: ProfileView()) {
                        avatarView
                    }
                }
            }
            .refreshable { await viewModel.loadData() }
            .task { await viewModel.loadData() }
        }
    }

    // MARK: - Hero Card
    private var heroCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(AppTheme.gradient)
                .shadow(color: AppTheme.accent.opacity(0.35), radius: 18, y: 8)

            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(greeting)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white.opacity(0.85))
                        Text(authViewModel.currentUser?.name
                             .components(separatedBy: " ").first ?? "Member")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    streakBadge
                }

                Rectangle()
                    .fill(.white.opacity(0.22))
                    .frame(height: 1)

                HStack(spacing: 0) {
                    heroStat(
                        value: "\(viewModel.stats.completedToday)",
                        label: "Done",
                        icon: "checkmark.circle.fill"
                    )
                    heroStat(
                        value: "\(viewModel.stats.waterCount)",
                        label: "Hydration",
                        icon: "drop.fill"
                    )
                    heroStat(
                        value: "\(viewModel.stats.pendingTasks)",
                        label: "Pending",
                        icon: "bell.fill"
                    )
                }
            }
            .padding(22)
        }
    }

    private func heroStat(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.white.opacity(0.78))
        }
        .frame(maxWidth: .infinity)
    }

    private var streakBadge: some View {
        VStack(spacing: 3) {
            Image(systemName: "heart.fill")
                .font(.title3)
                .foregroundStyle(.white.opacity(0.9))
            Text("\(viewModel.streak)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text("streak")
                .font(.caption2.weight(.medium))
                .foregroundStyle(.white.opacity(0.78))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.white.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Progress Ring Row
    private var progressRow: some View {
        HStack(spacing: 14) {
            VStack(spacing: 12) {
                ProgressRing(progress: viewModel.stats.completionRate, size: 76)
                Text("Completion")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .cardStyle()

            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .stroke(AppTheme.softBorder.opacity(0.5), lineWidth: 8)
                    Circle()
                        .trim(from: 0, to: min(Double(viewModel.stats.waterCount) / 12.0, 1.0))
                        .stroke(
                            LinearGradient(
                                colors: [AppTheme.accent, AppTheme.lavender],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.6), value: viewModel.stats.waterCount)
                    VStack(spacing: 2) {
                        Image(systemName: "drop.fill")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.accent)
                        Text("\(viewModel.stats.waterCount)")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.textDark)
                        Text("/12")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                }
                .frame(width: 76, height: 76)
                Text("Hydration")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .cardStyle()
        }
    }

    // MARK: - Stats Grid
    private var statsRow: some View {
        HStack(spacing: 14) {
            miniStatCard(
                title: "Missed",
                value: "\(viewModel.stats.missedTasks)",
                icon: "exclamationmark.circle.fill",
                color: viewModel.stats.missedTasks > 0 ? AppTheme.danger : AppTheme.success
            )
            miniStatCard(
                title: "Weekly Rate",
                value: "\(Int(viewModel.stats.completionRate))%",
                icon: "chart.line.uptrend.xyaxis",
                color: AppTheme.accent
            )
        }
    }

    private func miniStatCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 17))
                .foregroundStyle(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textDark)
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    // MARK: - Next Reminder
    private var nextReminderCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppTheme.lavender.opacity(0.2))
                    .frame(width: 48, height: 48)
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(AppTheme.accent)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Next Reminder")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppTheme.secondaryText)
                Text(viewModel.nextReminderText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textDark)
            }
            Spacer()
        }
        .cardStyle()
    }

    // MARK: - Pending Tasks Preview
    private var pendingSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Pending Today", systemImage: "checkmark.circle")
                    .font(.headline)
                    .foregroundStyle(AppTheme.textDark)
                Spacer()
                Text("\(viewModel.pendingTasks.count) tasks")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppTheme.secondaryText)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(AppTheme.softBorder.opacity(0.5))
                    .clipShape(Capsule())
            }

            ForEach(viewModel.pendingTasks.prefix(4)) { task in
                HomePendingRow(task: task)
            }

            if viewModel.pendingTasks.count > 4 {
                Text("+\(viewModel.pendingTasks.count - 4) more in Tasks tab")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppTheme.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 4)
            }
        }
    }

    // MARK: - Avatar
    private var avatarView: some View {
        ZStack {
            Circle()
                .fill(AppTheme.gradient)
                .frame(width: 36, height: 36)
            Text(initials)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
        }
    }

    private var initials: String {
        let name = authViewModel.currentUser?.name ?? "M"
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return "Good morning ✨"
        case 12..<17: return "Good afternoon"
        default:      return "Good evening"
        }
    }
}

// MARK: - Pending Row (Home)
private struct HomePendingRow: View {
    let task: TaskItem

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: task.priority.icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(task.priority.color)
                .frame(width: 36, height: 36)
                .background(task.priority.color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(task.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.textDark)
                if let due = task.dueTime {
                    Label(due.timeString, systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(task.isOverdue ? AppTheme.danger : AppTheme.secondaryText)
                }
            }

            Spacer()

            if task.requiresProof {
                Image(systemName: "paperclip")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
        .padding(14)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.softBorder, lineWidth: 1)
        )
    }
}
