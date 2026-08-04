import Foundation
import SwiftData

@Model
final class DeviceRecord {
    var id: UUID = UUID()
    var name: String = ""
    var kindRawValue: String = DeviceKind.unknown.rawValue
    var lastSeenAt: Date = Date()

    init(
        id: UUID = UUID(),
        name: String,
        kind: DeviceKind,
        lastSeenAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        kindRawValue = kind.rawValue
        self.lastSeenAt = lastSeenAt
    }
}
