import Foundation
import Testing
@testable import toolpouch

struct SystemSSHKeyManagerTests {
    @Test
    func generatesAndDiscoversAnEd25519KeyPair() async throws {
        let folderURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(
            at: folderURL,
            withIntermediateDirectories: true
        )
        defer { try? FileManager.default.removeItem(at: folderURL) }

        let manager = SystemSSHKeyManager()
        let request = SSHKeyGenerationRequest(
            algorithm: .ed25519,
            bitSize: nil,
            fileName: "id_toolpouch_test",
            comment: "test@example.com",
            passphrase: ""
        )

        try await manager.generateKey(request: request, in: folderURL)
        let keys = try await manager.listKeys(in: folderURL)

        let key = try #require(keys.first)
        #expect(key.name == "id_toolpouch_test")
        #expect(key.algorithm == "ssh-ed25519")
        #expect(key.comment == "test@example.com")
        #expect(key.publicKeyURL != nil)
    }

    @Test
    func refusesToOverwriteAnExistingKey() async throws {
        let folderURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(
            at: folderURL,
            withIntermediateDirectories: true
        )
        defer { try? FileManager.default.removeItem(at: folderURL) }

        let existingURL = folderURL.appendingPathComponent("id_existing")
        try "existing".write(to: existingURL, atomically: true, encoding: .utf8)

        let manager = SystemSSHKeyManager()
        let request = SSHKeyGenerationRequest(
            algorithm: .ed25519,
            bitSize: nil,
            fileName: "id_existing",
            comment: "",
            passphrase: ""
        )

        await #expect(throws: SSHKeyManagerError.self) {
            try await manager.generateKey(request: request, in: folderURL)
        }
    }
}
