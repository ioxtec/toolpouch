import Foundation
import Testing
@testable import toolpouch

@MainActor
struct ZipArchiveSecurityTests {
    @Test
    func archiveUsesStandardRawDeflateReadableBySystemUnzip() throws {
        let unzipURL = URL(fileURLWithPath: "/usr/bin/unzip")
        guard FileManager.default.isExecutableFile(atPath: unzipURL.path) else {
            return
        }
        let root = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let source = root.appending(path: "message.txt")
        let archive = root.appending(path: "message.zip")
        try Data("hello standard zip".utf8).write(to: source)
        try ZipArchive.create(from: source, to: archive)

        let process = Process()
        let output = Pipe()
        process.executableURL = unzipURL
        process.arguments = ["-p", archive.path, "message.txt"]
        process.standardOutput = output
        try process.run()
        process.waitUntilExit()

        #expect(process.terminationStatus == 0)
        #expect(
            String(
                data: output.fileHandleForReading.readDataToEndOfFile(),
                encoding: .utf8
            ) == "hello standard zip"
        )
    }

    @Test
    func extractionRejectsTraversalEntry() throws {
        let root = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let source = root.appending(path: "safe.txt")
        let archive = root.appending(path: "malicious.zip")
        let output = root.appending(path: "output", directoryHint: .isDirectory)
        try Data("escape".utf8).write(to: source)
        try ZipArchive.create(from: source, to: archive)
        var bytes = try Data(contentsOf: archive)
        replaceAll(
            Data("safe.txt".utf8),
            with: Data("../x.txt".utf8),
            in: &bytes
        )
        try bytes.write(to: archive)

        #expect(throws: ArchiveOperationError.invalidArchive) {
            try ZipArchive.extract(archiveURL: archive, to: output)
        }
        #expect(!FileManager.default.fileExists(atPath: root.appending(path: "x.txt").path))
    }

    @Test
    func untrustedArchivePolicyRejectsExtremeCompressionRatio() throws {
        let root = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let source = root.appending(path: "zeros.bin")
        let archive = root.appending(path: "bomb.zip")
        let output = root.appending(path: "output", directoryHint: .isDirectory)
        try Data(repeating: 0, count: 2 * 1_048_576).write(to: source)
        try ZipArchive.create(from: source, to: archive)

        #expect(throws: ArchiveOperationError.invalidArchive) {
            try ZipArchive.extract(
                archiveURL: archive,
                to: output,
                policy: .untrustedArchive
            )
        }
    }

    @Test
    func extractionRejectsDataAfterEndOfCentralDirectory() throws {
        let root = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let source = root.appending(path: "safe.txt")
        let archive = root.appending(path: "trailing-data.zip")
        let output = root.appending(path: "output", directoryHint: .isDirectory)
        try Data("safe".utf8).write(to: source)
        try ZipArchive.create(from: source, to: archive)
        var bytes = try Data(contentsOf: archive)
        bytes.append(contentsOf: [0xde, 0xad, 0xbe, 0xef])
        try bytes.write(to: archive)

        #expect(throws: ArchiveOperationError.invalidArchive) {
            try ZipArchive.extract(
                archiveURL: archive,
                to: output,
                policy: .untrustedArchive
            )
        }
    }

    private func makeTemporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appending(
            path: "ZipArchiveSecurityTests-\(UUID().uuidString)",
            directoryHint: .isDirectory
        )
        try FileManager.default.createDirectory(
            at: url,
            withIntermediateDirectories: true
        )
        return url
    }

    private func replaceAll(
        _ pattern: Data,
        with replacement: Data,
        in data: inout Data
    ) {
        precondition(pattern.count == replacement.count)
        while let range = data.range(of: pattern) {
            data.replaceSubrange(range, with: replacement)
        }
    }
}
