import SwiftUI

struct HydrationView: View {
    @StateObject private var viewModel = HydrationViewModel()
    @State private var showLogSheet      = false
    @State private var showImagePicker   = false
    @State private var showCamera        = false
    @State private var selectedImage: UIImage?
    @State private var noteText          = ""

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                AppTheme.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        hydrationHero
                        actionButtons
                        reminderWindowCard
                        if !viewModel.todayLogs.isEmpty {
                            todaySection
                        }
                        if viewModel.allLogs.count > viewModel.todayLogs.count {
                            historySection
                        }
                        if viewModel.allLogs.isEmpty && !viewModel.isLoading {
                            EmptyStateView(
                                icon: "drop",
                                title: "No logs yet",
                                message: "Tap 'Log Hydration' above to record your first update."
                            )
                        }
                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
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
            .navigationTitle("Hydration")
            .navigationBarTitleDisplayMode(.large)
            .refreshable { await viewModel.loadLogs() }
            .task { await viewModel.loadLogs() }
            .sheet(isPresented: $showLogSheet) { logSheet }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage)
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraPicker(image: $selectedImage)
            }
        }
    }

    // MARK: - Hero
    private var hydrationHero: some View {
        VStack(spacing: 18) {
            let filled = min(viewModel.todayCount, 12)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
                ForEach(0..<12) { i in
                    ZStack {
                        Circle()
                            .fill(i < filled ? AppTheme.accent.opacity(0.12) : AppTheme.softBorder.opacity(0.4))
                            .frame(width: 36, height: 36)
                        Image(systemName: "drop.fill")
                            .font(.body)
                            .foregroundStyle(
                                i < filled
                                ? AnyShapeStyle(LinearGradient(
                                    colors: [AppTheme.accent, AppTheme.lavender],
                                    startPoint: .top, endPoint: .bottom))
                                : AnyShapeStyle(AppTheme.softBorder)
                            )
                            .scaleEffect(i < filled ? 1.08 : 0.95)
                            .animation(.spring(response: 0.3).delay(Double(i) * 0.04), value: filled)
                    }
                }
            }
            .padding(.top, 4)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(viewModel.todayCount)")
                    .font(.system(size: 54, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textDark)
                Text("/ 12")
                    .font(.title2.weight(.medium))
                    .foregroundStyle(AppTheme.secondaryText)
            }

            VStack(spacing: 6) {
                Text("Hydration logs today")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.secondaryText)
                if let last = viewModel.lastLogTime {
                    Label("Last logged at \(last)", systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .cardStyle(elevated: true)
    }

    // MARK: - Action Buttons
    private var actionButtons: some View {
        HStack(spacing: 12) {
            // Quick log
            Button {
                Task { await viewModel.logWater() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Log Hydration")
                }
            }
            .buttonStyle(PrimaryButtonStyle(isLoading: viewModel.isSubmitting))
            .disabled(viewModel.isSubmitting)

            // With attachment
            Button { showLogSheet = true } label: {
                Image(systemName: "paperclip")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppTheme.accent)
                    .frame(width: 54, height: 54)
                    .background(AppTheme.lavender.opacity(0.15))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(AppTheme.softBorder, lineWidth: 1))
            }
        }
    }

    // MARK: - Reminder Window Info
    private var reminderWindowCard: some View {
        let hour = Calendar.current.component(.hour, from: Date())
        let active = hour >= 10 && hour < 22

        return HStack(spacing: 12) {
            Image(systemName: active ? "bell.fill" : "moon.fill")
                .foregroundStyle(active ? AppTheme.accent : AppTheme.secondaryText)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(active ? "Reminders active" : "Reminders paused")
                    .font(.subheadline.weight(.medium))
                Text(active ? "Running 10:00 AM – 10:00 PM daily"
                            : "Reminders resume at 10:00 AM")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
            }
            Spacer()
            Circle()
                .fill(active ? AppTheme.success : AppTheme.secondaryText.opacity(0.4))
                .frame(width: 8, height: 8)
        }
        .padding(16)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.softBorder, lineWidth: 1)
        )
    }

    // MARK: - Today Section
    private var todaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Log")
                .font(.headline)
            ForEach(viewModel.todayLogs) { log in
                WaterLogRowView(log: log)
            }
        }
    }

    // MARK: - History Section
    private var historySection: some View {
        let past = viewModel.allLogs.filter { !$0.uploadedAt.isSameDay(as: Date()) }
        return VStack(alignment: .leading, spacing: 12) {
            Text("Earlier")
                .font(.headline)
            ForEach(past.prefix(15)) { log in
                WaterLogRowView(log: log)
            }
        }
    }

    // MARK: - Log Sheet (with attachment + note)
    private var logSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Image area
                    if let img = selectedImage {
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 200)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            Button { selectedImage = nil } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.white)
                                    .shadow(radius: 4)
                                    .padding(10)
                            }
                        }
                    } else {
                        photoPickerButton
                    }

                    // Note
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Note (optional)")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AppTheme.secondaryText)
                        TextField("e.g. Drank 2 glasses of water", text: $noteText, axis: .vertical)
                            .lineLimit(3...5)
                            .textFieldStyle(DailyFlowTextFieldStyle())
                    }

                    Button {
                        Task {
                            if let img = selectedImage {
                                await viewModel.logWaterWithImage(
                                    image: img,
                                    note: noteText.isBlank ? nil : noteText
                                )
                            } else {
                                await viewModel.logWater(note: noteText.isBlank ? nil : noteText)
                            }
                            if viewModel.successMessage != nil {
                                noteText = ""; selectedImage = nil
                                showLogSheet = false
                            }
                        }
                    } label: {
                        Text("Submit Update")
                    }
                    .buttonStyle(PrimaryButtonStyle(isLoading: viewModel.isSubmitting))
                    .disabled(viewModel.isSubmitting)
                }
                .padding(20)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Submit Update")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        noteText = ""; selectedImage = nil; showLogSheet = false
                    }
                }
            }
            .sheet(isPresented: $showImagePicker) { ImagePicker(image: $selectedImage) }
            .fullScreenCover(isPresented: $showCamera) { CameraPicker(image: $selectedImage) }
        }
        .presentationDetents([.medium, .large])
    }

    private var photoPickerButton: some View {
        Menu {
            Button {
                showCamera = true
            } label: {
                Label("Take Photo", systemImage: "camera")
            }
            Button {
                showImagePicker = true
            } label: {
                Label("Choose from Library", systemImage: "photo")
            }
        } label: {
            VStack(spacing: 12) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(AppTheme.accent)
                Text("Add Attachment")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
                Text("Optional — tap to add a photo")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 130)
            .background(AppTheme.accent.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(AppTheme.accent.opacity(0.3), style: StrokeStyle(lineWidth: 1.5, dash: [6]))
            )
        }
    }
}

// MARK: - Water Log Row
struct WaterLogRowView: View {
    let log: WaterLog

    var body: some View {
        HStack(spacing: 14) {
            // Thumbnail or icon
            if let urlStr = log.imageURL, let url = URL(string: urlStr) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().scaledToFill()
                            .frame(width: 48, height: 48)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    default:
                        dropIcon
                    }
                }
            } else {
                dropIcon
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(log.uploadedAt.relativeString)
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    StatusBadge(status: log.status)
                }
                if let note = log.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                        .lineLimit(1)
                }
                if let comment = log.adminComment, !comment.isEmpty {
                    Label(comment, systemImage: "bubble.left")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
        }
        .padding(16)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.softBorder, lineWidth: 1)
        )
        .shadow(color: AppTheme.cardShadow, radius: 6, y: 2)
    }

    private var dropIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(AppTheme.lavender.opacity(0.15))
                .frame(width: 48, height: 48)
            Image(systemName: "drop.fill")
                .font(.title3)
                .foregroundStyle(AppTheme.accent)
        }
    }
}
