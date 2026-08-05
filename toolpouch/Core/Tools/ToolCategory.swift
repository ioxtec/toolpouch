nonisolated struct ToolCategory: Hashable, Identifiable, Sendable {
    enum ID: String, Codable, Sendable {
        case everyday
        case network
        case passwords
        case clipboard
        case text
        case developer
        case visual
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
