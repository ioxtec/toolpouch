nonisolated struct SSHKeyGenerationRequest: Sendable {
    let algorithm: SSHKeyAlgorithm
    let bitSize: Int?
    let fileName: String
    let comment: String
    let passphrase: String
}
