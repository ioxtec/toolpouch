import Foundation

nonisolated enum PluginPackageValidationError: Error, Equatable, LocalizedError {
    case manifestTooLarge
    case unreadableManifest
    case malformedManifest(String)
    case unsupportedSchemaVersion(Int)
    case invalidIdentifier(String)
    case emptyField(String)
    case invalidVersion(String)
    case unsupportedRuntime(ToolPluginRuntime)
    case runtimeUnavailableOnPlatform(ToolPluginRuntime, ToolPlatform)
    case missingEntryPoint
    case unsafeEntryPoint(String)
    case unexpectedEntryPoint
    case unexpectedServiceURL
    case missingServiceURL
    case insecureServiceURL
    case emptyPlatforms
    case emptyTools
    case duplicateToolIdentifier(String)
    case toolOutsidePluginNamespace(String)
    case toolPlatformsExceedPackage(String)
    case missingPayload(String)
    case nonExecutablePayload(String)
    case symbolicLinkPayload(String)

    var errorDescription: String? {
        switch self {
        case .manifestTooLarge:
            "Plugin manifest exceeds the 1 MB limit."
        case .unreadableManifest:
            "The package doesn't contain a readable manifest.json file."
        case let .malformedManifest(message):
            "The plugin manifest is malformed: \(message)"
        case let .unsupportedSchemaVersion(version):
            "Manifest schema version \(version) isn't supported."
        case let .invalidIdentifier(identifier):
            "Plugin identifier '\(identifier)' isn't a valid reverse-DNS identifier."
        case let .emptyField(field):
            "Required manifest field '\(field)' is empty."
        case let .invalidVersion(field):
            "Version field '\(field)' contains a negative component."
        case let .unsupportedRuntime(runtime):
            "Runtime '\(runtime.rawValue)' can't be installed from a package."
        case let .runtimeUnavailableOnPlatform(runtime, platform):
            "Runtime '\(runtime.rawValue)' isn't available on \(platform.rawValue)."
        case .missingEntryPoint:
            "This plugin runtime requires an entry point below payload/."
        case let .unsafeEntryPoint(path):
            "Plugin entry point '\(path)' isn't a safe relative payload path."
        case .unexpectedEntryPoint:
            "A remote plugin must not declare a local entry point."
        case .unexpectedServiceURL:
            "A local plugin runtime must not declare a serviceURL."
        case .missingServiceURL:
            "A remote plugin requires a serviceURL."
        case .insecureServiceURL:
            "A remote plugin serviceURL must use HTTPS."
        case .emptyPlatforms:
            "A plugin must support at least one platform."
        case .emptyTools:
            "A plugin must expose at least one tool."
        case let .duplicateToolIdentifier(identifier):
            "Tool identifier '\(identifier)' is duplicated in the manifest."
        case let .toolOutsidePluginNamespace(identifier):
            "Tool identifier '\(identifier)' must belong to the plugin namespace."
        case let .toolPlatformsExceedPackage(identifier):
            "Tool '\(identifier)' declares a platform not supported by its package."
        case let .missingPayload(path):
            "The declared plugin payload '\(path)' doesn't exist."
        case let .nonExecutablePayload(path):
            "Native plugin payload '\(path)' isn't executable."
        case let .symbolicLinkPayload(path):
            "The declared plugin payload '\(path)' must not be a symbolic link."
        }
    }
}

