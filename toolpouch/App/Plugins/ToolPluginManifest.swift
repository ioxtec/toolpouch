import Foundation

/// Version metadata for a compiled-in tool plugin.
nonisolated struct ToolPluginVersion: Hashable, Sendable {
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

/// Declarative metadata that describes a tool plugin without coupling it to a
/// specific view. This is the contract a plugin exposes to the registry.
nonisolated struct ToolPluginManifest: Hashable, Sendable {
    let version: ToolPluginVersion
    /// The minimum OS version the tool supports, expressed as a semantic
    /// version. Defaults to the app's deployment target.
    let minimumPlatformVersion: ToolPluginVersion
    /// Capabilities the device must expose for the tool to be available.
    let requiredCapabilities: Set<ToolCapability>

    init(
        version: ToolPluginVersion,
        minimumPlatformVersion: ToolPluginVersion = ToolPluginVersion(27, 0, 0),
        requiredCapabilities: Set<ToolCapability> = []
    ) {
        self.version = version
        self.minimumPlatformVersion = minimumPlatformVersion
        self.requiredCapabilities = requiredCapabilities
    }
}
