import Foundation

/// Trust established for an installed package. Manifest validation and trust
/// are intentionally separate: valid JSON does not make executable code safe.
nonisolated enum PluginPackageTrustLevel: String, Codable, Sendable {
    /// Local development package accepted by an explicit installation policy.
    case unsignedLocal
    /// Package signed by a registered third-party developer key.
    case developerSigned
    /// Package reviewed and countersigned by the Toolpouch repository.
    case repositorySigned
}

/// Durable metadata stored next to, but not inside, an immutable plugin
/// package. Keeping it outside avoids modifying content covered by signatures.
nonisolated struct InstalledPluginVersion: Hashable, Codable, Sendable {
    let manifest: PluginPackageManifest
    let trustLevel: PluginPackageTrustLevel
    let installedAt: Date

    var identifier: ToolPluginIdentifier { manifest.identifier }
    var version: ToolPluginVersion { manifest.version }
}

nonisolated struct PluginInstallationResult: Sendable {
    let installation: InstalledPluginVersion
    let packageURL: URL
    let isActive: Bool
}

/// Controls developer-only behavior separately from cryptographic
/// verification. Production repository installs should set this to `false`.
nonisolated struct PluginInstallationPolicy: Sendable {
    let allowsUnsignedLocalPackages: Bool

    static let localDevelopment = PluginInstallationPolicy(
        allowsUnsignedLocalPackages: true
    )
    static let repositoryOnly = PluginInstallationPolicy(
        allowsUnsignedLocalPackages: false
    )
}

/// Signature verification seam shared by local development and the future
/// repository trust chain. Implementations should hash canonical package
/// contents and ignore mutable installation metadata outside `packageURL`.
nonisolated protocol PluginPackageSignatureVerifying: Sendable {
    func verify(
        packageURL: URL,
        manifest: PluginPackageManifest
    ) throws -> PluginPackageTrustLevel
}

/// Development verifier used until author and repository signing land. It is
/// safe only together with a policy that explicitly allows unsigned packages.
nonisolated struct UnsignedLocalPluginVerifier: PluginPackageSignatureVerifying {
    func verify(
        packageURL: URL,
        manifest: PluginPackageManifest
    ) throws -> PluginPackageTrustLevel {
        .unsignedLocal
    }
}

nonisolated enum PluginInstallationError: Error, Equatable, LocalizedError {
    case sourceMissing
    case invalidPackageExtension
    case sourceIsSymbolicLink
    case invalidArchive
    case unsignedPackageNotAllowed
    case invalidIdentifier(String)
    case versionAlreadyInstalled(String, String)
    case pluginNotInstalled(String)
    case versionNotInstalled(String, String)
    case unreadableInstallationMetadata

    var errorDescription: String? {
        switch self {
        case .sourceMissing:
            "The selected plugin package doesn't exist."
        case .invalidPackageExtension:
            "Plugin packages must use the .toolpouchplugin extension."
        case .sourceIsSymbolicLink:
            "A plugin package import must not be a symbolic link."
        case .invalidArchive:
            "The plugin package isn't a valid or safe ZIP archive."
        case .unsignedPackageNotAllowed:
            "The current installation policy doesn't allow unsigned plugins."
        case let .invalidIdentifier(identifier):
            "Plugin identifier '\(identifier)' isn't safe for local storage."
        case let .versionAlreadyInstalled(identifier, version):
            "Plugin \(identifier) version \(version) is already installed."
        case let .pluginNotInstalled(identifier):
            "Plugin \(identifier) isn't installed."
        case let .versionNotInstalled(identifier, version):
            "Plugin \(identifier) version \(version) isn't installed."
        case .unreadableInstallationMetadata:
            "Installed plugin metadata is missing or unreadable."
        }
    }
}

/// Small pointer updated atomically when activating or rolling back a plugin.
/// Package version directories remain immutable after installation.
nonisolated struct ActivePluginVersion: Codable, Sendable {
    let identifier: ToolPluginIdentifier
    let version: ToolPluginVersion
}
