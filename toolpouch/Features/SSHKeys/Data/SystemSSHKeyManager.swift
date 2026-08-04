#if os(macOS)
import Foundation

nonisolated struct SystemSSHKeyManager: SSHKeyManaging {
    func listKeys(in folderURL: URL) async throws -> [SSHKeyPair] {
        try await Task.detached(priority: .userInitiated) {
            try Self.readKeys(in: folderURL)
        }.value
    }

    func generateKey(
        request: SSHKeyGenerationRequest,
        in folderURL: URL
    ) async throws {
        try await Task.detached(priority: .userInitiated) {
            try Self.generate(request: request, in: folderURL)
        }.value
    }

    func readKey(at url: URL) async throws -> String {
        try await Task.detached(priority: .userInitiated) {
            try String(contentsOf: url, encoding: .utf8)
        }.value
    }

    func moveKeyPairToTrash(_ key: SSHKeyPair) async throws {
        try await Task.detached(priority: .userInitiated) {
            let urls = [key.publicKeyURL, key.privateKeyURL].compactMap { $0 }
            var movedItems: [(original: URL, trashed: URL)] = []

            do {
                for url in urls {
                    var resultingURL: NSURL?
                    try FileManager.default.trashItem(
                        at: url,
                        resultingItemURL: &resultingURL
                    )
                    if let resultingURL {
                        movedItems.append((url, resultingURL as URL))
                    }
                }
            } catch {
                for item in movedItems.reversed()
                where !FileManager.default.fileExists(atPath: item.original.path) {
                    try? FileManager.default.moveItem(
                        at: item.trashed,
                        to: item.original
                    )
                }
                throw error
            }
        }.value
    }

    private static func readKeys(in folderURL: URL) throws -> [SSHKeyPair] {
        let fileManager = FileManager.default
        let urls = try fileManager.contentsOfDirectory(
            at: folderURL,
            includingPropertiesForKeys: [.isRegularFileKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )
        let publicURLs = Dictionary(
            uniqueKeysWithValues: urls
                .filter { $0.pathExtension == "pub" }
                .map { ($0.deletingPathExtension().lastPathComponent, $0) }
        )

        return urls
            .filter { url in
                guard url.pathExtension != "pub" else { return false }
                guard !Self.ignoredFileNames.contains(url.lastPathComponent) else { return false }
                return (try? Self.isPrivateKey(url)) == true
            }
            .map { privateURL in
                let name = privateURL.lastPathComponent
                let publicURL = publicURLs[name]
                let publicMetadata = publicURL.flatMap(Self.readPublicMetadata)
                let values = try? privateURL.resourceValues(forKeys: [.contentModificationDateKey])

                return SSHKeyPair(
                    name: name,
                    privateKeyURL: privateURL,
                    publicKeyURL: publicURL,
                    algorithm: publicMetadata?.algorithm,
                    comment: publicMetadata?.comment,
                    modifiedAt: values?.contentModificationDate
                )
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private static func generate(
        request: SSHKeyGenerationRequest,
        in folderURL: URL
    ) throws {
        try validate(fileName: request.fileName)

        let destination = folderURL.appendingPathComponent(request.fileName)
        let publicDestination = destination.appendingPathExtension("pub")
        guard !FileManager.default.fileExists(atPath: destination.path),
              !FileManager.default.fileExists(atPath: publicDestination.path) else {
            throw SSHKeyManagerError.fileAlreadyExists(request.fileName)
        }

        let temporaryFolder = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(
            at: temporaryFolder,
            withIntermediateDirectories: true
        )
        defer { try? FileManager.default.removeItem(at: temporaryFolder) }

        let temporaryKey = temporaryFolder.appendingPathComponent(request.fileName)
        let process = Process()
        let standardError = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ssh-keygen")
        process.standardError = standardError
        process.arguments = arguments(for: request, outputURL: temporaryKey)

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let data = standardError.fileHandleForReading.readDataToEndOfFile()
            let message = String(decoding: data, as: UTF8.self)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            throw SSHKeyManagerError.generationFailed(message)
        }

        try FileManager.default.copyItem(at: temporaryKey, to: destination)
        try FileManager.default.copyItem(
            at: temporaryKey.appendingPathExtension("pub"),
            to: publicDestination
        )
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o600],
            ofItemAtPath: destination.path
        )
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o644],
            ofItemAtPath: publicDestination.path
        )
    }

    private static func arguments(
        for request: SSHKeyGenerationRequest,
        outputURL: URL
    ) -> [String] {
        var arguments = [
            "-q",
            "-t", request.algorithm.rawValue,
            "-f", outputURL.path,
            "-C", request.comment,
            "-N", request.passphrase,
        ]
        if let bitSize = request.bitSize {
            arguments.append(contentsOf: ["-b", String(bitSize)])
        }
        return arguments
    }

    private static func validate(fileName: String) throws {
        let trimmed = fileName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              trimmed == fileName,
              !trimmed.contains("/"),
              trimmed != ".",
              trimmed != ".." else {
            throw SSHKeyManagerError.invalidFileName
        }
    }

    private static func isPrivateKey(_ url: URL) throws -> Bool {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        let prefix = try handle.read(upToCount: 96) ?? Data()
        let text = String(decoding: prefix, as: UTF8.self)
        return text.contains("PRIVATE KEY")
    }

    private static func readPublicMetadata(
        from url: URL
    ) -> (algorithm: String, comment: String?)? {
        guard let contents = try? String(contentsOf: url, encoding: .utf8) else {
            return nil
        }
        let parts = contents
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: " ", maxSplits: 2)
        guard let algorithm = parts.first else { return nil }
        let comment = parts.count == 3 ? String(parts[2]) : nil
        return (String(algorithm), comment)
    }

    private static let ignoredFileNames: Set<String> = [
        "authorized_keys",
        "config",
        "known_hosts",
        "known_hosts.old",
    ]
}
#endif
