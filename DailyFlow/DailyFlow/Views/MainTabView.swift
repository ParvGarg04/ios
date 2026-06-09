import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedTab = 0

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 1.0, green: 0.969, blue: 0.984, alpha: 0.95)
        appearance.shadowColor = UIColor(red: 0.85, green: 0.65, blue: 0.75, alpha: 0.15)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem { Label("Today", systemImage: "sparkles") }
                .tag(0)

            HydrationView()
                .tabItem { Label("Hydration", systemImage: "drop.fill") }
                .tag(1)

            TasksView()
                .tabItem { Label("Tasks", systemImage: "checkmark.circle.fill") }
                .tag(2)

            HistoryView()
                .tabItem { Label("History", systemImage: "calendar") }
                .tag(3)

            ProfileView()
                .tabItem { Label("Profile", systemImage: "heart.fill") }
                .tag(4)
        }
        .tint(AppTheme.accent)
        .task { await requestNotifications() }
    }

    private func requestNotifications() async {
        let granted = await NotificationService.shared.requestPermission()
        if granted {
            await NotificationService.shared.scheduleWaterReminders()
        }
    }
}
