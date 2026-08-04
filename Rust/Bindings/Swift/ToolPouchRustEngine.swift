import Foundation
import ToolPouchRustFFI

public enum ToolPouchRustEngineError: Error {
    case invalidArgument
    case unexpectedStatus(Int32)
}

public struct ToolPouchRustEngine: Sendable {
    public init() {}

    public var apiVersion: UInt32 {
        toolpouch_engine_api_version()
    }

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
}
