import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var currentUser:  UserProfile?
    @Published var isLoading     = true
    @Published var isProcessing  = false
    @Published var errorMessage: String?

    private var authStateHandle: AuthStateDidChangeListenerHandle?
    private let db   = Firestore.firestore()
    private let auth = AuthService.shared

    init() { listenToAuthState() }

    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    // MARK: - Auth Listener
    private func listenToAuthState() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            Task { @MainActor in
                if let user {
                    await self.fetchProfile(uid: user.uid)
                } else {
                    self.currentUser = nil
                    self.isLoading   = false
                }
            }
        }
    }

    // MARK: - Fetch Profile
    func fetchProfile(uid: String) async {
        do {
            let snap = try await db.collection("users").document(uid).getDocument()
            if let profile = try? snap.data(as: UserProfile.self) {
                currentUser = profile
            } else if let fireUser = Auth.auth().currentUser {
                // First-time: create profile
                let profile = UserProfile(
                    id: uid,
                    name: fireUser.displayName ?? "Member",
                    email: fireUser.email ?? "",
                    role: .member,
                    streak: 0,
                    lastActiveDate: nil,
                    createdAt: Date(),
                    notificationsEnabled: true
                )
                try db.collection("users").document(uid).setData(from: profile)
                currentUser = profile
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Sign In
    func signIn(email: String, password: String) async {
        isProcessing  = true
        errorMessage  = nil
        defer { isProcessing = false }
        do {
            try await auth.signIn(email: email, password: password)
        } catch {
            errorMessage = friendlyError(error)
        }
    }

    // MARK: - Sign Up
    func signUp(name: String, email: String, password: String) async {
        isProcessing = true
        errorMessage = nil
        defer { isProcessing = false }
        do {
            let uid = try await auth.signUp(name: name, email: email, password: password)
            let profile = UserProfile(
                id: uid, name: name, email: email, role: .member,
                streak: 0, lastActiveDate: nil, createdAt: Date(), notificationsEnabled: true
            )
            try db.collection("users").document(uid).setData(from: profile)
            currentUser = profile
        } catch {
            errorMessage = friendlyError(error)
        }
    }

    // MARK: - Sign Out
    func signOut() {
        try? auth.signOut()
        NotificationService.shared.cancelAllNotifications()
        currentUser = nil
    }

    // MARK: - Reset Password
    func resetPassword(email: String) async -> Bool {
        do {
            try await auth.resetPassword(email: email)
            return true
        } catch {
            errorMessage = friendlyError(error)
            return false
        }
    }

    // MARK: - Delete Account
    func deleteAccount() async {
        guard let uid = auth.currentUserId else { return }
        do {
            try await db.collection("users").document(uid).delete()
            try await auth.deleteAccount()
            currentUser = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Error messages
    private func friendlyError(_ error: Error) -> String {
        let code = (error as NSError).code
        switch code {
        case AuthErrorCode.wrongPassword.rawValue,
             AuthErrorCode.invalidCredential.rawValue:
            return "Incorrect email or password."
        case AuthErrorCode.invalidEmail.rawValue:
            return "Please enter a valid email address."
        case AuthErrorCode.userNotFound.rawValue:
            return "No account found with this email."
        case AuthErrorCode.emailAlreadyInUse.rawValue:
            return "An account with this email already exists."
        case AuthErrorCode.weakPassword.rawValue:
            return "Password must be at least 6 characters."
        case AuthErrorCode.networkError.rawValue:
            return "Network error. Please check your connection."
        default:
            return error.localizedDescription
        }
    }
}
