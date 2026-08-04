import Foundation
import SwiftData

@MainActor
final class DeviceRepository: DeviceStoring {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func save(_ device: Device) throws {
        if try fetchRecord(id: device.id) == nil {
            try insert(device)
        } else {
            try update(device)
        }
    }

    func insert(_ device: Device) throws {
        let record = DeviceRecord(
            id: device.id,
            name: device.name,
            kind: device.kind,
            lastSeenAt: device.lastSeenAt
        )

        modelContext.insert(record)
        try modelContext.save()
    }

    func fetch(id: UUID) throws -> Device? {
        try fetchRecord(id: id)?.device
    }

    func fetchAll() throws -> [Device] {
        let descriptor = FetchDescriptor<DeviceRecord>(
            sortBy: [SortDescriptor(\DeviceRecord.lastSeenAt, order: .reverse)]
        )

        return try modelContext.fetch(descriptor).map(\.device)
    }

    func update(_ device: Device) throws {
        guard let record = try fetchRecord(id: device.id) else {
            return
        }

        record.name = device.name
        record.kindRawValue = device.kind.rawValue
        record.lastSeenAt = device.lastSeenAt

        try modelContext.save()
    }

    func delete(id: UUID) throws {
        guard let record = try fetchRecord(id: id) else {
            return
        }

        modelContext.delete(record)
        try modelContext.save()
    }

    private func fetchRecord(id: UUID) throws -> DeviceRecord? {
        var descriptor = FetchDescriptor<DeviceRecord>(
            predicate: #Predicate { record in
                record.id == id
            }
        )
        descriptor.fetchLimit = 1

        return try modelContext.fetch(descriptor).first
    }
}

private extension DeviceRecord {
    var device: Device {
        Device(
            id: id,
            name: name,
            kind: DeviceKind(rawValue: kindRawValue) ?? .unknown,
            lastSeenAt: lastSeenAt
        )
    }
}
