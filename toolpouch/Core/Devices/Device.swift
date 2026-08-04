import Foundation

nonisolated struct Device: Codable, Hashable, Identifiable, Sendable {
    let id: UUID
    let name: String
    let kind: DeviceKind
    let lastSeenAt: Date
}
