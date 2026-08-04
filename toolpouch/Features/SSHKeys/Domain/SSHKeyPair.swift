import Foundation

nonisolated struct SSHKeyPair: Identifiable, Hashable, Sendable {
    var id: URL { privateKeyURL }

    let name: String
    let privateKeyURL: URL
    let publicKeyURL: URL?
    let algorithm: String?
    let comment: String?
    let modifiedAt: Date?
}
