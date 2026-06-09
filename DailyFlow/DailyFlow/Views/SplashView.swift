import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            SoftBackgroundDecoration()
            VStack(spacing: 22) {
                ZStack {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(AppTheme.gradient)
                        .frame(width: 88, height: 88)
                        .shadow(color: AppTheme.accent.opacity(0.35), radius: 20, y: 10)
                    Image(systemName: "sparkles")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundStyle(.white)
                }
                Text("DailyFlow")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textDark)
                ProgressView()
                    .tint(AppTheme.accent)
                    .padding(.top, 12)
            }
        }
    }
}

// MARK: - Root routing view
struct RootView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        Group {
            if authViewModel.isLoading {
                SplashView()
            } else if authViewModel.currentUser == nil {
                LoginView()
            } else {
                MainTabView()
            }
        }
        .animation(.easeInOut(duration: 0.25), value: authViewModel.isLoading)
        .animation(.easeInOut(duration: 0.25), value: authViewModel.currentUser == nil)
    }
}
