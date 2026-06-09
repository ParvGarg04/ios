import SwiftUI
import Firebase

@main
struct DailyFlowApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var themeManager  = ThemeManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authViewModel)
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.colorScheme)
        }
    }
}

// MARK: - AppDelegate
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        NotificationService.shared.registerCategories()
        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Reschedule water reminders if they've been lost (e.g. reinstall)
        Task {
            let status = await NotificationService.shared.checkPermissionStatus()
            if status == .authorized {
                await NotificationService.shared.scheduleWaterReminders()
            }
        }
        // Clear badge count
        UNUserNotificationCenter.current().setBadgeCount(0)
    }
}
