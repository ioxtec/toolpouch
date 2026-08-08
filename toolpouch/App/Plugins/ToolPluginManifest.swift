import Foundation

/// A globally unique identifier for a plugin package or bundled plugin.
nonisolated struct ToolPluginIdentifier: RawRepresentable, Hashable, Codable, Sendable {
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

/// Semantic version metadata shared by bundled and external plugins.
nonisolated struct ToolPluginVersion: Hashable, Codable, Sendable {
    let major: Int
    let minor: Int
    let patch: Int

    init(_ major: Int, _ minor: Int, _ patch: Int) {
        self.major = major
        self.minor = minor
        self.patch = patch
    }

    var string: String {
        "\(major).\(minor).\(patch)"
    }
}

/// The execution environment used by a plugin. This is separate from a
/// tool's computation backend: a bundled Swift tool may internally call Rust.
nonisolated enum ToolPluginRuntime: String, Codable, Sendable {
    case nativeSwift
    case nativeProcess
    case webAssembly
    case remoteService
}

/// Describes where an installed plugin registration came from.
nonisolated enum ToolPluginSource: String, Codable, Sendable {
    case bundled
    case localPackage
    case repository
}

/// Declarative metadata that describes a tool plugin without coupling it to a
/// specific view. This is the contract a plugin exposes to the registry.
nonisolated struct ToolPluginManifest: Hashable, Codable, Sendable {
    /// Version of the manifest schema, independent from the plugin version.
    let schemaVersion: Int
    let identifier: ToolPluginIdentifier
    let version: ToolPluginVersion
    /// The oldest Toolpouch release that understands this plugin contract.
    let minimumHostVersion: ToolPluginVersion
    /// The minimum OS version the tool supports, expressed as a semantic
    /// version. Defaults to the app's deployment target.
    let minimumPlatformVersion: ToolPluginVersion
    let runtime: ToolPluginRuntime
    /// Capabilities the device must expose for the tool to be available.
    let requiredCapabilities: Set<ToolCapability>

    init(
        schemaVersion: Int = 1,
        identifier: ToolPluginIdentifier,
        version: ToolPluginVersion,
        minimumHostVersion: ToolPluginVersion = ToolPluginVersion(1, 0, 0),
        minimumPlatformVersion: ToolPluginVersion = ToolPluginVersion(27, 0, 0),
        runtime: ToolPluginRuntime,
        requiredCapabilities: Set<ToolCapability> = []
    ) {
        self.schemaVersion = schemaVersion
        self.identifier = identifier
        self.version = version
        self.minimumHostVersion = minimumHostVersion
        self.minimumPlatformVersion = minimumPlatformVersion
        self.runtime = runtime
        self.requiredCapabilities = requiredCapabilities
    }
}
