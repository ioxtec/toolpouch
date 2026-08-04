import Foundation

@MainActor
protocol SSHKeyFolderAccessing: Sendable {
    var folderURL: URL? { get }

    func chooseFolder() async throws -> URL?
    func withAccess<T: Sendable>(
        _ operation: @escaping @Sendable (URL) async throws -> T
    ) async throws -> T
}
