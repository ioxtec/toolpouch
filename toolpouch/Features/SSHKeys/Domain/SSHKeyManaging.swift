import Foundation

nonisolated protocol SSHKeyManaging: Sendable {
    func listKeys(in folderURL: URL) async throws -> [SSHKeyPair]
    /// Generates a key pair without replacing files that already exist in the destination folder.
    func generateKey(
        request: SSHKeyGenerationRequest,
        in folderURL: URL
    ) async throws
    func readKey(at url: URL) async throws -> String
    /// Moves both files in a key pair to the system Trash so removal remains recoverable.
    func moveKeyPairToTrash(_ key: SSHKeyPair) async throws
}

nonisolated enum SSHKeyManagerError: LocalizedError {
    case invalidFileName
    case fileAlreadyExists(String)
    case generationFailed(String)
    case folderUnavailable
    case publicKeyUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidFileName:
            "Use a file name without slashes or parent-directory references.".localizedInterfaceText
        case let .fileAlreadyExists(name):
            String(format: "A key named %@ already exists.".localizedInterfaceText, name)
        case let .generationFailed(message):
            message.isEmpty ? "The key could not be generated.".localizedInterfaceText : message
        case .folderUnavailable:
            "Choose an SSH key folder first.".localizedInterfaceText
        case .publicKeyUnavailable:
            "This key does not have a matching public key file.".localizedInterfaceText
        }
    }
}
