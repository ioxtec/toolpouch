nonisolated struct ToolDefinition: Hashable, Identifiable, Sendable {
    enum ID: String, Codable, Sendable {
        case unitConverter
        case networkInfo
        case wiFiScanner
        case sshKeys
        case passwordGenerator
        case textEncoder
        case jsonToolkit
        case hashChecksum
        case networkCheck
        case clipboardInspector
        case domainLookup
        case imageInspector
        case colorPicker
        case archiveTool
    }

    let id: ID
    let categoryID: ToolCategory.ID
    let title: String
    let description: String
    let systemImage: String
    let supportedPlatforms: Set<ToolPlatform>
    let executionBackend: ToolExecutionBackend
    /// Capabilities the device must expose for this tool to be available.
    /// Defaults to an empty set (available wherever the platform matches).
    let requiredCapabilities: Set<ToolCapability>

    init(
        id: ID,
        categoryID: ToolCategory.ID,
        title: String,
        description: String,
        systemImage: String,
        supportedPlatforms: Set<ToolPlatform>,
        executionBackend: ToolExecutionBackend,
        requiredCapabilities: Set<ToolCapability> = []
    ) {
        self.id = id
        self.categoryID = categoryID
        self.title = title
        self.description = description
        self.systemImage = systemImage
        self.supportedPlatforms = supportedPlatforms
        self.executionBackend = executionBackend
        self.requiredCapabilities = requiredCapabilities
    }
}
