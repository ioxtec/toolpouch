nonisolated enum BinaryTextEncoding: String, CaseIterable, Identifiable, Sendable {
    case base64
    case base64URL
    case base32
    case hexadecimal

    var id: Self { self }

    var title: String {
        switch self {
        case .base64: "Base64"
        case .base64URL: "Base64URL"
        case .base32: "Base32"
        case .hexadecimal: "Hex"
        }
    }

    var description: String {
        switch self {
        case .base64: "Standard binary-to-text encoding."
        case .base64URL: "URL-safe Base64 used by tokens and JWTs."
        case .base32: "Readable encoding commonly used by 2FA secrets."
        case .hexadecimal: "Base16 representation used by developer tools."
        }
    }
}
