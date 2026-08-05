nonisolated enum HashAlgorithm: String, CaseIterable, Identifiable, Sendable {
    case sha256
    case sha512
    case md5

    var id: Self { self }

    var title: String {
        switch self {
        case .sha256: "SHA-256"
        case .sha512: "SHA-512"
        case .md5: "MD5"
        }
    }

    var isLegacy: Bool {
        self == .md5
    }
}
