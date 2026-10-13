nonisolated struct ToolCategory: Hashable, Identifiable, Sendable {
    /// Stable identifier persisted by catalog configuration and preferences.
    struct ID: RawRepresentable, Hashable, Codable, Sendable {
        let rawValue: String

        init(rawValue: String) {
            self.rawValue = rawValue
        }

        init(from decoder: any Decoder) throws {
            let container = try decoder.singleValueContainer()
            rawValue = try container.decode(String.self)
        }

        func encode(to encoder: any Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(rawValue)
        }
    }

    let id: ID
    let title: String
    let description: String
    let systemImage: String
    let supportedPlatforms: Set<ToolPlatform>

    var localizedTitle: String { title.localizedInterfaceText }
    var localizedDescription: String { description.localizedInterfaceText }

    init(
        id: ID,
        title: String,
        description: String,
        systemImage: String,
        supportedPlatforms: Set<ToolPlatform> = [.iOS, .macOS, .watchOS]
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.systemImage = systemImage
        self.supportedPlatforms = supportedPlatforms
    }
}

extension ToolCategory.ID {
    static let device = Self(rawValue: "device")
    static let network = Self(rawValue: "network")
    static let credentials = Self(rawValue: "credentials")
    static let text = Self(rawValue: "text")
    static let calculations = Self(rawValue: "calculations")
    static let science = Self(rawValue: "science")
    static let files = Self(rawValue: "files")
    static let graphics = Self(rawValue: "graphics")
    static let location = Self(rawValue: "location")
}
