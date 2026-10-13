import Foundation

nonisolated enum FunctionGraphError: Error, Equatable, LocalizedError {
    case invalidRange
    case noDrawableValues

    var errorDescription: String? {
        switch self {
        case .invalidRange:
            "The maximum x value must be greater than the minimum.".localizedInterfaceText
        case .noDrawableValues:
            "This expression has no drawable values in the selected range.".localizedInterfaceText
        }
    }
}
