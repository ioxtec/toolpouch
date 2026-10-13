import Foundation

nonisolated enum NetworkCheckError: LocalizedError, Equatable, Sendable {
    case invalidHost
    case invalidPort
    case hostNotFound
    case lookupFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidHost:
            "Enter a valid hostname or IP address.".localizedInterfaceText
        case .invalidPort:
            "The port must be between 1 and 65535.".localizedInterfaceText
        case .hostNotFound:
            "The host could not be resolved.".localizedInterfaceText
        case let .lookupFailed(reason):
            String(format: "DNS lookup failed: %@".localizedInterfaceText, reason)
        }
    }
}
