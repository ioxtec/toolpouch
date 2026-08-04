#if os(macOS)
@preconcurrency import CoreWLAN
import Foundation

nonisolated final class CoreWLANWiFiScanner: WiFiScanning, @unchecked Sendable {
    func scan() async throws -> [WiFiNetwork] {
        try await Task.detached(priority: .userInitiated) {
            guard let interface = CWWiFiClient.shared().interface() else {
                throw WiFiScannerError.interfaceUnavailable
            }

            let networks = try interface.scanForNetworks(withName: nil)

            return networks
                .map(Self.makeNetwork)
                .sorted {
                    if $0.rssi == $1.rssi {
                        return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                    }
                    return $0.rssi > $1.rssi
                }
        }.value
    }

    private static func makeNetwork(_ network: CWNetwork) -> WiFiNetwork {
        let name = network.ssid?.isEmpty == false ? network.ssid! : "Hidden Network"
        let bssid = network.bssid

        return WiFiNetwork(
            id: bssid ?? "\(name)-\(network.wlanChannel?.channelNumber ?? 0)",
            name: name,
            bssid: bssid,
            rssi: network.rssiValue,
            channel: network.wlanChannel?.channelNumber,
            isSecure: network.supportsSecurity(.none) == false
        )
    }
}
#endif
