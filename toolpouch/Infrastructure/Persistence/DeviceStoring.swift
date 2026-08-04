import Foundation

@MainActor
protocol DeviceStoring {
    func save(_ device: Device) throws
    func insert(_ device: Device) throws
    func fetch(id: UUID) throws -> Device?
    func fetchAll() throws -> [Device]
    func update(_ device: Device) throws
    func delete(id: UUID) throws
}
