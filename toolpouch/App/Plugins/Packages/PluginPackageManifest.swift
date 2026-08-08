import Foundation

/// The public, on-disk contract stored as `manifest.json` in a
/// `.toolpouchplugin` package.
///
/// Keep this model free of SwiftUI and app services. Rust, Swift, and other
/// plugin toolchains must be able to generate the same JSON without importing
/// Toolpouch source code.
nonisolated struct PluginPackageManifest: Hashable, Codable, Sendable {
    /// Version of the JSON contract, not the plugin release version.
    let schemaVersion: Int
    let identifier: ToolPluginIdentifier
    let displayName: String
    let summary: String
    let author: PluginAuthor
    let version: ToolPluginVersion
    let minimumHostVersion: ToolPluginVersion
    let runtime: ToolPluginRuntime

    /// Relative path below `payload/` for local runtimes. Remote plugins use
    /// `serviceURL` instead. Never place an absolute path in a manifest.
    let entryPoint: String?
    let serviceURL: URL?

    let supportedPlatforms: Set<ToolPlatform>
    let permissions: Set<ToolPluginPermission>
    let tools: [PluginPackageToolManifest]

    init(
        schemaVersion: Int = 1,
        identifier: ToolPluginIdentifier,
        displayName: String,
        summary: String,
        author: PluginAuthor,
        version: ToolPluginVersion,
        minimumHostVersion: ToolPluginVersion = ToolPluginVersion(1, 0, 0),
        runtime: ToolPluginRuntime,
        entryPoint: String? = nil,
        serviceURL: URL? = nil,
        supportedPlatforms: Set<ToolPlatform>,
        permissions: Set<ToolPluginPermission> = [],
        tools: [PluginPackageToolManifest]
    ) {
        self.schemaVersion = schemaVersion
        self.identifier = identifier
        self.displayName = displayName
        self.summary = summary
        self.author = author
        self.version = version
        self.minimumHostVersion = minimumHostVersion
        self.runtime = runtime
        self.entryPoint = entryPoint
        self.serviceURL = serviceURL
        self.supportedPlatforms = supportedPlatforms
        self.permissions = permissions
        self.tools = tools
    }
}

/// Human-readable author information shown before installation.
nonisolated struct PluginAuthor: Hashable, Codable, Sendable {
    let name: String
    let website: URL?

    init(name: String, website: URL? = nil) {
        self.name = name
        self.website = website
    }
}

/// Presentation and availability metadata for one tool exposed by a package.
/// A package may contain multiple tools, but all of them share one runtime,
/// version, signature, and permission grant.
nonisolated struct PluginPackageToolManifest: Hashable, Codable, Sendable {
    let id: ToolDefinition.ID
    let categoryID: ToolCategory.ID
    let title: String
    let description: String
    let systemImage: String
    let supportedPlatforms: Set<ToolPlatform>
    let requiredCapabilities: Set<ToolCapability>

    init(
        id: ToolDefinition.ID,
        categoryID: ToolCategory.ID,
        title: String,
        description: String,
        systemImage: String,
        supportedPlatforms: Set<ToolPlatform>,
        requiredCapabilities: Set<ToolCapability> = []
    ) {
        self.id = id
        self.categoryID = categoryID
        self.title = title
        self.description = description
        self.systemImage = systemImage
        self.supportedPlatforms = supportedPlatforms
        self.requiredCapabilities = requiredCapabilities
    }
}

/// Security-sensitive access requested by a plugin.
///
/// Permissions answer "what may this plugin access?" while `ToolCapability`
/// answers "can this device provide the feature?". Plugin hosts must grant
/// only the permissions listed here, even when the device has more capability.
nonisolated enum ToolPluginPermission: String, Codable, CaseIterable, Sendable {
    case readUserSelectedFiles = "files.user-selected.read"
    case writeUserSelectedFiles = "files.user-selected.write"
    case network = "network"
    case readClipboard = "clipboard.read"
    case writeClipboard = "clipboard.write"
}

/// Names and directories reserved by the package format. Centralizing them
/// prevents the app, CLI, and documentation from silently drifting apart.
nonisolated enum PluginPackageLayout {
    static let fileExtension = "toolpouchplugin"
    static let manifestFileName = "manifest.json"
    static let signatureFileName = "signature.json"
    static let payloadDirectoryName = "payload"
    static let resourcesDirectoryName = "resources"
}
