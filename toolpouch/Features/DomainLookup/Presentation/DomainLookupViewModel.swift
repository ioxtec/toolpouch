import Foundation
import Observation

@MainActor
@Observable
final class DomainLookupViewModel {
    var query = ""

    private(set) var registration: DomainRegistration?
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    private let service: any DomainLookupService

    init(service: any DomainLookupService) {
        self.service = service
    }

    var canLookup: Bool {
        !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !isLoading
    }

    func lookup() async {
        guard canLookup else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            registration = try await service.lookup(query)
        } catch is CancellationError {
            return
        } catch {
            registration = nil
            errorMessage = error.localizedDescription
        }
    }
}
