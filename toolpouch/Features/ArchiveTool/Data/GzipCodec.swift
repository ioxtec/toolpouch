import Compression
import Foundation
import zlib

/// GZIP codec built on the system Compression framework.
/// The framework's `COMPRESSION_ZLIB` algorithm emits raw DEFLATE
/// (RFC 1951), so this type adds the GZIP header and CRC32 trailer
/// (RFC 1952) when compressing and strips them when decompressing.
/// Streaming is used throughout so files are never fully loaded into memory.
nonisolated struct GzipCodec: Sendable {
    static let chunkSize = 1 << 16

    func compress(data: Data) throws -> Data {
        guard !data.isEmpty else { return Data() }

        var output = Data()
        output.append(Self.gzipHeader)
        let rawDeflate = try stream(
            data: data,
            operation: COMPRESSION_STREAM_ENCODE
        )
        output.append(rawDeflate)
        output.append(Self.crc32Data(of: data))
        output.append(Self.isize(of: data))
        return output
    }

    func decompress(data: Data) throws -> Data {
        guard data.count >= 18 else { throw ArchiveOperationError.invalidArchive }
        guard data[data.startIndex] == 0x1f, data[data.startIndex + 1] == 0x8b else {
            throw ArchiveOperationError.invalidArchive
        }

        let flags = data[data.startIndex + 3]
        var offset = 10
        if flags & 0x04 != 0 {
            offset += 2 // FEXTRA length field
        }
        if flags & 0x08 != 0 {
            while offset < data.count, data[data.startIndex + offset] != 0 {
                offset += 1
            }
            offset += 1 // FNAME terminator
        }
        if flags & 0x10 != 0 {
            while offset < data.count, data[data.startIndex + offset] != 0 {
                offset += 1
            }
            offset += 1 // FCOMMENT terminator
        }
        if flags & 0x02 != 0 {
            offset += 2 // FHCRC
        }
        guard offset + 8 <= data.count else {
            throw ArchiveOperationError.invalidArchive
        }

        let payload = data.subdata(
            in: (data.startIndex + offset)..<(data.endIndex - 8)
        )
        let raw = try stream(data: payload, operation: COMPRESSION_STREAM_DECODE)
        let actualCRC = Self.crc32(of: raw)
        let storedCRC: UInt32 = data.withUnsafeBytes {
            $0.loadUnaligned(fromByteOffset: data.count - 8, as: UInt32.self)
        }
        guard actualCRC == storedCRC else {
            throw ArchiveOperationError.invalidArchive
        }
        return raw
    }

    private static var gzipHeader: Data {
        // ID1 ID2 CM FLG MTIME XFL OS
        Data([0x1f, 0x8b, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03])
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

    private static func crc32Data(of data: Data) -> Data {
        var littleEndian = crc32(of: data).littleEndian
        return Data(bytes: &littleEndian, count: 4)
    }

    private static func isize(of data: Data) -> Data {
        var length = UInt32(data.count).littleEndian
        return Data(bytes: &length, count: 4)
    }

    private func stream(
        data: Data,
        operation: compression_stream_operation
    ) throws -> Data {
        let outputBufferSize = max(
            Int(compression_decode_scratch_buffer_size(COMPRESSION_ZLIB)),
            Self.chunkSize
        )

        return try data.withUnsafeBytes { rawBuffer in
            var dummyStorage = [UInt8](repeating: 0, count: 1)
            var stream = compression_stream(
                dst_ptr: dummyStorage.withUnsafeMutableBufferPointer { $0.baseAddress! },
                dst_size: 0,
                src_ptr: dummyStorage.withUnsafeBufferPointer { $0.baseAddress! },
                src_size: 0,
                state: nil
            )
            let status = compression_stream_init(&stream, operation, COMPRESSION_ZLIB)
            guard status != COMPRESSION_STATUS_ERROR else {
                throw ArchiveOperationError.archiveFailed
            }
            defer { compression_stream_destroy(&stream) }

            var outputBuffer = [UInt8](repeating: 0, count: outputBufferSize)
            var result = Data()
            var inputIndex = data.startIndex
            var failed = false

            while !failed {
                if stream.src_size == 0 {
                    let remaining = data.distance(from: inputIndex, to: data.endIndex)
                    let chunk = min(remaining, Self.chunkSize)
                    if chunk > 0 {
                        let range = inputIndex..<data.index(inputIndex, offsetBy: chunk)
                        stream.src_ptr = rawBuffer[range].bindMemory(to: UInt8.self).baseAddress!
                        stream.src_size = chunk
                        inputIndex = range.endIndex
                    } else {
                        stream.src_ptr = dummyStorage.withUnsafeBufferPointer { $0.baseAddress! }
                        stream.src_size = 0
                    }
                }

                let flags: Int32 = inputIndex == data.endIndex
                    ? Int32(COMPRESSION_STREAM_FINALIZE.rawValue)
                    : 0
                stream.dst_ptr = outputBuffer.withUnsafeMutableBytes {
                    $0.bindMemory(to: UInt8.self).baseAddress!
                }
                stream.dst_size = outputBufferSize

                let processStatus = compression_stream_process(&stream, flags)
                if processStatus == COMPRESSION_STATUS_ERROR {
                    failed = true
                    break
                }

                let produced = outputBufferSize - stream.dst_size
                if produced > 0 {
                    result.append(outputBuffer, count: produced)
                }

                if processStatus == COMPRESSION_STATUS_END {
                    break
                }
            }

            guard !result.isEmpty else {
                throw ArchiveOperationError.archiveFailed
            }
            return result
        }
    }
}
