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
    }

    let id: ID
    let categoryID: ToolCategory.ID
    let title: String
    let description: String
    let systemImage: String
    let supportedPlatforms: Set<ToolPlatform>
    let executionBackend: ToolExecutionBackend
}
