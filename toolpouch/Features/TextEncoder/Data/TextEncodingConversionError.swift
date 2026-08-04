import Foundation

nonisolated enum TextEncodingConversionError: LocalizedError {
    case invalidEncodedValue(BinaryTextEncoding)
    case invalidUTF8

    var errorDescription: String? {
        switch self {
        case let .invalidEncodedValue(encoding):
            "The input is not valid \(encoding.title)."
        case .invalidUTF8:
            "The decoded data is not valid UTF-8 text."
        }
    }
}
