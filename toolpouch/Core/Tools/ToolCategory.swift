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
    static let everyday = Self(rawValue: "everyday")
    static let system = Self(rawValue: "system")
    static let network = Self(rawValue: "network")
    static let passwords = Self(rawValue: "passwords")
    static let clipboard = Self(rawValue: "clipboard")
    static let text = Self(rawValue: "text")
    static let developer = Self(rawValue: "developer")
    static let visual = Self(rawValue: "visual")
}
