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
            "Enter a valid domain name, for example example.com."
        case let .unsupportedTopLevelDomain(tld):
            "No RDAP service is registered for .\(tld)."
        case .insecureService:
            "The registry does not provide a secure RDAP endpoint."
        case .notFound:
            "The domain was not found in the registry."
        case .rateLimited:
            "The registry is receiving too many requests. Try again later."
        case .invalidResponse:
            "The registry returned an unsupported response."
        case let .serverError(statusCode):
            "The registry returned HTTP status \(statusCode)."
        }
    }
}
