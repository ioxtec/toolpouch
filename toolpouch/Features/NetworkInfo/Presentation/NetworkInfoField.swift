import Foundation

nonisolated struct NetworkInfoField: Identifiable, Sendable {
    let id: String
    let title: String
    let value: String
    let systemImage: String
}

extension NetworkInfoSnapshot {
    var presentationFields: [NetworkInfoField] {
        [
            NetworkInfoField(
                id: "status",
                title: "Status",
                value: isConnected ? "Connected" : "Disconnected",
                systemImage: isConnected ? "checkmark.circle" : "xmark.circle"
            ),
            NetworkInfoField(
                id: "connection",
                title: "Connection",
                value: connectionKind.title,
                systemImage: "network"
            ),
            NetworkInfoField(
                id: "public-ip",
                title: "Public IP",
                value: publicIPAddress ?? "Unavailable",
                systemImage: "globe"
            ),
            NetworkInfoField(
                id: "local-ipv4",
                title: "Local IPv4",
                value: localIPv4Address ?? "Unavailable",
                systemImage: "4.circle"
            ),
            NetworkInfoField(
                id: "local-ipv6",
                title: "Local IPv6",
                value: localIPv6Address ?? "Unavailable",
                systemImage: "6.circle"
            ),
            NetworkInfoField(
                id: "interface",
                title: "Interface",
                value: interfaceName ?? "Unavailable",
                systemImage: "cable.connector"
            ),
            NetworkInfoField(
                id: "router",
                title: "Router",
                value: routerIPAddress ?? "Unavailable",
                systemImage: "wifi.router"
            ),
            NetworkInfoField(
                id: "dns",
                title: "DNS Servers",
                value: dnsServers.isEmpty ? "Unavailable" : dnsServers.joined(separator: ", "),
                systemImage: "server.rack"
            ),
            NetworkInfoField(
                id: "host",
                title: "Host Name",
                value: hostName ?? "Unavailable",
                systemImage: "desktopcomputer"
            ),
        ]
    }
}
