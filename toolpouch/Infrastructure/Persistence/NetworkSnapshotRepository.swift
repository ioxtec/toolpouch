import Foundation
import SwiftData

@MainActor
final class NetworkSnapshotRepository: NetworkSnapshotStoring {
    private enum Retention {
        static let snapshotsPerDevice = 100
    }

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func save(_ snapshot: NetworkInfoSnapshot) throws {
        modelContext.insert(NetworkSnapshotRecord(snapshot: snapshot))
        try removeExpiredSnapshots(deviceID: snapshot.deviceID)
        try modelContext.save()
    }

    func fetchLatest(limit: Int = 50) throws -> [NetworkInfoSnapshot] {
        var descriptor = FetchDescriptor<NetworkSnapshotRecord>(
            sortBy: [SortDescriptor(\NetworkSnapshotRecord.capturedAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return try modelContext.fetch(descriptor).map(\.snapshot)
    }

    func fetchLatest(deviceID: UUID) throws -> NetworkInfoSnapshot? {
        var descriptor = FetchDescriptor<NetworkSnapshotRecord>(
            predicate: #Predicate { record in
                record.deviceID == deviceID
            },
            sortBy: [SortDescriptor(\NetworkSnapshotRecord.capturedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first?.snapshot
    }

    func deleteAll() throws {
        try modelContext.delete(model: NetworkSnapshotRecord.self)
        try modelContext.save()
    }

    private func removeExpiredSnapshots(deviceID: UUID) throws {
        let descriptor = FetchDescriptor<NetworkSnapshotRecord>(
            predicate: #Predicate { record in
                record.deviceID == deviceID
            },
            sortBy: [SortDescriptor(\NetworkSnapshotRecord.capturedAt, order: .reverse)]
        )
        let records = try modelContext.fetch(descriptor)

        for record in records.dropFirst(Retention.snapshotsPerDevice) {
            modelContext.delete(record)
        }
    }
}
