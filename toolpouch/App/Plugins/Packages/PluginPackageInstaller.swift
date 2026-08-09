import Foundation

/// Serializes all mutations to the local plugin store.
///
/// Store layout:
/// ```text
/// Plugins/
/// ├── .staging/<transaction>/package/...
/// └── <plugin-id>/
///     ├── active.json
///     └── versions/<semver>/
///         ├── installation.json
///         └── package/...
/// ```
/// A complete transaction directory is moved into `versions/` only after ZIP
/// extraction, manifest validation, and trust verification all succeed.
actor PluginPackageInstaller {
    private enum StoreLayout {
        static let staging = ".staging"
        static let versions = "versions"
        static let package = "package"
        static let installationMetadata = "installation.json"
        static let activeVersion = "active.json"
    }

    private let rootDirectory: URL
    private let policy: PluginInstallationPolicy
    private let signatureVerifier: any PluginPackageSignatureVerifying
    private let validator: PluginPackageValidator
    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        rootDirectory: URL,
        policy: PluginInstallationPolicy = .repositoryOnly,
        signatureVerifier: any PluginPackageSignatureVerifying = UnsignedLocalPluginVerifier()
    ) {
        self.rootDirectory = rootDirectory.standardizedFileURL
        self.policy = policy
        self.signatureVerifier = signatureVerifier
        let fileManager = FileManager()
        self.fileManager = fileManager
        validator = PluginPackageValidator(fileManager: fileManager)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        self.decoder = decoder
    }

    /// Production location inside the app container. Tests and command-line
    /// tools should inject a temporary root instead.
    static func live(
        policy: PluginInstallationPolicy = .repositoryOnly,
        signatureVerifier: any PluginPackageSignatureVerifying = UnsignedLocalPluginVerifier()
    ) throws -> PluginPackageInstaller {
        let fileManager = FileManager.default
        guard let applicationSupport = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            throw PluginInstallationError.sourceMissing
        }
        return PluginPackageInstaller(
            rootDirectory: applicationSupport
                .appendingPathComponent("Toolpouch", isDirectory: true)
                .appendingPathComponent("Plugins", isDirectory: true),
            policy: policy,
            signatureVerifier: signatureVerifier
        )
    }

    /// Imports, validates, verifies, and optionally activates one immutable
    /// plugin version. A failed operation leaves no visible partial install.
    func install(
        archiveURL: URL,
        activate: Bool = true
    ) throws -> PluginInstallationResult {
        try validateArchiveSource(archiveURL)
        try prepareStore()

        let stagingURL = stagingRoot.appendingPathComponent(
            UUID().uuidString,
            isDirectory: true
        )
        let stagedPackageURL = stagingURL.appendingPathComponent(
            StoreLayout.package,
            isDirectory: true
        )
        try createPrivateDirectory(stagingURL)

        var activatedDestination: URL?
        defer {
            if fileManager.fileExists(atPath: stagingURL.path) {
                try? fileManager.removeItem(at: stagingURL)
            }
        }

        do {
            try ZipArchive.extract(
                archiveURL: archiveURL,
                to: stagedPackageURL,
                policy: .pluginPackage,
                fileManager: fileManager
            )
        } catch {
            throw PluginInstallationError.invalidArchive
        }

        let manifest = try validator.validatePackage(at: stagedPackageURL)
        guard policy.allowedRuntimes.contains(manifest.runtime) else {
            throw PluginInstallationError.runtimeNotAllowed(manifest.runtime)
        }
        let trustLevel = try signatureVerifier.verify(
            packageURL: stagedPackageURL,
            manifest: manifest
        )
        guard trustLevel != .unsignedLocal
            || policy.allowsUnsignedLocalPackages else {
            throw PluginInstallationError.unsignedPackageNotAllowed
        }

        let installation = InstalledPluginVersion(
            manifest: manifest,
            trustLevel: trustLevel,
            // Normalize to the precision used by durable metadata so the
            // returned and subsequently loaded records compare identically.
            installedAt: Date(
                timeIntervalSince1970: (
                    Date().timeIntervalSince1970 * 1_000
                ).rounded(.down) / 1_000
            )
        )
        let destination = versionDirectory(
            identifier: manifest.identifier,
            version: manifest.version
        )
        guard !fileManager.fileExists(atPath: destination.path) else {
            throw PluginInstallationError.versionAlreadyInstalled(
                manifest.identifier.rawValue,
                manifest.version.string
            )
        }

        try createPrivateDirectory(destination.deletingLastPathComponent())
        try write(
            installation,
            to: stagingURL.appendingPathComponent(
                StoreLayout.installationMetadata,
                isDirectory: false
            )
        )

        do {
            try fileManager.moveItem(at: stagingURL, to: destination)
            activatedDestination = destination
            if activate {
                try writeActiveVersion(
                    identifier: manifest.identifier,
                    version: manifest.version
                )
            }
        } catch {
            if let activatedDestination,
               fileManager.fileExists(atPath: activatedDestination.path) {
                try? fileManager.removeItem(at: activatedDestination)
            }
            throw error
        }

        return PluginInstallationResult(
            installation: installation,
            packageURL: destination.appendingPathComponent(
                StoreLayout.package,
                isDirectory: true
            ),
            isActive: activate
        )
    }

    /// Returns all immutable versions sorted newest-first by semantic version.
    func installedVersions(
        for identifier: ToolPluginIdentifier
    ) throws -> [InstalledPluginVersion] {
        try validateStoreIdentifier(identifier)
        let versionsURL = versionsDirectory(identifier: identifier)
        guard fileManager.fileExists(atPath: versionsURL.path) else { return [] }
        let children = try fileManager.contentsOfDirectory(
            at: versionsURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )
        return try children.compactMap { child in
            let values = try child.resourceValues(forKeys: [.isDirectoryKey])
            guard values.isDirectory == true else { return nil }
            let installation = try readInstallation(at: child)
            guard installation.identifier == identifier,
                  installation.version.string == child.lastPathComponent else {
                throw PluginInstallationError.unreadableInstallationMetadata
            }
            return installation
        }.sorted { $0.version > $1.version }
    }

    func activeVersion(
        for identifier: ToolPluginIdentifier
    ) throws -> InstalledPluginVersion? {
        try validateStoreIdentifier(identifier)
        let pointerURL = activePointerURL(identifier: identifier)
        guard fileManager.fileExists(atPath: pointerURL.path) else { return nil }
        let pointer: ActivePluginVersion = try read(from: pointerURL)
        guard pointer.identifier == identifier else {
            throw PluginInstallationError.unreadableInstallationMetadata
        }
        return try installation(
            identifier: identifier,
            version: pointer.version
        )
    }

    /// Resolves durable metadata together with the immutable package path used
    /// by execution hosts. Callers must still revalidate the entry point just
    /// before launch because files can be modified outside this actor.
    func activePackage(
        for identifier: ToolPluginIdentifier
    ) throws -> PluginInstallationResult? {
        guard let active = try activeVersion(for: identifier) else {
            return nil
        }
        return PluginInstallationResult(
            installation: active,
            packageURL: versionDirectory(
                identifier: identifier,
                version: active.version
            ).appendingPathComponent(
                StoreLayout.package,
                isDirectory: true
            ),
            isActive: true
        )
    }

    /// Activates an already installed version. This is also the rollback API.
    @discardableResult
    func activate(
        identifier: ToolPluginIdentifier,
        version: ToolPluginVersion
    ) throws -> InstalledPluginVersion {
        try validateStoreIdentifier(identifier)
        let installation = try installation(
            identifier: identifier,
            version: version
        )
        try writeActiveVersion(identifier: identifier, version: version)
        return installation
    }

    /// Removes one version. Removing the active version automatically rolls
    /// back to the newest remaining version, or disables the plugin when none
    /// remain.
    func uninstall(
        identifier: ToolPluginIdentifier,
        version: ToolPluginVersion
    ) throws {
        try validateStoreIdentifier(identifier)
        let destination = versionDirectory(
            identifier: identifier,
            version: version
        )
        guard fileManager.fileExists(atPath: destination.path) else {
            throw PluginInstallationError.versionNotInstalled(
                identifier.rawValue,
                version.string
            )
        }

        let active = try activeVersion(for: identifier)
        if active?.version == version {
            let fallback = try installedVersions(for: identifier)
                .first { $0.version != version }
            if let fallback {
                try writeActiveVersion(
                    identifier: identifier,
                    version: fallback.version
                )
            } else {
                let pointerURL = activePointerURL(identifier: identifier)
                if fileManager.fileExists(atPath: pointerURL.path) {
                    try fileManager.removeItem(at: pointerURL)
                }
            }
        }

        try fileManager.removeItem(at: destination)
        if try installedVersions(for: identifier).isEmpty {
            try? fileManager.removeItem(at: pluginDirectory(identifier))
        }
    }

    /// Removes every installed version and the active pointer for a plugin.
    func uninstallAll(identifier: ToolPluginIdentifier) throws {
        try validateStoreIdentifier(identifier)
        let directory = pluginDirectory(identifier)
        guard fileManager.fileExists(atPath: directory.path) else {
            throw PluginInstallationError.pluginNotInstalled(
                identifier.rawValue
            )
        }
        try fileManager.removeItem(at: directory)
    }

    private var stagingRoot: URL {
        rootDirectory.appendingPathComponent(
            StoreLayout.staging,
            isDirectory: true
        )
    }

    private func validateArchiveSource(_ archiveURL: URL) throws {
        guard archiveURL.pathExtension.lowercased()
                == PluginPackageLayout.fileExtension else {
            throw PluginInstallationError.invalidPackageExtension
        }
        guard fileManager.fileExists(atPath: archiveURL.path) else {
            throw PluginInstallationError.sourceMissing
        }
        let values = try archiveURL.resourceValues(
            forKeys: [.isRegularFileKey, .isSymbolicLinkKey]
        )
        guard values.isSymbolicLink != true else {
            throw PluginInstallationError.sourceIsSymbolicLink
        }
        guard values.isRegularFile == true else {
            throw PluginInstallationError.sourceMissing
        }
    }

    private func prepareStore() throws {
        try createPrivateDirectory(rootDirectory)
        try createPrivateDirectory(stagingRoot)
    }

    private func validateStoreIdentifier(
        _ identifier: ToolPluginIdentifier
    ) throws {
        let value = identifier.rawValue
        guard !value.isEmpty,
              value != ".",
              value != "..",
              !value.contains("/"),
              !value.contains("\\"),
              !value.contains("\0") else {
            throw PluginInstallationError.invalidIdentifier(value)
        }
    }

    private func createPrivateDirectory(_ url: URL) throws {
        try fileManager.createDirectory(
            at: url,
            withIntermediateDirectories: true
        )
        try fileManager.setAttributes(
            [.posixPermissions: 0o700],
            ofItemAtPath: url.path
        )
    }

    private func pluginDirectory(_ identifier: ToolPluginIdentifier) -> URL {
        rootDirectory.appendingPathComponent(
            identifier.rawValue,
            isDirectory: true
        )
    }

    private func versionsDirectory(
        identifier: ToolPluginIdentifier
    ) -> URL {
        pluginDirectory(identifier).appendingPathComponent(
            StoreLayout.versions,
            isDirectory: true
        )
    }

    private func versionDirectory(
        identifier: ToolPluginIdentifier,
        version: ToolPluginVersion
    ) -> URL {
        versionsDirectory(identifier: identifier).appendingPathComponent(
            version.string,
            isDirectory: true
        )
    }

    private func activePointerURL(
        identifier: ToolPluginIdentifier
    ) -> URL {
        pluginDirectory(identifier).appendingPathComponent(
            StoreLayout.activeVersion,
            isDirectory: false
        )
    }

    private func installation(
        identifier: ToolPluginIdentifier,
        version: ToolPluginVersion
    ) throws -> InstalledPluginVersion {
        let directory = versionDirectory(
            identifier: identifier,
            version: version
        )
        guard fileManager.fileExists(atPath: directory.path) else {
            throw PluginInstallationError.versionNotInstalled(
                identifier.rawValue,
                version.string
            )
        }
        let installation = try readInstallation(at: directory)
        guard installation.identifier == identifier,
              installation.version == version else {
            throw PluginInstallationError.unreadableInstallationMetadata
        }
        return installation
    }

    private func readInstallation(
        at versionDirectory: URL
    ) throws -> InstalledPluginVersion {
        do {
            return try read(
                from: versionDirectory.appendingPathComponent(
                    StoreLayout.installationMetadata,
                    isDirectory: false
                )
            )
        } catch {
            throw PluginInstallationError.unreadableInstallationMetadata
        }
    }

    private func writeActiveVersion(
        identifier: ToolPluginIdentifier,
        version: ToolPluginVersion
    ) throws {
        try createPrivateDirectory(pluginDirectory(identifier))
        try write(
            ActivePluginVersion(identifier: identifier, version: version),
            to: activePointerURL(identifier: identifier)
        )
    }

    private func write<Value: Encodable>(
        _ value: Value,
        to url: URL
    ) throws {
        let data = try encoder.encode(value)
        try data.write(to: url, options: [.atomic])
        try fileManager.setAttributes(
            [.posixPermissions: 0o600],
            ofItemAtPath: url.path
        )
    }

    private func read<Value: Decodable>(from url: URL) throws -> Value {
        try decoder.decode(Value.self, from: Data(contentsOf: url))
    }
}
