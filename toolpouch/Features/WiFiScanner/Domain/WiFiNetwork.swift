import Foundation

nonisolated struct WiFiNetwork: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let bssid: String?
    let rssi: Int
    let channel: Int?
    let isSecure: Bool

    var signalQuality: Double {
        min(max(Double(rssi + 100) / 50, 0), 1)
    }

    var signalSystemImage: String {
        switch signalQuality {
        case 0.75...: "wifi"
        case 0.5...: "wifi"
        case 0.25...: "wifi"
        default: "wifi.slash"
        }
    }
}
