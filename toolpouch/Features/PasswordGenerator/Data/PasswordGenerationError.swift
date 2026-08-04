import Foundation

nonisolated enum PasswordGenerationError: LocalizedError {
    case invalidLength
    case noCharacterSetSelected
    case wordListUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidLength:
            "The requested length is too short for the selected options."
        case .noCharacterSetSelected:
            "Select at least one character set."
        case .wordListUnavailable:
            "The passphrase word list is unavailable."
        }
    }
}
