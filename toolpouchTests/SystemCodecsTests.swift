import Foundation
import Testing
@testable import toolpouch

struct SystemCodecsTests {
    // MARK: - BZIP2

    @Test
    func bzip2EmptyInputRoundTrips() throws {
        let compressed = try Bzip2Codec.compress(data: Data())
        let decompressed = try Bzip2Codec.decompress(data: compressed)

        #expect(!compressed.isEmpty)
        #expect(decompressed.isEmpty)
    }

    @Test
    func bzip2RoundTripsUnicodeData() throws {
        let original = Data("ToolPouch — bzip2 🧰 test".utf8)
        let compressed = try Bzip2Codec.compress(data: original)
        let decompressed = try Bzip2Codec.decompress(data: compressed)

        #expect(decompressed == original)
    }

    @Test
    func bzip2RoundTripsBinaryData() throws {
        let original = Data((0..<100_000).map { UInt8($0 % 251) })
        let compressed = try Bzip2Codec.compress(data: original)
        let decompressed = try Bzip2Codec.decompress(data: compressed)

        #expect(decompressed == original)
    }

    @Test
    func bzip2EmitsValidMagic() throws {
        let compressed = try Bzip2Codec.compress(data: Data("hello".utf8))

        #expect(compressed.count >= 4)
        #expect(compressed[0] == 0x42) // 'B'
        #expect(compressed[1] == 0x5a) // 'Z'
        #expect(compressed[2] == 0x68) // 'h'
    }

    @Test
    func bzip2RejectsNonBzip2Data() {
        let garbage = Data("this is not a bzip2 archive".utf8)

        #expect(throws: ArchiveOperationError.invalidArchive) {
            try Bzip2Codec.decompress(data: garbage)
        }
    }

    @Test
    func bzip2RejectsTruncatedStream() throws {
        let compressed = try Bzip2Codec.compress(data: Data("truncated".utf8))
        let truncated = compressed.dropLast(4)

        #expect(throws: ArchiveOperationError.invalidArchive) {
            try Bzip2Codec.decompress(data: Data(truncated))
        }
    }

    @Test
    func bzip2DecompressesSystemFile() throws {
        let fixture = try makeSystemFixture(
            text: "system bzip2 → toolpouch",
            tool: "/usr/bin/bzip2",
            extension: "bz2"
        )

        let decompressed = try Bzip2Codec.decompress(data: fixture)

        #expect(String(data: decompressed, encoding: .utf8) == "system bzip2 → toolpouch")
    }

    @Test
    func systemBzip2ValidatesToolPouchOutput() throws {
        let original = Data("toolpouch → system bzip2 interop 1234567890".utf8)
        let compressed = try Bzip2Codec.compress(data: original)

        let temporaryDirectory = FileManager.default.temporaryDirectory
        let url = temporaryDirectory
            .appendingPathComponent("toolpouch-bz2-\(UUID().uuidString).bz2")
        try compressed.write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/bzip2")
        process.arguments = ["-t", url.path]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        try process.run()
        process.waitUntilExit()

        #expect(process.terminationStatus == 0)
    }

    // MARK: - XZ

    @Test
    func xzEmptyInputRoundTrips() throws {
        let compressed = try XZCodec.compress(data: Data())
        let decompressed = try XZCodec.decompress(data: compressed)

        #expect(!compressed.isEmpty)
        #expect(decompressed.isEmpty)
    }

    @Test
    func xzRoundTripsUnicodeData() throws {
        let original = Data("ToolPouch — xz 🧰 test".utf8)
        let compressed = try XZCodec.compress(data: original)
        let decompressed = try XZCodec.decompress(data: compressed)

        #expect(decompressed == original)
    }

    @Test
    func xzRoundTripsBinaryData() throws {
        let original = Data((0..<100_000).map { UInt8($0 % 251) })
        let compressed = try XZCodec.compress(data: original)
        let decompressed = try XZCodec.decompress(data: compressed)

        #expect(decompressed == original)
    }

    @Test
    func xzEmitsValidMagic() throws {
        let compressed = try XZCodec.compress(data: Data("hello".utf8))

        #expect(compressed.count >= 6)
        #expect(compressed[0] == 0xfd)
        #expect(compressed[1] == 0x37)
        #expect(compressed[2] == 0x7a)
        #expect(compressed[3] == 0x58)
        #expect(compressed[4] == 0x5a)
        #expect(compressed[5] == 0x00)
    }

    @Test
    func xzRejectsNonXzData() {
        let garbage = Data("this is not an xz archive".utf8)

        #expect(throws: ArchiveOperationError.invalidArchive) {
            try XZCodec.decompress(data: garbage)
        }
    }

    @Test
    func xzRejectsTruncatedStream() throws {
        let compressed = try XZCodec.compress(data: Data("truncated".utf8))
        let truncated = compressed.dropLast(4)

        #expect(throws: ArchiveOperationError.invalidArchive) {
            try XZCodec.decompress(data: Data(truncated))
        }
    }

    @Test(
        .enabled(
            if: SystemCodecsTests.systemToolPath(named: "xz") != nil,
            "Requires an xz executable"
        )
    )
    func xzDecompressesSystemFile() throws {
        let xz = try #require(Self.systemToolPath(named: "xz"))
        let fixture = try makeSystemFixture(
            text: "system xz → toolpouch",
            tool: xz,
            extension: "xz"
        )

        let decompressed = try XZCodec.decompress(data: fixture)

        #expect(String(data: decompressed, encoding: .utf8) == "system xz → toolpouch")
    }

    @Test(
        .enabled(
            if: SystemCodecsTests.systemToolPath(named: "xz") != nil,
            "Requires an xz executable"
        )
    )
    func systemXzValidatesToolPouchOutput() throws {
        let xz = try #require(Self.systemToolPath(named: "xz"))
        let original = Data("toolpouch → system xz interop 1234567890".utf8)
        let compressed = try XZCodec.compress(data: original)

        let temporaryDirectory = FileManager.default.temporaryDirectory
        let url = temporaryDirectory
            .appendingPathComponent("toolpouch-xz-\(UUID().uuidString).xz")
        try compressed.write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: xz)
        process.arguments = ["-t", url.path]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        try process.run()
        process.waitUntilExit()

        #expect(process.terminationStatus == 0)
    }

    // MARK: - Helpers

    nonisolated private static func systemToolPath(named name: String) -> String? {
        let environmentPaths = ProcessInfo.processInfo.environment["PATH"]?
            .split(separator: ":")
            .map(String.init) ?? []
        let searchPaths = environmentPaths + [
            "/opt/homebrew/bin",
            "/usr/local/bin",
            "/usr/bin",
        ]

        return searchPaths
            .map { URL(fileURLWithPath: $0).appendingPathComponent(name).path }
            .first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    private func makeSystemFixture(
        text: String,
        tool: String,
        extension ext: String
    ) throws -> Data {
        let temporaryDirectory = FileManager.default.temporaryDirectory
        let base = temporaryDirectory
            .appendingPathComponent("toolpouch-fixture-\(UUID().uuidString)")
        try text.write(to: base, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: base) }

        let compressed = URL(fileURLWithPath: base.path + "." + ext)
        defer { try? FileManager.default.removeItem(at: compressed) }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: tool)
        process.arguments = ["-k", "-f", base.path]
        try process.run()
        process.waitUntilExit()
        #expect(process.terminationStatus == 0)

        return try Data(contentsOf: compressed)
    }
}
