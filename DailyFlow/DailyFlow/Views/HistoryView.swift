import SwiftUI

struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(HistoryViewModel.HistoryFilter.allCases, id: \.self) { filter in
                            FilterChip(
                                title: filter.rawValue,
                                isSelected: viewModel.selectedFilter == filter
                            ) {
                                withAnimation(.spring(response: 0.3)) {
                                    viewModel.selectedFilter = filter
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
                .background(AppTheme.background)
                .overlay(
                    Rectangle()
                        .fill(AppTheme.softBorder.opacity(0.6))
                        .frame(height: 1),
                    alignment: .bottom
                )

                if viewModel.isLoading {
                    Spacer()
                    ProgressView("Loading history…")
                    Spacer()
                } else if viewModel.isEmpty {
                    Spacer()
                    EmptyStateView(
                        icon: "clock.arrow.circlepath",
                        title: "No history yet",
                        message: "Your completed tasks and hydration logs will appear here."
                    )
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                            ForEach(viewModel.groupedTimeline, id: \.0) { (day, entries) in
                                Section(header: daySectionHeader(day)) {
                                    ForEach(entries) { entry in
                                        TimelineEntryRow(entry: entry)
                                    }
                                }
                            }
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .refreshable { await viewModel.loadHistory() }
            .task { await viewModel.loadHistory() }
        }
    }

    private func daySectionHeader(_ label: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "calendar")
                .font(.caption2)
                .foregroundStyle(AppTheme.accent)
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.secondaryText)
        }
        .textCase(nil)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(AppTheme.background)
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 18)
                .padding(.vertical, 9)
                .background(
                    Capsule(style: .continuous)
                        .fill(isSelected ? AnyShapeStyle(AppTheme.gradient) : AnyShapeStyle(AppTheme.cardBackground))
                )
                .foregroundStyle(isSelected ? .white : AppTheme.textDark)
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(isSelected ? Color.clear : AppTheme.softBorder, lineWidth: 1)
                )
                .shadow(color: isSelected ? AppTheme.accent.opacity(0.2) : AppTheme.cardShadow, radius: 6, y: 2)
        }
    }
}

// MARK: - Timeline Entry Row
struct TimelineEntryRow: View {
    let entry: HistoryViewModel.TimelineEntry
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.35)) { isExpanded.toggle() }
            } label: {
                HStack(spacing: 14) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(entry.typeColor.opacity(0.12))
                            .frame(width: 40, height: 40)
                        Image(systemName: entry.typeIcon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(entry.typeColor)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(entry.title)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                        if let sub = entry.subtitle, !sub.isEmpty {
                            Text(sub)
                                .font(.caption)
                                .foregroundStyle(AppTheme.secondaryText)
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(entry.date.timeString)
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText)
                        StatusBadge(status: entry.status)
                    }

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.secondaryText)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 13)
            }
            .buttonStyle(.plain)

            // Expanded detail
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    if let urlStr = entry.imageURL, let url = URL(string: urlStr) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let img):
                                img.resizable()
                                    .scaledToFill()
                                    .frame(maxHeight: 200)
                                    .clipped()
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            case .failure:
                                Label("Could not load image", systemImage: "photo.badge.exclamationmark")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.secondaryText)
                            default:
                                ProgressView().frame(height: 80)
                            }
                        }
                    }

                    if let comment = entry.adminComment, !comment.isEmpty {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "bubble.left.fill")
                                .font(.caption)
                                .foregroundStyle(AppTheme.accent)
                            Text("Reviewer: \(comment)")
                                .font(.caption)
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                        .padding(10)
                        .background(AppTheme.accent.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 14)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Divider().padding(.leading, 74).background(AppTheme.softBorder.opacity(0.5))
        }
    }
}
