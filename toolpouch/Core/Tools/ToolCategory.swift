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
}
