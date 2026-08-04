nonisolated enum NetworkConnectionKind: String, Codable, CaseIterable, Sendable {
    case ethernet
    case cellular
    case other
    case unavailable
    case wiFi

    var title: String {
        switch self {
        case .ethernet:
            "Ethernet"
        case .cellular:
            "Cellular"
        case .other:
            "Other"
        case .unavailable:
            "Unavailable"
        case .wiFi:
            "Wi-Fi"
        }
    }
}
