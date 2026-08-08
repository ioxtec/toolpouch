import Foundation
import Testing
@testable import toolpouch

struct GzipCodecTests {
    private let codec = GzipCodec()

    @Test
    func emptyInputRoundTrips() throws {
        let compressed = try codec.compress(data: Data())
        #expect(compressed.isEmpty)
    }

    @Test
    func roundTripsUnicodeData() throws {
        let original = Data("ToolPouch — zażółć 🧰 gzip test".utf8)
        let compressed = try codec.compress(data: original)
        let decompressed = try codec.decompress(data: compressed)

        #expect(decompressed == original)
    }

    @Test
    func roundTripsBinaryData() throws {
        let original = Data((0..<4096).map { UInt8($0 % 256) })
        let compressed = try codec.compress(data: original)
        let decompressed = try codec.decompress(data: compressed)

        #expect(decompressed == original)
    }

    @Test
    func emitsValidGzipHeader() throws {
        let compressed = try codec.compress(data: Data("hello".utf8))

        #expect(compressed.count >= 18)
        #expect(compressed[0] == 0x1f)
        #expect(compressed[1] == 0x8b)
        #expect(compressed[2] == 0x08)
    }

    @Test
    func rejectsNonGzipData() {
        let garbage = Data("this is not a gzip archive".utf8)

        #expect(throws: ArchiveOperationError.invalidArchive) {
            try codec.decompress(data: garbage)
        }
    }

    @Test
    func rejectsCorruptedTrailer() throws {
        let original = Data("integrity check".utf8)
        var corrupted = try codec.compress(data: original)
        corrupted[corrupted.count - 5] ^= 0xff // corrupt the CRC field

        #expect(throws: ArchiveOperationError.invalidArchive) {
            try codec.decompress(data: corrupted)
        }
    }

    @Test
    func decompressesSystemGzipFile() throws {
        let fixture = try makeSystemGzipFixture(text: "system gzip → toolpouch")

        let decompressed = try codec.decompress(data: fixture)

        #expect(String(data: decompressed, encoding: .utf8) == "system gzip → toolpouch")
    }

    @Test
    func systemGzipValidatesToolPouchOutput() throws {
        let original = Data("toolpouch → system gzip interop 1234567890".utf8)
        let compressed = try codec.compress(data: original)

        let temporaryDirectory = FileManager.default.temporaryDirectory
        let url = temporaryDirectory
            .appendingPathComponent("toolpouch-interop-\(UUID().uuidString).gz")
        try compressed.write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/gzip")
        process.arguments = ["-t", url.path]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        try process.run()
        process.waitUntilExit()

        #expect(process.terminationStatus == 0)
    }

    private func makeSystemGzipFixture(text: String) throws -> Data {
        let temporaryDirectory = FileManager.default.temporaryDirectory
        let base = temporaryDirectory
            .appendingPathComponent("toolpouch-fixture-\(UUID().uuidString)")
        try text.write(to: base, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: base) }

        let gz = URL(fileURLWithPath: base.path + ".gz")
        defer { try? FileManager.default.removeItem(at: gz) }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/gzip")
        process.arguments = ["-k", "-f", base.path]
        try process.run()
        process.waitUntilExit()
        #expect(process.terminationStatus == 0)

        return try Data(contentsOf: gz)
    }
}
