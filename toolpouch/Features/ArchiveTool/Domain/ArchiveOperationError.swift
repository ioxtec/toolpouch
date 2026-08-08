import Foundation

nonisolated enum ArchiveOperationError: LocalizedError, Equatable {
    case sourceMissing
    case destinationUnavailable
    case invalidArchive
    case unsupportedFormat
    case emptySource
    case archiveFailed

    var errorDescription: String? {
        switch self {
        case .sourceMissing:
            "The selected file or folder could not be found."
        case .destinationUnavailable:
            "ToolPouch could not write to the chosen location."
        case .invalidArchive:
            "The dropped file is not a valid archive."
        case .unsupportedFormat:
            "This archive format is not supported yet."
        case .emptySource:
            "There is nothing to compress."
        case .archiveFailed:
            "The archive could not be created."
        }
    }
}
