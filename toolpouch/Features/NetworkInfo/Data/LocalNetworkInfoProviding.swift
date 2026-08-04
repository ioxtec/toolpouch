nonisolated struct LocalNetworkInfo: Sendable {
    let isConnected: Bool
    let connectionKind: NetworkConnectionKind
    let interfaceName: String?
    let localIPv4Address: String?
    let localIPv6Address: String?
    let routerIPAddress: String?
    let dnsServers: [String]
    let hostName: String?
}

protocol LocalNetworkInfoProviding: Sendable {
    func read() -> LocalNetworkInfo
}
