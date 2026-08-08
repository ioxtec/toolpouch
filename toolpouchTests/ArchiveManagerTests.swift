import Foundation
import Testing
@testable import toolpouch

struct ArchiveManagerTests {
    private let manager = ArchiveManager()

    @Test
    func zipRoundTripsFolder() async throws {
        let (source, temporaryRoot) = try makeSourceFolder()
        defer { try? FileManager.default.removeItem(at: temporaryRoot) }

        let zipURL = temporaryRoot.appendingPathComponent("folder.zip")
        try await manager.compress(
            sourceURL: source,
            destinationURL: zipURL,
            format: .zip
        )

        let output = temporaryRoot.appendingPathComponent("extracted")
        try ZipArchive.extract(archiveURL: zipURL, to: output)

        #expect(
            FileManager.default.fileExists(
                atPath: output.appendingPathComponent("folder/inner/data.txt").path
            )
        )
        let content = try String(
            contentsOf: output.appendingPathComponent("folder/inner/data.txt"),
            encoding: .utf8
        )
        #expect(content == "ArchiveTool test data")
    }

    @Test
    func gzipRoundTripsSingleFile() async throws {
        let temporaryRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("ArchiveManagerTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: temporaryRoot, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: temporaryRoot) }

        let source = temporaryRoot.appendingPathComponent("log.txt")
        try "hello gzip world".write(to: source, atomically: true, encoding: .utf8)

        let gzURL = temporaryRoot.appendingPathComponent("log.gz")
        try await manager.compress(
            sourceURL: source,
            destinationURL: gzURL,
            format: .gzip
        )

        let output = try await manager.decompress(archiveURL: gzURL)

        #expect(
            try String(contentsOf: output, encoding: .utf8) == "hello gzip world"
        )
        #expect(FileManager.default.fileExists(atPath: gzURL.path))
    }

    @Test
    func gzipRejectsFolderSource() async throws {
        let temporaryRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("ArchiveManagerTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: temporaryRoot, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: temporaryRoot) }

        let folder = temporaryRoot.appendingPathComponent("somefolder")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        let gzURL = temporaryRoot.appendingPathComponent("somefolder.gz")
        await #expect(throws: ArchiveOperationError.unsupportedFormat) {
            try await manager.compress(
                sourceURL: folder,
                destinationURL: gzURL,
                format: .gzip
            )
        }
    }

    @Test
    func decompressZipVerifiesContents() async throws {
        let temporaryRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("ArchiveManagerTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: temporaryRoot, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: temporaryRoot) }

        let source = temporaryRoot.appendingPathComponent("hello.txt")
        try "zip content".write(to: source, atomically: true, encoding: .utf8)
        let zipURL = temporaryRoot.appendingPathComponent("hello.zip")
        try ZipArchive.create(from: source, to: zipURL)

        let output = try await manager.decompress(archiveURL: zipURL)

        #expect(
            FileManager.default.fileExists(
                atPath: output.appendingPathComponent("hello.txt").path
            )
        )
    }

    @Test
    func rejectsUnsupportedExtension() async throws {
        let temporaryRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("ArchiveManagerTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: temporaryRoot, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: temporaryRoot) }

        let file = temporaryRoot.appendingPathComponent("data.rar")
        try "not an archive".write(to: file, atomically: true, encoding: .utf8)

        await #expect(throws: ArchiveOperationError.unsupportedFormat) {
            try await manager.decompress(archiveURL: file)
        }
    }

    @Test
    func bzip2RoundTripsSingleFile() async throws {
        let temporaryRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("ArchiveManagerTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: temporaryRoot, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: temporaryRoot) }

        let source = temporaryRoot.appendingPathComponent("log.txt")
        try "hello bzip2 world".write(to: source, atomically: true, encoding: .utf8)

        let bz2URL = temporaryRoot.appendingPathComponent("log.bz2")
        try await manager.compress(
            sourceURL: source,
            destinationURL: bz2URL,
            format: .bzip2
        )

        let output = try await manager.decompress(archiveURL: bz2URL)

        #expect(
            try String(contentsOf: output, encoding: .utf8) == "hello bzip2 world"
        )
        #expect(FileManager.default.fileExists(atPath: bz2URL.path))
    }

    @Test
    func xzRoundTripsSingleFile() async throws {
        let temporaryRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("ArchiveManagerTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: temporaryRoot, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: temporaryRoot) }

        let source = temporaryRoot.appendingPathComponent("log.txt")
        try "hello xz world".write(to: source, atomically: true, encoding: .utf8)

        let xzURL = temporaryRoot.appendingPathComponent("log.xz")
        try await manager.compress(
            sourceURL: source,
            destinationURL: xzURL,
            format: .xz
        )

        let output = try await manager.decompress(archiveURL: xzURL)

        #expect(
            try String(contentsOf: output, encoding: .utf8) == "hello xz world"
        )
        #expect(FileManager.default.fileExists(atPath: xzURL.path))
    }

    @Test
    func tarRoundTripsFolder() async throws {
        let (source, temporaryRoot) = try makeSourceFolder()
        defer { try? FileManager.default.removeItem(at: temporaryRoot) }

        let tarURL = temporaryRoot.appendingPathComponent("folder.tar")
        try await manager.compress(
            sourceURL: source,
            destinationURL: tarURL,
            format: .tar
        )

        let output = try await manager.decompress(archiveURL: tarURL)

        #expect(
            FileManager.default.fileExists(
                atPath: output.appendingPathComponent("folder/inner/data.txt").path
            )
        )
        let content = try String(
            contentsOf: output.appendingPathComponent("folder/inner/data.txt"),
            encoding: .utf8
        )
        #expect(content == "ArchiveTool test data")
    }

    @Test
    func tgzRoundTripsFolder() async throws {
        let (source, temporaryRoot) = try makeSourceFolder()
        defer { try? FileManager.default.removeItem(at: temporaryRoot) }

        let tgzURL = temporaryRoot.appendingPathComponent("folder.tgz")
        try await manager.compress(
            sourceURL: source,
            destinationURL: tgzURL,
            format: .tar
        )
        // Wrap the tar in gzip to produce a .tgz archive.
        let tarData = try Data(contentsOf: tgzURL)
        let gzData = try GzipCodec().compress(data: tarData)
        try gzData.write(to: tgzURL)

        let output = try await manager.decompress(archiveURL: tgzURL)

        #expect(
            FileManager.default.fileExists(
                atPath: output.appendingPathComponent("folder/inner/data.txt").path
            )
        )
        let content = try String(
            contentsOf: output.appendingPathComponent("folder/inner/data.txt"),
            encoding: .utf8
        )
        #expect(content == "ArchiveTool test data")
    }

    @Test
    func tarRejectsEntryOutsideOutputDirectory() async throws {
        let temporaryRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("ArchiveManagerTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(
            at: temporaryRoot,
            withIntermediateDirectories: true
        )
        defer { try? FileManager.default.removeItem(at: temporaryRoot) }

        let tarURL = temporaryRoot.appendingPathComponent("malicious.tar")
        try makeTarEntry(name: "../escaped.txt", contents: Data("nope".utf8))
            .write(to: tarURL)

        await #expect(throws: ArchiveOperationError.invalidArchive) {
            try await manager.decompress(archiveURL: tarURL)
        }
        #expect(
            !FileManager.default.fileExists(
                atPath: temporaryRoot.appendingPathComponent("escaped.txt").path
            )
        )
    }

    @Test
    func bzip2RejectsFolderSource() async throws {
        let temporaryRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("ArchiveManagerTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: temporaryRoot, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: temporaryRoot) }

        let folder = temporaryRoot.appendingPathComponent("somefolder")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        let bz2URL = temporaryRoot.appendingPathComponent("somefolder.bz2")
        await #expect(throws: ArchiveOperationError.unsupportedFormat) {
            try await manager.compress(
                sourceURL: folder,
                destinationURL: bz2URL,
                format: .bzip2
            )
        }
    }

    @Test
    func xzRejectsFolderSource() async throws {
        let temporaryRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("ArchiveManagerTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: temporaryRoot, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: temporaryRoot) }

        let folder = temporaryRoot.appendingPathComponent("somefolder")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        let xzURL = temporaryRoot.appendingPathComponent("somefolder.xz")
        await #expect(throws: ArchiveOperationError.unsupportedFormat) {
            try await manager.compress(
                sourceURL: folder,
                destinationURL: xzURL,
                format: .xz
            )
        }
    }

    private func makeSourceFolder() throws -> (URL, URL) {
        let temporaryRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("ArchiveManagerTests-\(UUID().uuidString)")
        let source = temporaryRoot.appendingPathComponent("folder")
        try FileManager.default.createDirectory(
            at: source.appendingPathComponent("inner"),
            withIntermediateDirectories: true
        )
        try "ArchiveTool test data".write(
            to: source.appendingPathComponent("inner/data.txt"),
            atomically: true,
            encoding: .utf8
        )
        return (source, temporaryRoot)
    }

    private func makeTarEntry(name: String, contents: Data) -> Data {
        var header = Data(repeating: 0, count: 512)

        func write(_ text: String, at offset: Int, length: Int) {
            for (index, byte) in text.utf8.prefix(length).enumerated() {
                header[offset + index] = byte
            }
        }

        write(name, at: 0, length: 100)
        write("0000644", at: 100, length: 8)
        write("0000000", at: 108, length: 8)
        write("0000000", at: 116, length: 8)
        write(String(contents.count, radix: 8), at: 124, length: 12)
        write("00000000000", at: 136, length: 12)
        write("        ", at: 148, length: 8)
        header[156] = 0x30

        var checksum: UInt32 = 0
        for byte in header {
            checksum += UInt32(byte)
        }
        write(String(checksum, radix: 8), at: 148, length: 7)

        var archive = header
        archive.append(contents)
        let padding = (512 - contents.count % 512) % 512
        archive.append(Data(repeating: 0, count: padding + 1024))
        return archive
    }
}
