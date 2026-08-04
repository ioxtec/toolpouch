import Foundation

@MainActor
protocol NetworkSnapshotStoring {
    func save(_ snapshot: NetworkInfoSnapshot) throws
    func fetchLatest(limit: Int) throws -> [NetworkInfoSnapshot]
    func fetchLatest(deviceID: UUID) throws -> NetworkInfoSnapshot?
    func deleteAll() throws
}
