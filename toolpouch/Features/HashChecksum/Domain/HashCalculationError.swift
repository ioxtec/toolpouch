import Foundation

nonisolated enum HashCalculationError: LocalizedError, Equatable, Sendable {
    case fileAccessDenied
    case fileReadFailed(String)

    var errorDescription: String? {
        switch self {
        case .fileAccessDenied:
            "ToolPouch could not access the selected file."
        case let .fileReadFailed(details):
            "The file could not be read. \(details)"
        }
    }
}
