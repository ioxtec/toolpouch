import Foundation

nonisolated enum DomainLookupError: LocalizedError, Equatable, Sendable {
    case invalidDomain
    case unsupportedTopLevelDomain(String)
    case insecureService
    case notFound
    case rateLimited
    case invalidResponse
    case serverError(Int)

    var errorDescription: String? {
        switch self {
        case .invalidDomain:
            "Enter a valid domain name, for example example.com.".localizedInterfaceText
        case let .unsupportedTopLevelDomain(tld):
            String(format: "No RDAP service is registered for .%@.".localizedInterfaceText, tld)
        case .insecureService:
            "The registry does not provide a secure RDAP endpoint.".localizedInterfaceText
        case .notFound:
            "The domain was not found in the registry.".localizedInterfaceText
        case .rateLimited:
            "The registry is receiving too many requests. Try again later.".localizedInterfaceText
        case .invalidResponse:
            "The registry returned an unsupported response.".localizedInterfaceText
        case let .serverError(statusCode):
            String(format: "The registry returned HTTP status %lld.".localizedInterfaceText, Int64(statusCode))
        }
    }
}
