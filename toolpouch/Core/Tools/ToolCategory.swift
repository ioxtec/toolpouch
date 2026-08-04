nonisolated struct ToolCategory: Hashable, Identifiable, Sendable {
    enum ID: String, Sendable {
        case network
        case security
        case passwords
        case clipboard
        case design
        case images
        case text
        case sync
        case utilities
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
