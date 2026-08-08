import Foundation
import Testing
@testable import toolpouch

@MainActor
struct PluginPackageValidatorTests {
    private let validator = PluginPackageValidator()

    @Test
    func validNativeProcessManifestPassesValidation() throws {
        let manifest = makeManifest()

        try validator.validate(manifest)
    }

    @Test
    func manifestRoundTripsThroughJSON() throws {
        let manifest = makeManifest(
            permissions: [.network, .readUserSelectedFiles]
        )

        let data = try JSONEncoder().encode(manifest)
        let decoded = try validator.decodeAndValidateManifest(from: data)

        #expect(decoded == manifest)
    }

    @Test
    func documentedExampleManifestStaysCompatibleWithDecoder() throws {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let exampleURL = repositoryRoot.appending(
            path: "PluginSDK/Examples/native-process/manifest.json",
            directoryHint: .notDirectory
        )
        let data = try Data(contentsOf: exampleURL)

        let manifest = try validator.decodeAndValidateManifest(from: data)

        #expect(manifest.identifier.rawValue == "dev.example.formatter")
        #expect(manifest.runtime == .nativeProcess)
    }

    @Test
    func bundledSwiftRuntimeCannotBeInstalledFromPackage() {
        let manifest = makeManifest(runtime: .nativeSwift, entryPoint: nil)

        #expect(
            throws: PluginPackageValidationError.unsupportedRuntime(.nativeSwift)
        ) {
            try validator.validate(manifest)
        }
    }

    @Test(arguments: [
        "/tmp/plugin",
        "payload/../plugin",
        "payload/./plugin",
        "payload//plugin",
        "payload\\plugin",
        "plugin",
    ])
    func unsafeEntryPointsAreRejected(_ entryPoint: String) {
        let manifest = makeManifest(entryPoint: entryPoint)

        #expect(
            throws: PluginPackageValidationError.unsafeEntryPoint(entryPoint)
        ) {
            try validator.validate(manifest)
        }
    }

    @Test
    func toolIdentifierMustBelongToPluginNamespace() {
        let tool = makeTool(id: "dev.someone-else.formatter")
        let manifest = makeManifest(tools: [tool])

        #expect(
            throws: PluginPackageValidationError.toolOutsidePluginNamespace(
                tool.id.rawValue
            )
        ) {
            try validator.validate(manifest)
        }
    }

    @Test
    func duplicateToolIdentifiersAreRejected() {
        let tool = makeTool()
        let manifest = makeManifest(tools: [tool, tool])

        #expect(
            throws: PluginPackageValidationError.duplicateToolIdentifier(
                tool.id.rawValue
            )
        ) {
            try validator.validate(manifest)
        }
    }

    @Test
    func toolCannotAddAPlatformUnsupportedByItsPackage() {
        let tool = makeTool(supportedPlatforms: [.macOS, .iOS])
        let manifest = makeManifest(
            supportedPlatforms: [.macOS],
            tools: [tool]
        )

        #expect(
            throws: PluginPackageValidationError.toolPlatformsExceedPackage(
                tool.id.rawValue
            )
        ) {
            try validator.validate(manifest)
        }
    }

    @Test
    func remotePluginRequiresHTTPSAndNoLocalEntryPoint() throws {
        let valid = makeManifest(
            runtime: .remoteService,
            entryPoint: nil,
            serviceURL: URL(string: "https://plugins.example.dev/run")
        )
        try validator.validate(valid)

        let insecure = makeManifest(
            runtime: .remoteService,
            entryPoint: nil,
            serviceURL: URL(string: "http://plugins.example.dev/run")
        )
        #expect(throws: PluginPackageValidationError.insecureServiceURL) {
            try validator.validate(insecure)
        }
    }

    @Test
    func nativeProcessRuntimeIsMacOSOnly() {
        let manifest = makeManifest(
            supportedPlatforms: [.iOS],
            tools: [makeTool(supportedPlatforms: [.iOS])]
        )

        #expect(
            throws: PluginPackageValidationError.runtimeUnavailableOnPlatform(
                .nativeProcess,
                .iOS
            )
        ) {
            try validator.validate(manifest)
        }
    }

    @Test
    func extractedPackageMustContainDeclaredPayload() throws {
        let temporaryDirectory = try makeTemporaryPackageDirectory()
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }
        let manifest = makeManifest()
        try write(manifest, to: temporaryDirectory)

        #expect(
            throws: PluginPackageValidationError.missingPayload(
                "payload/macos-arm64/plugin"
            )
        ) {
            try validator.validatePackage(at: temporaryDirectory)
        }
    }

    @Test
    func extractedPackageWithRegularPayloadPassesValidation() throws {
        let temporaryDirectory = try makeTemporaryPackageDirectory()
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }
        let manifest = makeManifest()
        try write(manifest, to: temporaryDirectory)
        let payloadURL = temporaryDirectory.appending(
            path: "payload/macos-arm64/plugin",
            directoryHint: .notDirectory
        )
        try FileManager.default.createDirectory(
            at: payloadURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data("plugin".utf8).write(to: payloadURL)
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o755],
            ofItemAtPath: payloadURL.path
        )

        let validated = try validator.validatePackage(at: temporaryDirectory)

        #expect(validated == manifest)
    }

    @Test
    func nativeProcessPayloadMustBeExecutable() throws {
        let temporaryDirectory = try makeTemporaryPackageDirectory()
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }
        let manifest = makeManifest()
        try write(manifest, to: temporaryDirectory)
        let payloadURL = temporaryDirectory.appending(
            path: "payload/macos-arm64/plugin",
            directoryHint: .notDirectory
        )
        try FileManager.default.createDirectory(
            at: payloadURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data("plugin".utf8).write(to: payloadURL)
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o644],
            ofItemAtPath: payloadURL.path
        )

        #expect(
            throws: PluginPackageValidationError.nonExecutablePayload(
                "payload/macos-arm64/plugin"
            )
        ) {
            try validator.validatePackage(at: temporaryDirectory)
        }
    }

    @Test
    func payloadBehindIntermediateSymbolicLinkIsRejected() throws {
        let packageDirectory = try makeTemporaryPackageDirectory()
        let outsideDirectory = try makeTemporaryPackageDirectory()
        defer {
            try? FileManager.default.removeItem(at: packageDirectory)
            try? FileManager.default.removeItem(at: outsideDirectory)
        }
        let manifest = makeManifest()
        try write(manifest, to: packageDirectory)
        let outsidePayload = outsideDirectory.appending(
            path: "plugin",
            directoryHint: .notDirectory
        )
        try Data("plugin".utf8).write(to: outsidePayload)
        let payloadRoot = packageDirectory.appending(
            path: "payload",
            directoryHint: .isDirectory
        )
        try FileManager.default.createDirectory(
            at: payloadRoot,
            withIntermediateDirectories: true
        )
        try FileManager.default.createSymbolicLink(
            at: payloadRoot.appending(
                path: "macos-arm64",
                directoryHint: .isDirectory
            ),
            withDestinationURL: outsideDirectory
        )

        #expect(
            throws: PluginPackageValidationError.symbolicLinkPayload(
                "payload/macos-arm64/plugin"
            )
        ) {
            try validator.validatePackage(at: packageDirectory)
        }
    }

    @Test
    func manifestSizeIsBoundedBeforeDecoding() {
        let oversizedData = Data(
            repeating: 0,
            count: PluginPackageValidator.maximumManifestSize + 1
        )

        #expect(throws: PluginPackageValidationError.manifestTooLarge) {
            try validator.decodeAndValidateManifest(from: oversizedData)
        }
    }

    private func makeManifest(
        runtime: ToolPluginRuntime = .nativeProcess,
        entryPoint: String? = "payload/macos-arm64/plugin",
        serviceURL: URL? = nil,
        supportedPlatforms: Set<ToolPlatform> = [.macOS],
        permissions: Set<ToolPluginPermission> = [],
        tools: [PluginPackageToolManifest]? = nil
    ) -> PluginPackageManifest {
        PluginPackageManifest(
            identifier: ToolPluginIdentifier(
                rawValue: "dev.example.formatter"
            ),
            displayName: "Example Formatter",
            summary: "Formats text using an external plugin process.",
            author: PluginAuthor(
                name: "Example Developer",
                website: URL(string: "https://example.dev")
            ),
            version: ToolPluginVersion(1, 0, 0),
            runtime: runtime,
            entryPoint: entryPoint,
            serviceURL: serviceURL,
            supportedPlatforms: supportedPlatforms,
            permissions: permissions,
            tools: tools ?? [makeTool(supportedPlatforms: supportedPlatforms)]
        )
    }

    private func makeTool(
        id: String = "dev.example.formatter.text",
        supportedPlatforms: Set<ToolPlatform> = [.macOS]
    ) -> PluginPackageToolManifest {
        PluginPackageToolManifest(
            id: ToolDefinition.ID(rawValue: id),
            categoryID: .text,
            title: "Example Formatter",
            description: "Formats selected text.",
            systemImage: "text.alignleft",
            supportedPlatforms: supportedPlatforms
        )
    }

    private func makeTemporaryPackageDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appending(
            path: "PluginPackageTests-\(UUID().uuidString)",
            directoryHint: .isDirectory
        )
        try FileManager.default.createDirectory(
            at: url,
            withIntermediateDirectories: true
        )
        return url
    }

    private func write(
        _ manifest: PluginPackageManifest,
        to directory: URL
    ) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(manifest)
        try data.write(
            to: directory.appending(
                path: PluginPackageLayout.manifestFileName,
                directoryHint: .notDirectory
            )
        )
    }
}
