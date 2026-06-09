import SwiftUI

struct TasksView: View {
    @StateObject private var viewModel = TasksViewModel()
    @State private var selectedSegment = 0
    @State private var selectedTask: TaskItem?
    @State private var showCompletionSheet = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                AppTheme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    segmentBar

                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 14) {
                            if currentTasks.isEmpty && !viewModel.isLoading {
                                EmptyStateView(
                                    icon: emptyIcon,
                                    title: emptyTitle,
                                    message: emptyMessage
                                )
                                .padding(.top, 40)
                            } else {
                                ForEach(currentTasks) { task in
                                    ImprovedTaskCard(task: task, viewModel: viewModel) {
                                        selectedTask = task
                                        showCompletionSheet = true
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .padding(.bottom, 20)
                    }
                }

                // Toast
                if viewModel.showToast {
                    ToastBanner(
                        message: viewModel.successMessage ?? viewModel.errorMessage ?? "",
                        isSuccess: viewModel.toastSuccess
                    )
                    .padding(.bottom, 90)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle("Tasks")
            .navigationBarTitleDisplayMode(.large)
            .refreshable { await viewModel.loadTasks() }
            .task { await viewModel.loadTasks() }
            .sheet(isPresented: $showCompletionSheet, onDismiss: {
                Task { await viewModel.loadTasks() }
            }) {
                if let task = selectedTask {
                    TaskCompletionSheet(task: task, viewModel: viewModel)
                }
            }
        }
    }

    // MARK: - Segment Bar
    private var segmentBar: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { index in
                Button {
                    withAnimation(.spring(response: 0.3)) { selectedSegment = index }
                } label: {
                    Text(["Pending", "Completed", "Missed"][index])
                        .font(.subheadline.weight(selectedSegment == index ? .semibold : .medium))
                        .foregroundStyle(selectedSegment == index ? .white : AppTheme.secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(
                            Capsule(style: .continuous)
                                .fill(selectedSegment == index ? AnyShapeStyle(AppTheme.gradient) : AnyShapeStyle(AppTheme.cardBackground))
                        )
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(selectedSegment == index ? Color.clear : AppTheme.softBorder, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(AppTheme.background)
    }

    private var currentTasks: [TaskItem] {
        switch selectedSegment {
        case 0: return viewModel.pendingTasks
        case 1: return viewModel.completedTasks
        default: return viewModel.missedTasks
        }
    }

    private var emptyIcon: String {
        ["tray.fill", "checkmark.circle", "exclamationmark.circle"][selectedSegment]
    }
    private var emptyTitle: String {
        ["No pending tasks", "No completed tasks", "No missed tasks"][selectedSegment]
    }
    private var emptyMessage: String {
        [
            "You're all caught up! New tasks will appear here.",
            "Complete tasks to see them here.",
            "Great job staying on schedule!"
        ][selectedSegment]
    }
}

// MARK: - Improved Task Card
struct ImprovedTaskCard: View {
    let task: TaskItem
    @ObservedObject var viewModel: TasksViewModel
    let onTap: () -> Void

    private var submission: TaskSubmission? { viewModel.todaySubmission(for: task.taskId) }
    private var isCompleted: Bool { submission != nil && submission?.verificationStatus != .rejected }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main row
            HStack(spacing: 14) {
                // Priority / type icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isCompleted
                              ? AppTheme.success.opacity(0.12)
                              : task.priority.color.opacity(0.12))
                        .frame(width: 46, height: 46)
                    Image(systemName: isCompleted ? "checkmark" :
                          (task.requiresProof ? "paperclip" : task.priority.icon))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(isCompleted ? AppTheme.success : task.priority.color)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(task.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .strikethrough(isCompleted, color: AppTheme.secondaryText)

                    if !task.description.isEmpty {
                        Text(task.description)
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText)
                            .lineLimit(2)
                    }

                    HStack(spacing: 10) {
                        if let due = task.dueTime {
                            Label(due.timeString, systemImage: "clock")
                                .font(.caption)
                                .foregroundStyle(
                                    task.isOverdue && !isCompleted
                                    ? AppTheme.danger : AppTheme.secondaryText
                                )
                        }
                        if task.requiresProof {
                            Label("Attachment", systemImage: "photo")
                                .font(.caption)
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                        if task.repeatInterval != .none {
                            Label(task.repeatInterval.displayName, systemImage: "repeat")
                                .font(.caption)
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                    }
                }

                Spacer()

                PriorityBadge(priority: task.priority)
            }
            .padding(16)

            // Submission status strip
            if let sub = submission {
                Divider().padding(.horizontal, 16)
                HStack(spacing: 8) {
                    StatusBadge(status: sub.verificationStatus)
                    if let comment = sub.adminComment, !comment.isEmpty {
                        Text("· \(comment)")
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText)
                            .lineLimit(1)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }

            // Action button if not completed
            if !isCompleted {
                Divider().padding(.horizontal, 16)
                Button(action: onTap) {
                    HStack(spacing: 8) {
                        Image(systemName: task.requiresProof ? "camera.fill" : "checkmark.circle.fill")
                        Text(task.requiresProof ? "Upload Attachment" : "Mark Complete")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                }
            }
        }
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous)
                .stroke(AppTheme.softBorder, lineWidth: 1)
        )
        .shadow(color: AppTheme.cardShadow, radius: 8, y: 3)
        .opacity(isCompleted ? 0.78 : 1)
    }
}

// MARK: - Task Completion Sheet
struct TaskCompletionSheet: View {
    let task: TaskItem
    @ObservedObject var viewModel: TasksViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var note          = ""
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var showCamera    = false
    @State private var showAttachError = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Task info header
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(task.priority.color.opacity(0.12))
                                .frame(width: 46, height: 46)
                            Image(systemName: task.priority.icon)
                                .font(.system(size: 18))
                                .foregroundStyle(task.priority.color)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(task.title)
                                .font(.headline)
                            if !task.description.isEmpty {
                                Text(task.description)
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.secondaryText)
                            }
                        }
                        Spacer()
                        PriorityBadge(priority: task.priority)
                    }
                    .cardStyle()

                    // Attachment section
                    if task.requiresProof {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 4) {
                                Text("Attachment")
                                    .font(.subheadline.weight(.semibold))
                                Text("(Required)")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.danger)
                            }

                            if let img = selectedImage {
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 180)
                                        .clipped()
                                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    Button { selectedImage = nil } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.title2)
                                            .foregroundStyle(.white)
                                            .shadow(radius: 4)
                                            .padding(10)
                                    }
                                }
                            } else {
                                HStack(spacing: 12) {
                                    Button { showCamera = true } label: {
                                        HStack {
                                            Image(systemName: "camera.fill")
                                            Text("Camera")
                                        }
                                    }
                                    .buttonStyle(SecondaryButtonStyle())

                                    Button { showImagePicker = true } label: {
                                        HStack {
                                            Image(systemName: "photo")
                                            Text("Library")
                                        }
                                    }
                                    .buttonStyle(SecondaryButtonStyle())
                                }
                            }

                            if showAttachError {
                                Label("An attachment is required.", systemImage: "exclamationmark.triangle")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.danger)
                            }
                        }
                    } else {
                        // Optional attachment for simple tasks
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Attachment (optional)")
                                .font(.subheadline.weight(.semibold))

                            if let img = selectedImage {
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 150)
                                        .clipped()
                                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    Button { selectedImage = nil } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.title2)
                                            .foregroundStyle(.white)
                                            .shadow(radius: 4)
                                            .padding(10)
                                    }
                                }
                            } else {
                                Button {
                                    showImagePicker = true
                                } label: {
                                    Label("Add Photo", systemImage: "camera")
                                        .font(.subheadline)
                                        .foregroundStyle(AppTheme.accent)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(AppTheme.accent.opacity(0.08))
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                }
                            }
                        }
                    }

                    // Note
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Note (optional)")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AppTheme.secondaryText)
                        TextField("Add a note about this task...", text: $note, axis: .vertical)
                            .lineLimit(3...6)
                            .textFieldStyle(DailyFlowTextFieldStyle())
                    }

                    // Error from ViewModel
                    if let err = viewModel.errorMessage {
                        Label(err, systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(AppTheme.danger)
                            .padding(12)
                            .background(AppTheme.danger.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }

                    Button {
                        Task { await handleSubmit() }
                    } label: {
                        if viewModel.isSubmitting {
                            ProgressView().tint(.white)
                        } else {
                            Text(task.requiresProof ? "Submit Update" : "Mark Completed")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(viewModel.isSubmitting)
                }
                .padding(20)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Complete Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showImagePicker) { ImagePicker(image: $selectedImage) }
            .fullScreenCover(isPresented: $showCamera) { CameraPicker(image: $selectedImage) }
        }
        .presentationDetents([.medium, .large])
    }

    private func handleSubmit() async {
        showAttachError = false
        if task.requiresProof && selectedImage == nil {
            showAttachError = true
            return
        }
        await viewModel.completeTask(
            task,
            image: selectedImage,
            note: note.isBlank ? nil : note
        )
        if viewModel.successMessage != nil {
            dismiss()
        }
    }
}
