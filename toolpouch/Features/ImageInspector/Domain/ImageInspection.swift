import Foundation

nonisolated struct ImageInspection: Equatable, Sendable {
    let width: UInt32
    let height: UInt32
    let format: String
    let colorModel: String
    let channelCount: UInt8
    let bitsPerChannel: UInt8
    let hasAlpha: Bool
    let fileSize: UInt64

    var dimensions: String {
        "\(width) × \(height) px"
    }

    var megapixels: String {
        let value = Double(width) * Double(height) / 1_000_000
        return value.formatted(.number.precision(.fractionLength(0...2))) + " MP"
    }

    var formattedFileSize: String {
        ByteCountFormatter.string(
            fromByteCount: Int64(clamping: fileSize),
            countStyle: .file
        )
    }

    var bitDepth: String {
        "\(bitsPerChannel)-bit per channel"
    }
}
