#if os(macOS)
import CoreLocation

@MainActor
final class CoreLocationWiFiScanAuthorizer: NSObject, WiFiScanAuthorizing, CLLocationManagerDelegate {
    private let locationManager: CLLocationManager
    private var continuation: CheckedContinuation<Void, Never>?

    override init() {
        locationManager = CLLocationManager()
        super.init()
        locationManager.delegate = self
    }

    func authorize() async throws {
        switch locationManager.authorizationStatus {
        case .authorized, .authorizedAlways, .authorizedWhenInUse:
            return
        case .denied, .restricted:
            throw WiFiScannerError.locationPermissionRequired
        case .notDetermined:
            await withCheckedContinuation { continuation in
                self.continuation = continuation
                locationManager.requestWhenInUseAuthorization()
            }
            try await authorize()
        @unknown default:
            throw WiFiScannerError.locationPermissionRequired
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor [weak self] in
            self?.resumeAuthorizationRequestIfResolved()
        }
    }

    private func resumeAuthorizationRequestIfResolved() {
        guard locationManager.authorizationStatus != .notDetermined else { return }
        continuation?.resume()
        continuation = nil
    }
}
#endif
