import Foundation
import Observation

@MainActor
@Observable
final class WiFiScannerViewModel {
    private let scanner: any WiFiScanning
    private let authorizer: any WiFiScanAuthorizing

    private(set) var networks: [WiFiNetwork] = []
    private(set) var isScanning = false
    private(set) var errorMessage: String?
    private(set) var lastScannedAt: Date?

    init(
        scanner: any WiFiScanning,
        authorizer: any WiFiScanAuthorizing
    ) {
        self.scanner = scanner
        self.authorizer = authorizer
    }

    func scan() async {
        guard !isScanning else { return }

        isScanning = true
        errorMessage = nil

        do {
            try await authorizer.authorize()
            networks = try await scanner.scan()
            lastScannedAt = .now
        } catch {
            errorMessage = error.localizedDescription
        }

        isScanning = false
    }
}
