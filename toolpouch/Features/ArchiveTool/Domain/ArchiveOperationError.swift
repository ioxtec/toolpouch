import Foundation

nonisolated enum ArchiveOperationError: LocalizedError, Equatable {
    case sourceMissing
    case destinationUnavailable
    case invalidArchive
    case unsupportedFormat
    case emptySource
    case archiveFailed
    case destinationExists
    case sourceIsDestination

    var errorDescription: String? {
        switch self {
        case .sourceMissing:
            "The selected file or folder could not be found.".localizedInterfaceText
        case .destinationUnavailable:
            "ToolPouch could not write to the chosen location.".localizedInterfaceText
        case .invalidArchive:
            "The dropped file is not a valid archive.".localizedInterfaceText
        case .unsupportedFormat:
            "This archive format is not supported yet.".localizedInterfaceText
        case .emptySource:
            "There is nothing to compress.".localizedInterfaceText
        case .archiveFailed:
            "The archive could not be created.".localizedInterfaceText
        case .destinationExists:
            "A file already exists at the chosen destination. Choose a different name.".localizedInterfaceText
        case .sourceIsDestination:
            "Choose a destination outside the source. The original must not be overwritten.".localizedInterfaceText
        }
    }
}
