nonisolated enum SSHKeyAlgorithm: String, CaseIterable, Identifiable, Sendable {
    case ed25519
    case rsa
    case ecdsa

    var id: Self { self }

    var title: String {
        switch self {
        case .ed25519: "Ed25519"
        case .rsa: "RSA"
        case .ecdsa: "ECDSA"
        }
    }

    var defaultFileName: String {
        "id_\(rawValue)"
    }

    var supportedBitSizes: [Int] {
        switch self {
        case .ed25519: []
        case .rsa: [3072, 4096]
        case .ecdsa: [256, 384, 521]
        }
    }
}
