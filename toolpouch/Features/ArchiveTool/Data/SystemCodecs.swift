import Foundation

// BZIP2: single-stream block compression from the system bzip2 library.
#if canImport(bzlib)
import bzlib
#endif

// XZ: the .xz container (RFC 7931, LZMA2) from the system liblzma.
#if canImport(lzma)
import lzma
#endif

/// BZIP2 codec backed by the system `libbz2` (BZ2_bz* streaming API).
/// Available on macOS, iOS and watchOS through the SDK's libbz2 module.
nonisolated enum Bzip2Codec {
    static let blockSize = 9 // 900 KB blocks, strongest bzip2 ratio
    static let chunkSize = 1 << 16

    static func compress(data: Data) throws -> Data {
        var stream = bz_stream()
        let initStatus = BZ2_bzCompressInit(&stream, Int32(blockSize), 0, 0)
        guard initStatus == BZ_OK else { throw ArchiveOperationError.archiveFailed }
        defer { BZ2_bzCompressEnd(&stream) }

        var source = Array(data)
        let sourceCount = source.count
        return try source.withUnsafeMutableBytes { sourceBuffer in
            var output = Data()
            var outputBuffer = [UInt8](repeating: 0, count: chunkSize)
            var inputIndex = 0
            var finished = false

            while !finished {
                if stream.avail_in == 0 {
                    let remaining = sourceCount - inputIndex
                    let chunk = min(remaining, chunkSize)
                    if chunk > 0 {
                        stream.next_in = sourceBuffer.baseAddress!
                            .advanced(by: inputIndex)
                            .bindMemory(to: Int8.self, capacity: chunk)
                        stream.avail_in = UInt32(chunk)
                        inputIndex += chunk
                    } else {
                        stream.next_in = nil
                        stream.avail_in = 0
                    }
                }

                stream.next_out = outputBuffer.withUnsafeMutableBytes {
                    $0.bindMemory(to: Int8.self).baseAddress
                }
                stream.avail_out = UInt32(outputBuffer.count)

                let action: Int32 = inputIndex == sourceCount ? BZ_FINISH : BZ_RUN
                let status = BZ2_bzCompress(&stream, action)
                let produced = outputBuffer.count - Int(stream.avail_out)
                if produced > 0 {
                    output.append(outputBuffer, count: produced)
                }

                if status == BZ_STREAM_END {
                    finished = true
                } else if status < 0 {
                    throw ArchiveOperationError.archiveFailed
                }
            }
            return output
        }
    }

    static func decompress(data: Data) throws -> Data {
        guard !data.isEmpty else { throw ArchiveOperationError.invalidArchive }

        var stream = bz_stream()
        let initStatus = BZ2_bzDecompressInit(&stream, 0, 0)
        guard initStatus == BZ_OK else { throw ArchiveOperationError.archiveFailed }
        defer { BZ2_bzDecompressEnd(&stream) }

        var source = Array(data)
        let sourceCount = source.count
        return try source.withUnsafeMutableBytes { sourceBuffer in
            var output = Data()
            var outputBuffer = [UInt8](repeating: 0, count: chunkSize)
            var inputIndex = 0
            var finished = false

            while !finished {
                if stream.avail_in == 0 {
                    let remaining = sourceCount - inputIndex
                    let chunk = min(remaining, chunkSize)
                    if chunk > 0 {
                        stream.next_in = sourceBuffer.baseAddress!
                            .advanced(by: inputIndex)
                            .bindMemory(to: Int8.self, capacity: chunk)
                        stream.avail_in = UInt32(chunk)
                        inputIndex += chunk
                    } else {
                        stream.next_in = nil
                        stream.avail_in = 0
                    }
                }

                stream.next_out = outputBuffer.withUnsafeMutableBytes {
                    $0.bindMemory(to: Int8.self).baseAddress
                }
                stream.avail_out = UInt32(outputBuffer.count)

                let status = BZ2_bzDecompress(&stream)
                let produced = outputBuffer.count - Int(stream.avail_out)
                if produced > 0 {
                    output.append(outputBuffer, count: produced)
                }

                if status == BZ_STREAM_END {
                    finished = true
                } else if status != BZ_OK {
                    throw ArchiveOperationError.invalidArchive
                } else if inputIndex == sourceCount,
                          stream.avail_in == 0,
                          produced == 0 {
                    // BZ2_bzDecompress keeps returning BZ_OK when a valid-looking
                    // stream is truncated and no more input can arrive.
                    throw ArchiveOperationError.invalidArchive
                }
            }
            return output
        }
    }
}

/// XZ codec backed by the system `liblzma` using the one-shot
/// `lzma_easy_buffer_encode` / `lzma_stream_buffer_decode` API.
nonisolated enum XZCodec {
    static let preset: UInt32 = 6 // default LZMA2 preset, matches xz -6

    static func compress(data: Data) throws -> Data {
        let bound = lzma_stream_buffer_bound(data.count)
        var compressed = [UInt8](repeating: 0, count: bound)
        var outputPosition: size_t = 0

        let status = data.withUnsafeBytes { sourceBuffer in
            compressed.withUnsafeMutableBytes { destinationBuffer in
                lzma_easy_buffer_encode(
                    preset,
                    LZMA_CHECK_CRC64,
                    nil,
                    sourceBuffer.bindMemory(to: UInt8.self).baseAddress,
                    data.count,
                    destinationBuffer.bindMemory(to: UInt8.self).baseAddress,
                    &outputPosition,
                    bound
                )
            }
        }
        guard status == LZMA_OK else { throw ArchiveOperationError.archiveFailed }
        return Data(compressed.prefix(outputPosition))
    }

    static func decompress(data: Data) throws -> Data {
        guard !data.isEmpty else { throw ArchiveOperationError.invalidArchive }

        var stream = lzma_stream()
        let initStatus = lzma_stream_decoder(&stream, UInt64.max, 0)
        guard initStatus == LZMA_OK else { throw ArchiveOperationError.invalidArchive }
        defer { lzma_end(&stream) }

        var source = Array(data)
        let sourceCount = source.count
        var output = Data()
        var outputBuffer = [UInt8](repeating: 0, count: 1 << 16)
        var inputIndex = 0
        var finished = false

        return try source.withUnsafeMutableBytes { sourceBuffer in
            while !finished {
                if stream.avail_in == 0 {
                    let remaining = sourceCount - inputIndex
                    let chunk = min(remaining, 1 << 16)
                    if chunk > 0 {
                        stream.next_in = UnsafeRawPointer(sourceBuffer.baseAddress!)
                            .advanced(by: inputIndex)
                            .bindMemory(to: UInt8.self, capacity: chunk)
                        stream.avail_in = chunk
                        inputIndex += chunk
                    } else {
                        stream.next_in = nil
                        stream.avail_in = 0
                    }
                }

                stream.next_out = outputBuffer.withUnsafeMutableBytes {
                    $0.bindMemory(to: UInt8.self).baseAddress
                }
                stream.avail_out = outputBuffer.count

                let action: lzma_action = inputIndex == sourceCount ? LZMA_FINISH : LZMA_RUN
                let status = lzma_code(&stream, action)
                let produced = outputBuffer.count - Int(stream.avail_out)
                if produced > 0 {
                    output.append(outputBuffer, count: produced)
                }

                if status == LZMA_STREAM_END {
                    finished = true
                } else if status != LZMA_OK {
                    throw ArchiveOperationError.invalidArchive
                } else if inputIndex == sourceCount,
                          stream.avail_in == 0,
                          produced == 0 {
                    throw ArchiveOperationError.invalidArchive
                }
            }
            return output
        }
    }
}
