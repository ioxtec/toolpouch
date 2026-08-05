import Foundation

nonisolated protocol DomainLookupService: Sendable {
    /// Normalizes a user-entered domain and returns its public RDAP registration data.
    func lookup(_ input: String) async throws -> DomainRegistration
}
