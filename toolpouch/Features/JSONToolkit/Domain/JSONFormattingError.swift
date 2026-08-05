import Foundation

nonisolated enum JSONFormattingError: LocalizedError, Equatable, Sendable {
    case emptyInput
    case invalidJSON(String)
    case outputEncodingFailed

    var errorDescription: String? {
        switch self {
        case .emptyInput:
            "Enter JSON to validate and format."
        case let .invalidJSON(details):
            details
        case .outputEncodingFailed:
            "The formatted JSON could not be converted to text."
        }
    }
}
