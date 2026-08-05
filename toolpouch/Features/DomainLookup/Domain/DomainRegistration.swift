import Foundation

nonisolated struct DomainRegistration: Sendable {
    let name: String
    let unicodeName: String?
    let registryHandle: String?
    let registrarName: String?
    let registrarHandle: String?
    let registeredAt: Date?
    let expiresAt: Date?
    let lastChangedAt: Date?
    let nameservers: [String]
    let statuses: [String]
    let isDNSSECSigned: Bool?
    let notices: [String]
    let sourceURL: URL
    let rawResponse: String
}
