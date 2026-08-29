import Foundation

protocol MediaFileInspecting: Sendable {
    func inspectMedia(at url: URL) async throws -> MediaFileInspection
}
