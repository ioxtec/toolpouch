import Foundation

protocol WiFiScanning: Sendable {
    func scan() async throws -> [WiFiNetwork]
}

nonisolated struct UnsupportedWiFiScanner: WiFiScanning {
    func scan() async throws -> [WiFiNetwork] {
        throw WiFiScannerError.unsupportedPlatform
    }
}

nonisolated enum WiFiScannerError: LocalizedError {
    case interfaceUnavailable
    case locationPermissionRequired
    case unsupportedPlatform

    var errorDescription: String? {
        switch self {
        case .interfaceUnavailable:
            "No Wi-Fi interface is available."
        case .locationPermissionRequired:
            "Location access is required to identify nearby Wi-Fi networks."
        case .unsupportedPlatform:
            "Nearby Wi-Fi scanning is not available on this platform."
        }
    }
}
