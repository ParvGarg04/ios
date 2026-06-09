import Foundation
import UIKit
import FirebaseStorage

final class StorageService {
    static let shared = StorageService()
    private let storage = Storage.storage().reference()
    private init() {}

    // MARK: - Upload Task Attachment
    func uploadTaskAttachment(image: UIImage, userId: String, taskId: String) async throws -> String {
        let path = "submissions/\(userId)/\(taskId)/\(UUID().uuidString).jpg"
        return try await upload(image: image, path: path)
    }

    // MARK: - Upload Water Attachment
    func uploadWaterAttachment(image: UIImage, userId: String) async throws -> String {
        let path = "waterLogs/\(userId)/\(UUID().uuidString).jpg"
        return try await upload(image: image, path: path)
    }

    // MARK: - Core Upload
    private func upload(image: UIImage, path: String, quality: CGFloat = 0.75) async throws -> String {
        guard let data = image.jpegData(compressionQuality: quality) else {
            throw StorageError.compressionFailed
        }

        let ref      = storage.child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        _ = try await ref.putDataAsync(data, metadata: metadata)
        let url = try await ref.downloadURL()
        return url.absoluteString
    }

    // MARK: - Delete
    func deleteFile(at urlString: String) async throws {
        guard let url = URL(string: urlString) else { return }
        let path = url.path.components(separatedBy: "/o/").last?
            .removingPercentEncoding?
            .components(separatedBy: "?").first ?? ""
        guard !path.isEmpty else { return }
        let ref = storage.child(path)
        try await ref.delete()
    }
}

enum StorageError: LocalizedError {
    case compressionFailed
    var errorDescription: String? {
        switch self {
        case .compressionFailed:
            return "Failed to compress image. Please try again."
        }
    }
}
