import Foundation
import Testing
@testable import toolpouch

struct NetworkInfoCollectorTests {
    @Test
    func disconnectedNetworkProducesACompleteOfflineSnapshot() async {
        let device = Device(
            id: UUID(),
            name: "Test Mac",
            kind: .desktop,
            lastSeenAt: Date()
        )
        let localInfo = LocalNetworkInfo(
            isConnected: false,
            connectionKind: .unavailable,
            interfaceName: nil,
            localIPv4Address: nil,
            localIPv6Address: nil,
            routerIPAddress: nil,
            dnsServers: [],
            hostName: "test-mac.local"
        )
        let collector = NetworkInfoCollector(
            localProvider: LocalNetworkInfoProviderStub(info: localInfo)
        )

        let snapshot = await collector.collect(for: device)

        #expect(snapshot.deviceID == device.id)
        #expect(snapshot.deviceName == device.name)
        #expect(snapshot.connectionKind == .unavailable)
        #expect(snapshot.publicIPAddress == nil)
        #expect(snapshot.hostName == "test-mac.local")
    }
}

private nonisolated struct LocalNetworkInfoProviderStub: LocalNetworkInfoProviding {
    let info: LocalNetworkInfo

    func read() -> LocalNetworkInfo {
        info
    }
}
