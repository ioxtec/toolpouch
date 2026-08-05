import Foundation

@MainActor
/// Remembers the selected key folder and opens security-scoped access only for a requested operation.
protocol SSHKeyFolderAccessing: Sendable {
    var folderURL: URL? { get }

    func chooseFolder() async throws -> URL?
    /// Runs an operation while the sandbox bookmark is active, then closes access reliably.
    func withAccess<T: Sendable>(
        _ operation: @escaping @Sendable (URL) async throws -> T
    ) async throws -> T
}
