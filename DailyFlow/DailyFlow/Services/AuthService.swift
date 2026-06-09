import Foundation
import FirebaseAuth
import FirebaseFirestore

final class AuthService: ObservableObject {
    static let shared = AuthService()
    private init() {}

    var currentUser: User? { Auth.auth().currentUser }
    var currentUserId: String? { Auth.auth().currentUser?.uid }

    func signIn(email: String, password: String) async throws {
        try await Auth.auth().signIn(withEmail: email, password: password)
    }

    func signUp(name: String, email: String, password: String) async throws -> String {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        let uid = result.user.uid
        let changeReq = result.user.createProfileChangeRequest()
        changeReq.displayName = name
        try await changeReq.commitChanges()
        return uid
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }

    func resetPassword(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }

    func deleteAccount() async throws {
        guard let user = Auth.auth().currentUser else { return }
        try await user.delete()
    }
}
