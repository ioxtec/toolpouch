import Foundation
import UniformTypeIdentifiers

/// Production archive manager. ZIP and TAR can bundle folders, while
/// GZIP, BZIP2, and XZ compress single files. Heavy work runs on a detached
/// executor so the main actor stays free.
nonisolated struct ArchiveManager: ArchiveManaging {
    private let gzipCodec: GzipCodec

    init(gzipCodec: GzipCodec = GzipCodec()) {
        self.gzipCodec = gzipCodec
    }

    func compress(
        sourceURL: URL,
        destinationURL: URL,
        format: ArchiveFormat
    ) async throws {
        try await Task.detached(priority: .userInitiated) {
            try self.compressSynchronously(
                sourceURL: sourceURL,
                destinationURL: destinationURL,
                format: format
            )
        }.value
    }

    func decompress(archiveURL: URL) async throws -> URL {
        try await Task.detached(priority: .userInitiated) {
            try self.decompressSynchronously(archiveURL: archiveURL)
        }.value
    }

    private func compressSynchronously(
        sourceURL: URL,
        destinationURL: URL,
        format: ArchiveFormat
    ) throws {
        guard FileManager.default.fileExists(atPath: sourceURL.path) else {
            throw ArchiveOperationError.sourceMissing
        }
        guard FileManager.default.fileExists(
            atPath: destinationURL.deletingLastPathComponent().path
        ) else {
            throw ArchiveOperationError.destinationUnavailable
        }

        switch format {
        case .zip:
            try ZipArchive.create(
                from: sourceURL,
                to: destinationURL
            )
        case .gzip:
            try compressToGzip(sourceURL: sourceURL, destinationURL: destinationURL)
        case .bzip2:
            try compressWithCodec(
                sourceURL: sourceURL,
                destinationURL: destinationURL,
                encode: Bzip2Codec.compress
            )
        case .xz:
            try compressWithCodec(
                sourceURL: sourceURL,
                destinationURL: destinationURL,
                encode: XZCodec.compress
            )
        case .tar:
            try compressToTar(sourceURL: sourceURL, destinationURL: destinationURL)
        case .sevenZip, .rar, .iso:
            throw ArchiveOperationError.unsupportedFormat
        }
    }

    private func compressToGzip(sourceURL: URL, destinationURL: URL) throws {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(
            atPath: sourceURL.path,
            isDirectory: &isDirectory
        ) else {
            throw ArchiveOperationError.sourceMissing
        }
        guard !isDirectory.boolValue else {
            throw ArchiveOperationError.unsupportedFormat
        }

        let data = try Data(contentsOf: sourceURL, options: [.mappedIfSafe])
        let compressed = try gzipCodec.compress(data: data)
        try compressed.write(to: destinationURL, options: [.atomic])
    }

    private func compressWithCodec(
        sourceURL: URL,
        destinationURL: URL,
        encode: (Data) throws -> Data
    ) throws {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(
            atPath: sourceURL.path,
            isDirectory: &isDirectory
        ) else {
            throw ArchiveOperationError.sourceMissing
        }
        guard !isDirectory.boolValue else {
            throw ArchiveOperationError.unsupportedFormat
        }

        let data = try Data(contentsOf: sourceURL, options: [.mappedIfSafe])
        let compressed = try encode(data)
        try compressed.write(to: destinationURL, options: [.atomic])
    }

    private func compressToTar(sourceURL: URL, destinationURL: URL) throws {
        var entries: [(name: String, url: URL)] = []
        collectTarEntries(from: sourceURL, into: &entries)

        guard !entries.isEmpty else { throw ArchiveOperationError.emptySource }

        var output = Data()
        let blockSize = 512

        for entry in entries {
            var isDirectory: ObjCBool = false
            FileManager.default.fileExists(
                atPath: entry.url.path,
                isDirectory: &isDirectory
            )

            var header = Data(repeating: 0, count: blockSize)
            let name = entry.name.hasSuffix("/")
                ? String(entry.name.dropLast())
                : entry.name

            func write(_ text: String, at offset: Int, length: Int) {
                let bytes = text.utf8.prefix(length)
                for (index, byte) in bytes.enumerated() {
                    header[offset + index] = byte
                }
            }

            let contentData: Data
            let mode: String
            let typeFlag: UInt8

            if isDirectory.boolValue {
                contentData = Data()
                mode = "0000755"
                typeFlag = 0x35
            } else {
                contentData = try Data(contentsOf: entry.url, options: [.mappedIfSafe])
                mode = "0000644"
                typeFlag = 0x30
            }

            write(name, at: 0, length: 100)
            write(mode, at: 100, length: 8)
            write("0000000", at: 108, length: 8) // uid
            write("0000000", at: 116, length: 8) // gid
            write(String(contentData.count, radix: 8), at: 124, length: 12)
            write("00000000000", at: 136, length: 12) // mtime
            write("        ", at: 148, length: 8) // checksum placeholder
            header[156] = typeFlag

            var checksum: UInt32 = 0
            for byte in header {
                checksum += UInt32(byte)
            }
            write(String(checksum, radix: 8), at: 148, length: 7)
            header[155] = 0

            output.append(header)
            if !contentData.isEmpty {
                output.append(contentData)
            }
            let padding = blockSize - (contentData.count % blockSize)
            if padding != blockSize {
                output.append(Data(repeating: 0, count: padding))
            }
        }

        output.append(Data(repeating: 0, count: blockSize * 2)) // end marker
        try output.write(to: destinationURL, options: [.atomic])
    }

    private func decompressSynchronously(archiveURL: URL) throws -> URL {
        guard FileManager.default.fileExists(atPath: archiveURL.path) else {
            throw ArchiveOperationError.sourceMissing
        }

        let fileExtension = archiveURL.pathExtension.lowercased()
        let outputDirectory = archiveURL.deletingPathExtension()

        switch fileExtension {
        case "zip":
            try ZipArchive.extract(
                archiveURL: archiveURL,
                to: outputDirectory
            )
        case "gz", "gzip":
            let data = try Data(contentsOf: archiveURL, options: [.mappedIfSafe])
            let decompressed = try gzipCodec.decompress(data: data)
            try decompressed.write(to: outputDirectory, options: [.atomic])
        case "bz2":
            let data = try Data(contentsOf: archiveURL, options: [.mappedIfSafe])
            let decompressed = try Bzip2Codec.decompress(data: data)
            try decompressed.write(to: outputDirectory, options: [.atomic])
        case "xz":
            let data = try Data(contentsOf: archiveURL, options: [.mappedIfSafe])
            let decompressed = try XZCodec.decompress(data: data)
            try decompressed.write(to: outputDirectory, options: [.atomic])
        case "tar":
            let data = try Data(contentsOf: archiveURL, options: [.mappedIfSafe])
            try extractTar(data: data, outputDirectory: outputDirectory)
        case "tgz":
            let data = try Data(contentsOf: archiveURL, options: [.mappedIfSafe])
            let decompressed = try gzipCodec.decompress(data: data)
            try extractTar(data: decompressed, outputDirectory: outputDirectory)
        default:
            throw ArchiveOperationError.unsupportedFormat
        }

        return outputDirectory
    }

    // MARK: - TAR

    private func collectTarEntries(
        from url: URL,
        into entries: inout [(name: String, url: URL)],
        prefix: String = ""
    ) {
        var isDirectory: ObjCBool = false
        FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)

        if isDirectory.boolValue {
            let currentPrefix = prefix.isEmpty ? url.lastPathComponent : prefix
            if let contents = try? FileManager.default.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: nil
            ) {
                for child in contents {
                    let childName = child.lastPathComponent
                    collectTarEntries(
                        from: child,
                        into: &entries,
                        prefix: "\(currentPrefix)/\(childName)"
                    )
                }
            }
            entries.append((name: currentPrefix + "/", url: url))
        } else {
            entries.append((name: prefix.isEmpty ? url.lastPathComponent : prefix, url: url))
        }
    }

    private func extractTar(data: Data, outputDirectory: URL) throws {
        try FileManager.default.createDirectory(
            at: outputDirectory,
            withIntermediateDirectories: true
        )
        guard data.count >= 512 else {
            throw ArchiveOperationError.invalidArchive
        }

        var offset = 0
        while offset + 512 <= data.count {
            let header = data.subdata(in: offset..<(offset + 512))
            let nameData = header.prefix(100)
            guard let name = String(
                data: nameData,
                encoding: .utf8
            )?.trimmingCharacters(in: CharacterSet(charactersIn: "\0")),
                !name.isEmpty else {
                break
            }

            let sizeField = header[124..<136]
            let sizeText = String(
                data: Data(sizeField),
                encoding: .ascii
            )?.trimmingCharacters(in: CharacterSet(charactersIn: " \0"))
            let size = Int(sizeText ?? "0", radix: 8) ?? 0
            guard size >= 0, offset + 512 + size <= data.count else {
                throw ArchiveOperationError.invalidArchive
            }

            let typeFlag = header[156]
            let filePath = try safeExtractionURL(
                for: name,
                inside: outputDirectory
            )

            if typeFlag == 0x35 { // directory entry
                try? FileManager.default.createDirectory(
                    at: filePath,
                    withIntermediateDirectories: true
                )
            } else if typeFlag == 0 || typeFlag == 0x30 || typeFlag == 0x00 {
                try FileManager.default.createDirectory(
                    at: filePath.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                if size > 0 {
                    let content = data.subdata(
                        in: (offset + 512)..<(offset + 512 + size)
                    )
                    try content.write(to: filePath, options: [.atomic])
                } else {
                    try Data().write(to: filePath)
                }
            }

            offset += 512 + ((size + 511) / 512) * 512
        }
    }

    private func safeExtractionURL(
        for entryName: String,
        inside outputDirectory: URL
    ) throws -> URL {
        guard !entryName.hasPrefix("/"),
              !entryName.contains("\\") else {
            throw ArchiveOperationError.invalidArchive
        }

        let root = outputDirectory.standardizedFileURL
        let candidate = root
            .appendingPathComponent(entryName)
            .standardizedFileURL
        let rootPrefix = root.path.hasSuffix("/") ? root.path : root.path + "/"

        guard candidate.path.hasPrefix(rootPrefix) else {
            throw ArchiveOperationError.invalidArchive
        }
        return candidate
    }
}
