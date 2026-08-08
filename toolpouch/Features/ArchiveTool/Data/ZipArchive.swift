import Compression
import Foundation
import zlib

/// Minimal, dependency-free ZIP archive writer and reader.
/// Implements the ZIP file format (local file headers, central directory
/// and end-of-central-directory record) with DEFLATE compression provided
/// by the system Compression framework. Reads both stored (method 0) and
/// deflated (method 8) entries.
nonisolated enum ZipArchive {
    static func create(
        from sourceURL: URL,
        to destinationURL: URL,
        fileManager: FileManager = .default
    ) throws {
        guard fileManager.fileExists(atPath: sourceURL.path) else {
            throw ArchiveOperationError.sourceMissing
        }

        var files: [(name: String, url: URL)] = []
        collectEntries(from: sourceURL, into: &files, fileManager: fileManager)
        guard !files.isEmpty else { throw ArchiveOperationError.emptySource }

        var localHeaders = Data()
        var centralDirectory = Data()
        let codec = GzipCodec()

        for entry in files {
            let entryName = entry.name
            guard let nameData = entryName.data(using: .utf8) else {
                throw ArchiveOperationError.archiveFailed
            }

            var isDirectory: ObjCBool = false
            fileManager.fileExists(atPath: entry.url.path, isDirectory: &isDirectory)

            let contentData: Data
            let crcValue: UInt32
            let compressedData: Data
            let method: UInt16
            let size: UInt32

            if isDirectory.boolValue {
                contentData = Data()
                crcValue = 0
                compressedData = Data()
                method = 0
                size = 0
            } else {
                contentData = try Data(contentsOf: entry.url, options: [.mappedIfSafe])
                size = UInt32(contentData.count)
                crcValue = crc32(of: contentData)
                let raw = try codec.compress(data: contentData)
                if raw.count < contentData.count {
                    compressedData = raw
                    method = 8
                } else {
                    compressedData = contentData
                    method = 0
                }
            }

            let offset = localHeaders.count

            var localHeader = Data()
            localHeader.append(contentsOf: [0x50, 0x4b, 0x03, 0x04]) // signature
            localHeader.append(contentsOf: littleEndian(UInt16(20))) // version needed
            localHeader.append(contentsOf: littleEndian(UInt16(0))) // flags
            localHeader.append(contentsOf: littleEndian(method)) // method
            localHeader.append(contentsOf: littleEndian(UInt16(0))) // mod time
            localHeader.append(contentsOf: littleEndian(UInt16(0))) // mod date
            localHeader.append(contentsOf: littleEndian(crcValue)) // crc
            localHeader.append(contentsOf: littleEndian(UInt32(compressedData.count))) // compressed size
            localHeader.append(contentsOf: littleEndian(size)) // uncompressed size
            localHeader.append(contentsOf: littleEndian(UInt16(nameData.count))) // name length
            localHeader.append(contentsOf: littleEndian(UInt16(0))) // extra length
            localHeader.append(nameData)
            localHeaders.append(localHeader)
            localHeaders.append(compressedData)

            var centralEntry = Data()
            centralEntry.append(contentsOf: [0x50, 0x4b, 0x01, 0x02]) // signature
            centralEntry.append(contentsOf: littleEndian(UInt16(20))) // version made by
            centralEntry.append(contentsOf: littleEndian(UInt16(20))) // version needed
            centralEntry.append(contentsOf: littleEndian(UInt16(0))) // flags
            centralEntry.append(contentsOf: littleEndian(method)) // method
            centralEntry.append(contentsOf: littleEndian(UInt16(0))) // mod time
            centralEntry.append(contentsOf: littleEndian(UInt16(0))) // mod date
            centralEntry.append(contentsOf: littleEndian(crcValue)) // crc
            centralEntry.append(contentsOf: littleEndian(UInt32(compressedData.count)))
            centralEntry.append(contentsOf: littleEndian(size))
            centralEntry.append(contentsOf: littleEndian(UInt16(nameData.count)))
            centralEntry.append(contentsOf: littleEndian(UInt16(0))) // extra length
            centralEntry.append(contentsOf: littleEndian(UInt16(0))) // comment length
            centralEntry.append(contentsOf: littleEndian(UInt16(0))) // disk number
            centralEntry.append(contentsOf: littleEndian(UInt16(0))) // internal attrs
            centralEntry.append(contentsOf: littleEndian(UInt32(0))) // external attrs
            centralEntry.append(contentsOf: littleEndian(UInt32(offset))) // local header offset
            centralEntry.append(nameData)
            centralDirectory.append(centralEntry)
        }

        let centralDirectorySize = centralDirectory.count
        let centralDirectoryOffset = localHeaders.count

        var endRecord = Data()
        endRecord.append(contentsOf: [0x50, 0x4b, 0x05, 0x06]) // signature
        endRecord.append(contentsOf: littleEndian(UInt16(0))) // disk number
        endRecord.append(contentsOf: littleEndian(UInt16(0))) // disk with central dir
        endRecord.append(contentsOf: littleEndian(UInt16(files.count))) // entries on disk
        endRecord.append(contentsOf: littleEndian(UInt16(files.count))) // total entries
        endRecord.append(contentsOf: littleEndian(UInt32(centralDirectorySize)))
        endRecord.append(contentsOf: littleEndian(UInt32(centralDirectoryOffset)))
        endRecord.append(contentsOf: littleEndian(UInt16(0))) // comment length

        var archive = Data()
        archive.append(localHeaders)
        archive.append(centralDirectory)
        archive.append(endRecord)
        try archive.write(to: destinationURL, options: [.atomic])
    }

    static func extract(
        archiveURL: URL,
        to destinationDirectory: URL,
        fileManager: FileManager = .default
    ) throws {
        let data = try Data(contentsOf: archiveURL, options: [.mappedIfSafe])
        guard data.count > 22 else { throw ArchiveOperationError.invalidArchive }

        let eocdOffset = findEndOfCentralDirectory(in: data)
        guard eocdOffset >= 0 else { throw ArchiveOperationError.invalidArchive }

        let eocdStart = data.startIndex + eocdOffset
        let entryCount = Int(readUInt16(data, at: eocdStart + 10))
        let centralSize = Int(readUInt32(data, at: eocdStart + 12))
        let centralOffset = Int(readUInt32(data, at: eocdStart + 16))

        guard centralOffset >= 0, centralSize >= 0,
              centralOffset + centralSize <= data.count else {
            throw ArchiveOperationError.invalidArchive
        }

        try fileManager.createDirectory(
            at: destinationDirectory,
            withIntermediateDirectories: true
        )

        let codec = GzipCodec()
        var cursor = data.startIndex + centralOffset

        for _ in 0..<entryCount {
            guard cursor + 46 <= data.count,
                  data[cursor] == 0x50,
                  data[cursor + 1] == 0x4b,
                  data[cursor + 2] == 0x01,
                  data[cursor + 3] == 0x02 else {
                throw ArchiveOperationError.invalidArchive
            }

            let method = readUInt16(data, at: cursor + 10)
            let crcStored = readUInt32(data, at: cursor + 16)
            let compressedSize = Int(readUInt32(data, at: cursor + 20))
            let uncompressedSize = Int(readUInt32(data, at: cursor + 24))
            let nameLength = Int(readUInt16(data, at: cursor + 28))
            let extraLength = Int(readUInt16(data, at: cursor + 30))
            let commentLength = Int(readUInt16(data, at: cursor + 32))
            let localOffset = Int(readUInt32(data, at: cursor + 42))

            guard cursor + 46 + nameLength <= data.count,
                  let name = String(
                      data: data.subdata(
                          in: (cursor + 46)..<(cursor + 46 + nameLength)
                      ),
                      encoding: .utf8
                  ) else {
                throw ArchiveOperationError.invalidArchive
            }

            let normalizedName = name.hasSuffix("/")
                ? String(name.dropLast())
                : name
            guard !normalizedName.isEmpty,
                  !normalizedName.contains("..") else {
                throw ArchiveOperationError.invalidArchive
            }

            let destinationPath = destinationDirectory
                .appendingPathComponent(normalizedName)

            if name.hasSuffix("/") {
                try fileManager.createDirectory(
                    at: destinationPath,
                    withIntermediateDirectories: true
                )
            } else {
                let compressedData = try readLocalEntry(
                    data: data,
                    localOffset: localOffset,
                    compressedSize: compressedSize
                )
                let content: Data
                switch method {
                case 0:
                    content = compressedData
                case 8:
                    content = try codec.decompress(data: compressedData)
                default:
                    throw ArchiveOperationError.unsupportedFormat
                }
                guard content.count == uncompressedSize else {
                    throw ArchiveOperationError.invalidArchive
                }
                guard crc32(of: content) == crcStored else {
                    throw ArchiveOperationError.invalidArchive
                }
                try fileManager.createDirectory(
                    at: destinationPath.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                try content.write(to: destinationPath, options: [.atomic])
            }

            cursor += 46 + nameLength + extraLength + commentLength
        }
    }

    // MARK: - Helpers

    private static func collectEntries(
        from url: URL,
        into entries: inout [(name: String, url: URL)],
        fileManager: FileManager,
        prefix: String = ""
    ) {
        var isDirectory: ObjCBool = false
        fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory)

        if isDirectory.boolValue {
            guard let contents = try? fileManager.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: nil
            ) else { return }

            let currentPrefix = prefix.isEmpty ? url.lastPathComponent : prefix
            for child in contents {
                let childName = child.lastPathComponent
                let childPrefix = "\(currentPrefix)/\(childName)"
                collectEntries(
                    from: child,
                    into: &entries,
                    fileManager: fileManager,
                    prefix: childPrefix
                )
            }
            if prefix.isEmpty {
                entries.append((name: currentPrefix + "/", url: url))
            }
        } else {
            let entryName = prefix.isEmpty ? url.lastPathComponent : prefix
            entries.append((name: entryName, url: url))
        }
    }

    private static func readLocalEntry(
        data: Data,
        localOffset: Int,
        compressedSize: Int
    ) throws -> Data {
        let start = data.startIndex + localOffset
        guard start + 30 <= data.count,
              data[start] == 0x50,
              data[start + 1] == 0x4b,
              data[start + 2] == 0x03,
              data[start + 3] == 0x04 else {
            throw ArchiveOperationError.invalidArchive
        }
        let nameLength = Int(readUInt16(data, at: start + 26))
        let extraLength = Int(readUInt16(data, at: start + 28))
        let contentStart = start + 30 + nameLength + extraLength
        guard contentStart + compressedSize <= data.count else {
            throw ArchiveOperationError.invalidArchive
        }
        return data.subdata(in: contentStart..<(contentStart + compressedSize))
    }

    private static func findEndOfCentralDirectory(in data: Data) -> Int {
        let minimumSize = 22
        guard data.count >= minimumSize else { return -1 }
        let searchLimit = min(data.count - minimumSize, 65_557)
        for backstep in 0...searchLimit {
            let index = data.endIndex - 1 - backstep - 21
            guard index >= data.startIndex, index + 4 <= data.endIndex else { continue }
            if data[index] == 0x50, data[index + 1] == 0x4b,
               data[index + 2] == 0x05, data[index + 3] == 0x06 {
                return index - data.startIndex
            }
        }
        return -1
    }

    private static func crc32(of data: Data) -> UInt32 {
        data.withUnsafeBytes { buffer in
            UInt32(truncatingIfNeeded: zlib.crc32(
                0,
                buffer.bindMemory(to: UInt8.self).baseAddress,
                uInt(buffer.count)
            ))
        }
    }

    private static func littleEndian<T: FixedWidthInteger>(_ value: T) -> [UInt8] {
        var little = value.littleEndian
        return withUnsafeBytes(of: &little) { Array($0) }
    }

    private static func readUInt16(_ data: Data, at offset: Int) -> UInt16 {
        guard offset + 2 <= data.count else { return 0 }
        return UInt16(data[offset]) | (UInt16(data[offset + 1]) << 8)
    }

    private static func readUInt32(_ data: Data, at offset: Int) -> UInt32 {
        guard offset + 4 <= data.count else { return 0 }
        return UInt32(data[offset])
            | (UInt32(data[offset + 1]) << 8)
            | (UInt32(data[offset + 2]) << 16)
            | (UInt32(data[offset + 3]) << 24)
    }
}
