import Foundation
import SwiftData

@Model
final class NetworkSnapshotRecord {
    var id: UUID = UUID()
    var deviceID: UUID = UUID()
    var deviceName: String = ""
    var deviceKindRawValue: String = DeviceKind.unknown.rawValue
    var capturedAt: Date = Date()
    var isConnected: Bool = false
    var connectionKindRawValue: String = NetworkConnectionKind.unavailable.rawValue
    var interfaceName: String?
    var publicIPAddress: String?
    var localIPv4Address: String?
    var localIPv6Address: String?
    var routerIPAddress: String?
    var dnsServersData: Data?
    var hostName: String?

    init(snapshot: NetworkInfoSnapshot) {
        id = snapshot.id
        deviceID = snapshot.deviceID
        deviceName = snapshot.deviceName
        deviceKindRawValue = snapshot.deviceKind.rawValue
        capturedAt = snapshot.capturedAt
        isConnected = snapshot.isConnected
        connectionKindRawValue = snapshot.connectionKind.rawValue
        interfaceName = snapshot.interfaceName
        publicIPAddress = snapshot.publicIPAddress
        localIPv4Address = snapshot.localIPv4Address
        localIPv6Address = snapshot.localIPv6Address
        routerIPAddress = snapshot.routerIPAddress
        dnsServersData = try? JSONEncoder().encode(snapshot.dnsServers)
        hostName = snapshot.hostName
    }
}

extension NetworkSnapshotRecord {
    var snapshot: NetworkInfoSnapshot {
        NetworkInfoSnapshot(
            id: id,
            deviceID: deviceID,
            deviceName: deviceName,
            deviceKind: DeviceKind(rawValue: deviceKindRawValue) ?? .unknown,
            capturedAt: capturedAt,
            isConnected: isConnected,
            connectionKind: NetworkConnectionKind(rawValue: connectionKindRawValue) ?? .unavailable,
            interfaceName: interfaceName,
            publicIPAddress: publicIPAddress,
            localIPv4Address: localIPv4Address,
            localIPv6Address: localIPv6Address,
            routerIPAddress: routerIPAddress,
            dnsServers: decodedDNSServers,
            hostName: hostName
        )
    }

    private var decodedDNSServers: [String] {
        guard let dnsServersData else { return [] }
        return (try? JSONDecoder().decode([String].self, from: dnsServersData)) ?? []
    }
}
