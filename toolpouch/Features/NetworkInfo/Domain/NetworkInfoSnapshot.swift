import Foundation

nonisolated struct NetworkInfoSnapshot: Codable, Hashable, Identifiable, Sendable {
    let id: UUID
    let deviceID: UUID
    let deviceName: String
    let deviceKind: DeviceKind
    let capturedAt: Date
    let isConnected: Bool
    let connectionKind: NetworkConnectionKind
    let interfaceName: String?
    let publicIPAddress: String?
    let localIPv4Address: String?
    let localIPv6Address: String?
    let routerIPAddress: String?
    let dnsServers: [String]
    let hostName: String?

    init(
        id: UUID = UUID(),
        deviceID: UUID,
        deviceName: String,
        deviceKind: DeviceKind,
        capturedAt: Date = Date(),
        isConnected: Bool,
        connectionKind: NetworkConnectionKind,
        interfaceName: String? = nil,
        publicIPAddress: String? = nil,
        localIPv4Address: String? = nil,
        localIPv6Address: String? = nil,
        routerIPAddress: String? = nil,
        dnsServers: [String] = [],
        hostName: String? = nil
    ) {
        self.id = id
        self.deviceID = deviceID
        self.deviceName = deviceName
        self.deviceKind = deviceKind
        self.capturedAt = capturedAt
        self.isConnected = isConnected
        self.connectionKind = connectionKind
        self.interfaceName = interfaceName
        self.publicIPAddress = publicIPAddress
        self.localIPv4Address = localIPv4Address
        self.localIPv6Address = localIPv6Address
        self.routerIPAddress = routerIPAddress
        self.dnsServers = dnsServers
        self.hostName = hostName
    }
}
