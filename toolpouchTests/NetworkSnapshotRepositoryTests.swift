import Foundation
import SwiftData
import Testing
@testable import toolpouch

struct NetworkSnapshotRepositoryTests {
    @Test @MainActor
    func savesAndReadsTheLatestSnapshotForADevice() throws {
        let container = PersistenceContainer.makeModelContainer(mode: .inMemory)
        let repository = NetworkSnapshotRepository(
            modelContext: container.mainContext
        )
        let deviceID = UUID()
        let olderSnapshot = makeSnapshot(
            deviceID: deviceID,
            capturedAt: Date(timeIntervalSince1970: 100)
        )
        let newerSnapshot = makeSnapshot(
            deviceID: deviceID,
            capturedAt: Date(timeIntervalSince1970: 200)
        )

        try repository.save(olderSnapshot)
        try repository.save(newerSnapshot)

        let latestSnapshot = try repository.fetchLatest(deviceID: deviceID)

        #expect(latestSnapshot == newerSnapshot)
        #expect(latestSnapshot?.dnsServers == ["1.1.1.1", "8.8.8.8"])
    }

    @Test @MainActor
    func returnsSnapshotsInReverseChronologicalOrder() throws {
        let container = PersistenceContainer.makeModelContainer(mode: .inMemory)
        let repository = NetworkSnapshotRepository(
            modelContext: container.mainContext
        )
        let olderSnapshot = makeSnapshot(
            capturedAt: Date(timeIntervalSince1970: 100)
        )
        let newerSnapshot = makeSnapshot(
            capturedAt: Date(timeIntervalSince1970: 200)
        )

        try repository.save(olderSnapshot)
        try repository.save(newerSnapshot)

        let snapshots = try repository.fetchLatest(limit: 10)

        #expect(snapshots.map(\.id) == [newerSnapshot.id, olderSnapshot.id])
    }

    @MainActor
    private func makeSnapshot(
        deviceID: UUID = UUID(),
        capturedAt: Date
    ) -> NetworkInfoSnapshot {
        NetworkInfoSnapshot(
            deviceID: deviceID,
            deviceName: "Test Mac",
            deviceKind: .desktop,
            capturedAt: capturedAt,
            isConnected: true,
            connectionKind: .wiFi,
            interfaceName: "en0",
            publicIPAddress: "203.0.113.10",
            localIPv4Address: "192.168.1.5",
            localIPv6Address: "fe80::1",
            routerIPAddress: "192.168.1.1",
            dnsServers: ["1.1.1.1", "8.8.8.8"],
            hostName: "test-mac.local"
        )
    }
}
