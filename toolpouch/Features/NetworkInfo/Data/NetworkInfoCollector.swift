import Foundation

nonisolated struct NetworkInfoCollector: NetworkInfoCollecting {
    private let localProvider: any LocalNetworkInfoProviding
    private let publicClient: PublicIPAddressClient

    init(
        localProvider: any LocalNetworkInfoProviding = SystemLocalNetworkInfoProvider(),
        publicClient: PublicIPAddressClient = PublicIPAddressClient()
    ) {
        self.localProvider = localProvider
        self.publicClient = publicClient
    }

    func collect(for device: Device) async -> NetworkInfoSnapshot {
        let localInfo = localProvider.read()
        let publicIPAddress: String?

        if localInfo.isConnected {
            publicIPAddress = try? await publicClient.fetch()
        } else {
            publicIPAddress = nil
        }

        return NetworkInfoSnapshot(
            deviceID: device.id,
            deviceName: device.name,
            deviceKind: device.kind,
            isConnected: localInfo.isConnected,
            connectionKind: localInfo.connectionKind,
            interfaceName: localInfo.interfaceName,
            publicIPAddress: publicIPAddress,
            localIPv4Address: localInfo.localIPv4Address,
            localIPv6Address: localInfo.localIPv6Address,
            routerIPAddress: localInfo.routerIPAddress,
            dnsServers: localInfo.dnsServers,
            hostName: localInfo.hostName
        )
    }
}
