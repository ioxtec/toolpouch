import Foundation
import ToolPouchRustFFI

nonisolated public enum ToolPouchRustEngineError: Error {
    case invalidArgument
    case fileAccessFailed
    case unsupportedImageFormat
    case invalidImage
    case encodingFailed
    case unexpectedStatus(Int32)
}

nonisolated public struct ToolPouchRustImageMetadata: Equatable, Sendable {
    public let cameraMake: String?
    public let cameraModel: String?
    public let lensModel: String?
    public let capturedAt: String?
    public let exposureTime: String?
    public let aperture: String?
    public let iso: String?
    public let focalLength: String?
    public let orientation: String?
    public let latitude: Double?
    public let longitude: Double?
}

nonisolated public enum ToolPouchRustImageOutputFormat: UInt32, Sendable {
    case png = 1
    case jpeg = 2
    case webP = 3
}

nonisolated public struct ToolPouchRustImageInfo: Equatable, Sendable {
    nonisolated public enum Format: UInt32, Sendable {
        case unknown = 0
        case png = 1
        case jpeg = 2
        case gif = 3
        case webP = 4
        case tiff = 5
        case bmp = 6
        case ico = 7
        case pnm = 8
    }

    nonisolated public enum ColorModel: UInt32, Sendable {
        case unknown = 0
        case grayscale = 1
        case grayscaleAlpha = 2
        case rgb = 3
        case rgba = 4
    }

    public let width: UInt32
    public let height: UInt32
    public let format: Format
    public let colorModel: ColorModel
    public let channelCount: UInt8
    public let bitsPerChannel: UInt8
    public let hasAlpha: Bool
    public let fileSize: UInt64
}

nonisolated public struct ToolPouchRustEngine: Sendable {
    public init() {}

    public var apiVersion: UInt32 {
        toolpouch_engine_api_version()
    }

    /// Calculates CRC-32 in Rust while presenting Swift errors instead of raw status codes.
    public func crc32(for data: Data) throws -> UInt32 {
        var checksum: UInt32 = 0
        let status = data.withUnsafeBytes { buffer in
            toolpouch_engine_crc32(
                buffer.bindMemory(to: UInt8.self).baseAddress,
                buffer.count,
                &checksum
            )
        }

        switch status {
        case TOOLPOUCH_ENGINE_STATUS_OK:
            return checksum
        case TOOLPOUCH_ENGINE_STATUS_INVALID_ARGUMENT:
            throw ToolPouchRustEngineError.invalidArgument
        default:
            throw ToolPouchRustEngineError.unexpectedStatus(status)
        }
    }

    /// Reads image metadata through Rust while holding sandbox access for the duration of the call.
    public func inspectImage(at url: URL) throws -> ToolPouchRustImageInfo {
        let didStartAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        var output = ToolPouchImageInfo()
        let path = Data(url.path.utf8)
        let status = path.withUnsafeBytes { buffer in
            toolpouch_image_inspect(
                buffer.bindMemory(to: UInt8.self).baseAddress,
                buffer.count,
                &output
            )
        }
        try validateImageStatus(status)

        return ToolPouchRustImageInfo(
            width: output.width,
            height: output.height,
            format: .init(rawValue: output.format) ?? .unknown,
            colorModel: .init(rawValue: output.color_model) ?? .unknown,
            channelCount: output.channel_count,
            bitsPerChannel: output.bits_per_channel,
            hasAlpha: output.has_alpha != 0,
            fileSize: output.file_size
        )
    }

    public func readImageMetadata(at url: URL) throws -> ToolPouchRustImageMetadata {
        try withSecurityScopedAccess(to: url) {
            var output = ToolPouchImageMetadata()
            let path = Data(url.path.utf8)
            let status = path.withUnsafeBytes { buffer in
                toolpouch_image_read_metadata(
                    buffer.bindMemory(to: UInt8.self).baseAddress,
                    buffer.count,
                    &output
                )
            }
            try validateImageStatus(status)
            let hasLocation = output.has_location != 0

            return ToolPouchRustImageMetadata(
                cameraMake: string(from: output.camera_make),
                cameraModel: string(from: output.camera_model),
                lensModel: string(from: output.lens_model),
                capturedAt: string(from: output.captured_at),
                exposureTime: string(from: output.exposure_time),
                aperture: string(from: output.aperture),
                iso: string(from: output.iso),
                focalLength: string(from: output.focal_length),
                orientation: string(from: output.orientation),
                latitude: hasLocation ? output.latitude : nil,
                longitude: hasLocation ? output.longitude : nil
            )
        }
    }

    public func transformImage(
        at inputURL: URL,
        savingTo outputURL: URL,
        maximumWidth: UInt32,
        maximumHeight: UInt32,
        format: ToolPouchRustImageOutputFormat,
        quality: UInt8
    ) throws {
        try withSecurityScopedAccess(to: inputURL) {
            try withSecurityScopedAccess(to: outputURL) {
                let input = Data(inputURL.path.utf8)
                let output = Data(outputURL.path.utf8)
                let status = input.withUnsafeBytes { inputBuffer in
                    output.withUnsafeBytes { outputBuffer in
                        toolpouch_image_transform(
                            inputBuffer.bindMemory(to: UInt8.self).baseAddress,
                            inputBuffer.count,
                            outputBuffer.bindMemory(to: UInt8.self).baseAddress,
                            outputBuffer.count,
                            maximumWidth,
                            maximumHeight,
                            format.rawValue,
                            quality
                        )
                    }
                }
                try validateImageStatus(status)
            }
        }
    }

    private func validateImageStatus(_ status: Int32) throws {
        switch status {
        case TOOLPOUCH_ENGINE_STATUS_OK:
            return
        case TOOLPOUCH_ENGINE_STATUS_INVALID_ARGUMENT:
            throw ToolPouchRustEngineError.invalidArgument
        case TOOLPOUCH_ENGINE_STATUS_IO_ERROR:
            throw ToolPouchRustEngineError.fileAccessFailed
        case TOOLPOUCH_ENGINE_STATUS_UNSUPPORTED_FORMAT:
            throw ToolPouchRustEngineError.unsupportedImageFormat
        case TOOLPOUCH_ENGINE_STATUS_INVALID_IMAGE:
            throw ToolPouchRustEngineError.invalidImage
        case TOOLPOUCH_ENGINE_STATUS_ENCODING_FAILED:
            throw ToolPouchRustEngineError.encodingFailed
        default:
            throw ToolPouchRustEngineError.unexpectedStatus(status)
        }
    }

    private func withSecurityScopedAccess<T>(
        to url: URL,
        operation: () throws -> T
    ) throws -> T {
        let didStartAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }
        return try operation()
    }

    private func string<T>(from storage: T) -> String? {
        withUnsafeBytes(of: storage) { buffer in
            let bytes = buffer.prefix { $0 != 0 }
            guard !bytes.isEmpty else { return nil }
            return String(decoding: bytes, as: UTF8.self)
        }
    }
}
