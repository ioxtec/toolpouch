import Foundation

nonisolated enum TextEncodingConversionError: LocalizedError {
    case invalidEncodedValue(BinaryTextEncoding)
    case invalidUTF8

    var errorDescription: String? {
        switch self {
        case let .invalidEncodedValue(encoding):
            String(format: "The input is not valid %@.".localizedInterfaceText, encoding.title)
        case .invalidUTF8:
            "The decoded data is not valid UTF-8 text.".localizedInterfaceText
        }
    }
}
