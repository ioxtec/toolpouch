import Foundation

nonisolated enum HashCalculationError: LocalizedError, Equatable, Sendable {
    case fileAccessDenied
    case fileReadFailed(String)

    var errorDescription: String? {
        switch self {
        case .fileAccessDenied:
            "ToolPouch could not access the selected file.".localizedInterfaceText
        case let .fileReadFailed(details):
            String(format: "The file could not be read. %@".localizedInterfaceText, details)
        }
    }
}