/// Decodes and validates package metadata before installation.
///
/// This type intentionally does not unzip archives or execute payloads. The
/// installer will first extract into a private staging directory, then call
/// this validator, and only after success atomically activate the package.
nonisolated struct PluginPackageValidator {
    static let supportedSchemaVersion = 1
    static let maximumManifestSize = 1_048_576

    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func decodeAndValidateManifest(
        from data: Data
    ) throws -> PluginPackageManifest {
        guard data.count <= Self.maximumManifestSize else {
            throw PluginPackageValidationError.manifestTooLarge
        }

        let manifest: PluginPackageManifest
        do {
            manifest = try JSONDecoder().decode(
                PluginPackageManifest.self,
                from: data
            )
        } catch {
            throw PluginPackageValidationError.malformedManifest(
                error.localizedDescription
            )
        }

        try validate(manifest)
        return manifest
    }

    /// Validates an already extracted package directory and returns its
    /// manifest. Callers must still verify signatures before activation.
    func validatePackage(
        at packageDirectory: URL
    ) throws -> PluginPackageManifest {
        let root = packageDirectory.standardizedFileURL
        let manifestURL = root.appendingPathComponent(
            PluginPackageLayout.manifestFileName,
            isDirectory: false
        )

        guard let data = try? Data(
            contentsOf: manifestURL,
            options: [.mappedIfSafe]
        ) else {
            throw PluginPackageValidationError.unreadableManifest
        }

        let manifest = try decodeAndValidateManifest(from: data)
        if let entryPoint = manifest.entryPoint {
            try validatePayload(
                entryPoint,
                runtime: manifest.runtime,
                inside: root
            )
        }
        return manifest
    }

    func validate(_ manifest: PluginPackageManifest) throws {
        guard manifest.schemaVersion == Self.supportedSchemaVersion else {
            throw PluginPackageValidationError.unsupportedSchemaVersion(
                manifest.schemaVersion
            )
        }
        guard Self.isReverseDNSIdentifier(manifest.identifier.rawValue) else {
            throw PluginPackageValidationError.invalidIdentifier(
                manifest.identifier.rawValue
            )
        }
        try requireText(manifest.displayName, field: "displayName")
        try requireText(manifest.summary, field: "summary")
        try requireText(manifest.author.name, field: "author.name")
        try validateVersion(manifest.version, field: "version")
        try validateVersion(
            manifest.minimumHostVersion,
            field: "minimumHostVersion"
        )
        guard !manifest.supportedPlatforms.isEmpty else {
            throw PluginPackageValidationError.emptyPlatforms
        }
        guard !manifest.tools.isEmpty else {
            throw PluginPackageValidationError.emptyTools
        }

        switch manifest.runtime {
        case .nativeProcess, .webAssembly:
            guard let entryPoint = manifest.entryPoint else {
                throw PluginPackageValidationError.missingEntryPoint
            }
            guard Self.isSafePayloadPath(entryPoint) else {
                throw PluginPackageValidationError.unsafeEntryPoint(entryPoint)
            }
            guard manifest.serviceURL == nil else {
                throw PluginPackageValidationError.unexpectedServiceURL
            }
            if manifest.runtime == .nativeProcess,
               let unsupportedPlatform = manifest.supportedPlatforms.first(
                   where: { $0 != .macOS }
               ) {
                // iOS and watchOS don't allow an app to spawn downloaded
                // executables. Swift and Rust native-process plugins are
                // therefore a macOS-only package type.
                throw PluginPackageValidationError.runtimeUnavailableOnPlatform(
                    .nativeProcess,
                    unsupportedPlatform
                )
            }
        case .remoteService:
            guard let serviceURL = manifest.serviceURL else {
                throw PluginPackageValidationError.missingServiceURL
            }
            guard serviceURL.scheme?.lowercased() == "https",
                  serviceURL.host?.isEmpty == false
            else {
                throw PluginPackageValidationError.insecureServiceURL
            }
            guard manifest.entryPoint == nil else {
                throw PluginPackageValidationError.unexpectedEntryPoint
            }
        case .nativeSwift:
            // Swift plugins compiled into Toolpouch use ToolPlugin directly.
            // Downloadable Swift executables use the nativeProcess runtime.
            throw PluginPackageValidationError.unsupportedRuntime(.nativeSwift)
        }

        var toolIdentifiers = Set<ToolDefinition.ID>()
        for tool in manifest.tools {
            try validate(
                tool,
                pluginIdentifier: manifest.identifier,
                packagePlatforms: manifest.supportedPlatforms
            )
            guard toolIdentifiers.insert(tool.id).inserted else {
                throw PluginPackageValidationError.duplicateToolIdentifier(
                    tool.id.rawValue
                )
            }
        }
    }

    private func validate(
        _ tool: PluginPackageToolManifest,
        pluginIdentifier: ToolPluginIdentifier,
        packagePlatforms: Set<ToolPlatform>
    ) throws {
        let pluginNamespace = pluginIdentifier.rawValue
        let toolIdentifier = tool.id.rawValue
        guard toolIdentifier == pluginNamespace
            || toolIdentifier.hasPrefix("\(pluginNamespace).")
        else {
            throw PluginPackageValidationError.toolOutsidePluginNamespace(
                toolIdentifier
            )
        }
        try requireText(tool.title, field: "tools.title")
        try requireText(tool.description, field: "tools.description")
        try requireText(tool.systemImage, field: "tools.systemImage")
        guard !tool.supportedPlatforms.isEmpty,
              tool.supportedPlatforms.isSubset(of: packagePlatforms)
        else {
            throw PluginPackageValidationError.toolPlatformsExceedPackage(
                toolIdentifier
            )
        }
    }

    private func validatePayload(
        _ entryPoint: String,
        runtime: ToolPluginRuntime,
        inside root: URL
    ) throws {
        guard Self.isSafePayloadPath(entryPoint) else {
            throw PluginPackageValidationError.unsafeEntryPoint(entryPoint)
        }
        let payloadURL = root.appendingPathComponent(
            entryPoint,
            isDirectory: false
        ).standardizedFileURL
        let expectedPrefix = root.path.hasSuffix("/")
            ? root.path
            : root.path + "/"
        guard payloadURL.path.hasPrefix(expectedPrefix) else {
            throw PluginPackageValidationError.unsafeEntryPoint(entryPoint)
        }
        guard fileManager.fileExists(atPath: payloadURL.path) else {
            throw PluginPackageValidationError.missingPayload(entryPoint)
        }

        // Check every component, not only the executable itself. Otherwise an
        // attacker could place a regular file behind an intermediate symlink
        // that escapes the private staging directory.
        var componentURL = root
        for component in entryPoint.split(separator: "/") {
            componentURL.appendPathComponent(String(component))
            let componentValues = try componentURL.resourceValues(
                forKeys: [.isSymbolicLinkKey]
            )
            guard componentValues.isSymbolicLink != true else {
                throw PluginPackageValidationError.symbolicLinkPayload(
                    entryPoint
                )
            }
        }

        let values = try payloadURL.resourceValues(
            forKeys: [.isRegularFileKey, .isSymbolicLinkKey]
        )
        guard values.isSymbolicLink != true else {
            throw PluginPackageValidationError.symbolicLinkPayload(entryPoint)
        }
        guard values.isRegularFile == true else {
            throw PluginPackageValidationError.missingPayload(entryPoint)
        }
        if runtime == .nativeProcess,
           !fileManager.isExecutableFile(atPath: payloadURL.path) {
            throw PluginPackageValidationError.nonExecutablePayload(entryPoint)
        }
    }

    private func requireText(_ value: String, field: String) throws {
        guard !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw PluginPackageValidationError.emptyField(field)
        }
    }

    private func validateVersion(
        _ version: ToolPluginVersion,
        field: String
    ) throws {
        guard version.major >= 0, version.minor >= 0, version.patch >= 0 else {
            throw PluginPackageValidationError.invalidVersion(field)
        }
    }

    private static func isReverseDNSIdentifier(_ identifier: String) -> Bool {
        let components = identifier.split(
            separator: ".",
            omittingEmptySubsequences: false
        )
        guard components.count >= 3 else { return false }

        return components.allSatisfy { component in
            guard let first = component.first,
                  first.isASCII,
                  first.isLetter || first.isNumber
            else {
                return false
            }
            return component.allSatisfy {
                $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "-")
            }
        }
    }

    private static func isSafePayloadPath(_ path: String) -> Bool {
        guard path.hasPrefix("\(PluginPackageLayout.payloadDirectoryName)/"),
              !path.hasPrefix("/"),
              !path.contains("\\")
        else {
            return false
        }
        let components = path.split(
            separator: "/",
            omittingEmptySubsequences: false
        )
        return !components.contains(where: {
            $0.isEmpty || $0 == "." || $0 == ".."
        })
    }
}
