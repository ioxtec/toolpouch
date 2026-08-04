nonisolated struct ToolDefinition: Hashable, Identifiable, Sendable {
    enum ID: String, Sendable {
        case networkInfo
        case wiFiScanner
        case sshKeys
    }

    let id: ID
    let categoryID: ToolCategory.ID
    let title: String
    let description: String
    let systemImage: String
    let supportedPlatforms: Set<ToolPlatform>
    let executionBackend: ToolExecutionBackend
}
