nonisolated enum TextConversionDirection: String, CaseIterable, Identifiable, Sendable {
    case encode
    case decode

    var id: Self { self }

    var title: String {
        switch self {
        case .encode: "Encode"
        case .decode: "Decode"
        }
    }

    var inputTitle: String {
        switch self {
        case .encode: "Plain Text"
        case .decode: "Encoded Text"
        }
    }

    var outputTitle: String {
        switch self {
        case .encode: "Encoded Text"
        case .decode: "Plain Text"
        }
    }

    var opposite: Self {
        switch self {
        case .encode: .decode
        case .decode: .encode
        }
    }
}
