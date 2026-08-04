#if os(macOS)
import Foundation
import Observation

@MainActor
@Observable
final class SSHKeysViewModel {
    private let manager: any SSHKeyManaging
    private let folderStore: any SSHKeyFolderAccessing

    private(set) var keys: [SSHKeyPair] = []
    private(set) var folderURL: URL?
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private(set) var copiedKeyID: SSHKeyPair.ID?

    init(
        manager: any SSHKeyManaging,
        folderStore: any SSHKeyFolderAccessing
    ) {
        self.manager = manager
        self.folderStore = folderStore
        folderURL = folderStore.folderURL
    }

    func load() async {
        guard folderStore.folderURL != nil else {
            folderURL = nil
            keys = []
            return
        }

        await perform {
            try await folderStore.withAccess { [manager] folderURL in
                try await manager.listKeys(in: folderURL)
            }
        } onSuccess: { [weak self] keys in
            self?.folderURL = self?.folderStore.folderURL
            self?.keys = keys
        }
    }

    func chooseFolder() async {
        do {
            guard let folderURL = try await folderStore.chooseFolder() else { return }
            self.folderURL = folderURL
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func generate(_ request: SSHKeyGenerationRequest) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await folderStore.withAccess { [manager] folderURL in
                try await manager.generateKey(request: request, in: folderURL)
            }
            await load()
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }

    func copyPublicKey(_ key: SSHKeyPair) async {
        guard let publicKeyURL = key.publicKeyURL else {
            errorMessage = SSHKeyManagerError.publicKeyUnavailable.localizedDescription
            return
        }
        await copyKey(at: publicKeyURL, keyID: key.id)
    }

    func copyPrivateKey(_ key: SSHKeyPair) async {
        await copyKey(at: key.privateKeyURL, keyID: key.id)
    }

    func moveKeyPairToTrash(_ key: SSHKeyPair) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await folderStore.withAccess { [manager] _ in
                try await manager.moveKeyPairToTrash(key)
            }
            keys.removeAll { $0.id == key.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func copyKey(at url: URL, keyID: SSHKeyPair.ID) async {
        do {
            let value = try await folderStore.withAccess { [manager] _ in
                try await manager.readKey(at: url)
            }
            SystemClipboard.copy(value)
            copiedKeyID = keyID
            try? await Task.sleep(for: .seconds(1.2))
            if copiedKeyID == keyID {
                copiedKeyID = nil
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func perform<T: Sendable>(
        _ operation: () async throws -> T,
        onSuccess: (T) -> Void
    ) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            onSuccess(try await operation())
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
#endif
