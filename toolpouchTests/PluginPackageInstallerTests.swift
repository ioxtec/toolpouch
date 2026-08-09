import Foundation
import Testing
@testable import toolpouch

@MainActor
struct PluginPackageInstallerTests {
    private let identifier = ToolPluginIdentifier(
        rawValue: "dev.example.formatter"
    )

    @Test
    func installsAndActivatesUnsignedDevelopmentPackage() async throws {
        let fixture = try makeFixture(version: ToolPluginVersion(1, 0, 0))
        defer { fixture.remove() }
        let installer = makeDevelopmentInstaller(storeURL: fixture.storeURL)

        let result = try await installer.install(archiveURL: fixture.archiveURL)
        let active = try await installer.activeVersion(for: identifier)
        let versions = try await installer.installedVersions(for: identifier)

        #expect(result.isActive)
        #expect(result.installation.trustLevel == .unsignedLocal)
        #expect(active == result.installation)
        #expect(versions == [result.installation])
        #expect(
            FileManager.default.fileExists(
                atPath: result.packageURL.appending(
                    path: "payload/macos-arm64/plugin",
                    directoryHint: .notDirectory
                ).path
            )
        )
    }

    @Test
    func inactiveInstallDoesNotChangeActivePointer() async throws {
        let fixture = try makeFixture(version: ToolPluginVersion(1, 0, 0))
        defer { fixture.remove() }
        let installer = makeDevelopmentInstaller(storeURL: fixture.storeURL)

        let result = try await installer.install(
            archiveURL: fixture.archiveURL,
            activate: false
        )

        #expect(!result.isActive)
        #expect(try await installer.activeVersion(for: identifier) == nil)
        #expect(try await installer.installedVersions(for: identifier).count == 1)
    }

    @Test
    func activationRollsBackBetweenInstalledVersions() async throws {
        let fixtureV1 = try makeFixture(version: ToolPluginVersion(1, 0, 0))
        let fixtureV2 = try makeFixture(
            version: ToolPluginVersion(2, 0, 0),
            rootURL: fixtureV1.rootURL
        )
        defer { fixtureV1.remove() }
        let installer = makeDevelopmentInstaller(storeURL: fixtureV1.storeURL)
        _ = try await installer.install(archiveURL: fixtureV1.archiveURL)
        _ = try await installer.install(archiveURL: fixtureV2.archiveURL)

        let rolledBack = try await installer.activate(
            identifier: identifier,
            version: ToolPluginVersion(1, 0, 0)
        )

        #expect(rolledBack.version == ToolPluginVersion(1, 0, 0))
        #expect(
            try await installer.activeVersion(for: identifier)?.version
                == ToolPluginVersion(1, 0, 0)
        )
        #expect(
            try await installer.installedVersions(for: identifier).map(\.version)
                == [ToolPluginVersion(2, 0, 0), ToolPluginVersion(1, 0, 0)]
        )
    }

    @Test
    func removingActiveVersionFallsBackToNewestRemainingVersion() async throws {
        let fixtureV1 = try makeFixture(version: ToolPluginVersion(1, 0, 0))
        let fixtureV2 = try makeFixture(
            version: ToolPluginVersion(2, 0, 0),
            rootURL: fixtureV1.rootURL
        )
        defer { fixtureV1.remove() }
        let installer = makeDevelopmentInstaller(storeURL: fixtureV1.storeURL)
        _ = try await installer.install(archiveURL: fixtureV1.archiveURL)
        _ = try await installer.install(archiveURL: fixtureV2.archiveURL)
        _ = try await installer.activate(
            identifier: identifier,
            version: ToolPluginVersion(1, 0, 0)
        )

        try await installer.uninstall(
            identifier: identifier,
            version: ToolPluginVersion(1, 0, 0)
        )

        #expect(
            try await installer.activeVersion(for: identifier)?.version
                == ToolPluginVersion(2, 0, 0)
        )
    }

    @Test
    func duplicateVersionIsRejectedWithoutChangingActiveVersion() async throws {
        let fixture = try makeFixture(version: ToolPluginVersion(1, 0, 0))
        defer { fixture.remove() }
        let installer = makeDevelopmentInstaller(storeURL: fixture.storeURL)
        _ = try await installer.install(archiveURL: fixture.archiveURL)

        await #expect(
            throws: PluginInstallationError.versionAlreadyInstalled(
                identifier.rawValue,
                "1.0.0"
            )
        ) {
            try await installer.install(archiveURL: fixture.archiveURL)
        }
        #expect(
            try await installer.activeVersion(for: identifier)?.version
                == ToolPluginVersion(1, 0, 0)
        )
    }

    @Test
    func repositoryPolicyRejectsUnsignedPackageWithoutPartialInstall() async throws {
        let fixture = try makeFixture(version: ToolPluginVersion(1, 0, 0))
        defer { fixture.remove() }
        let installer = PluginPackageInstaller(
            rootDirectory: fixture.storeURL,
            policy: .repositoryOnly
        )

        await #expect(
            throws: PluginInstallationError.unsignedPackageNotAllowed
        ) {
            try await installer.install(archiveURL: fixture.archiveURL)
        }
        #expect(try await installer.installedVersions(for: identifier).isEmpty)
        let stagingURL = fixture.storeURL.appending(
            path: ".staging",
            directoryHint: .isDirectory
        )
        let stagedItems = try FileManager.default.contentsOfDirectory(
            at: stagingURL,
            includingPropertiesForKeys: nil
        )
        #expect(stagedItems.isEmpty)
    }

    @Test
    func appStorePolicyRejectsNativeProcessPackage() async throws {
        let fixture = try makeFixture(
            version: ToolPluginVersion(1, 0, 0),
            runtime: .nativeProcess
        )
        defer { fixture.remove() }
        let installer = PluginPackageInstaller(
            rootDirectory: fixture.storeURL,
            policy: .repositoryOnly,
            signatureVerifier: StubSignatureVerifier(
                trustLevel: .repositorySigned
            )
        )

        await #expect(
            throws: PluginInstallationError.runtimeNotAllowed(.nativeProcess)
        ) {
            try await installer.install(archiveURL: fixture.archiveURL)
        }
        #expect(try await installer.installedVersions(for: identifier).isEmpty)
    }

    @Test
    func signedVerifierPersistsEstablishedTrust() async throws {
        let fixture = try makeFixture(version: ToolPluginVersion(1, 0, 0))
        defer { fixture.remove() }
        let installer = PluginPackageInstaller(
            rootDirectory: fixture.storeURL,
            policy: .repositoryOnly,
            signatureVerifier: StubSignatureVerifier(
                trustLevel: .repositorySigned
            )
        )

        let result = try await installer.install(archiveURL: fixture.archiveURL)

        #expect(result.installation.trustLevel == .repositorySigned)
    }

    @Test
    func unsafeLookupIdentifierCannotEscapePluginStore() async throws {
        let fixture = try makeFixture(version: ToolPluginVersion(1, 0, 0))
        defer { fixture.remove() }
        let installer = makeDevelopmentInstaller(storeURL: fixture.storeURL)
        let unsafeIdentifier = ToolPluginIdentifier(rawValue: "../../outside")

        await #expect(
            throws: PluginInstallationError.invalidIdentifier("../../outside")
        ) {
            try await installer.installedVersions(for: unsafeIdentifier)
        }
    }

    @Test
    func uninstallAllRemovesPluginAndActivePointer() async throws {
        let fixture = try makeFixture(version: ToolPluginVersion(1, 0, 0))
        defer { fixture.remove() }
        let installer = makeDevelopmentInstaller(storeURL: fixture.storeURL)
        _ = try await installer.install(archiveURL: fixture.archiveURL)

        try await installer.uninstallAll(identifier: identifier)

        #expect(try await installer.activeVersion(for: identifier) == nil)
        #expect(try await installer.installedVersions(for: identifier).isEmpty)
    }

    private func makeFixture(
        version: ToolPluginVersion,
        rootURL existingRoot: URL? = nil,
        runtime: ToolPluginRuntime = .webAssembly
    ) throws -> PluginInstallerFixture {
        let rootURL = existingRoot ?? FileManager.default.temporaryDirectory
            .appending(
                path: "PluginInstallerTests-\(UUID().uuidString)",
                directoryHint: .isDirectory
            )
        try FileManager.default.createDirectory(
            at: rootURL,
            withIntermediateDirectories: true
        )
        let sourceURL = rootURL.appending(
            path: "source-\(version.string)",
            directoryHint: .isDirectory
        )
        try FileManager.default.createDirectory(
            at: sourceURL,
            withIntermediateDirectories: true
        )
        let payloadURL = sourceURL.appending(
            path: "payload/macos-arm64/plugin",
            directoryHint: .notDirectory
        )
        try FileManager.default.createDirectory(
            at: payloadURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data("plugin-\(version.string)".utf8).write(to: payloadURL)
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o755],
            ofItemAtPath: payloadURL.path
        )

        let manifest = PluginPackageManifest(
            identifier: identifier,
            displayName: "Example Formatter",
            summary: "Formats example text.",
            author: PluginAuthor(name: "Example Developer"),
            version: version,
            runtime: runtime,
            entryPoint: "payload/macos-arm64/plugin",
            supportedPlatforms: [.macOS],
            tools: [
                PluginPackageToolManifest(
                    id: ToolDefinition.ID(
                        rawValue: "dev.example.formatter.text"
                    ),
                    categoryID: .text,
                    title: "Example Formatter",
                    description: "Formats example text.",
                    systemImage: "text.alignleft",
                    supportedPlatforms: [.macOS]
                ),
            ]
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(manifest).write(
            to: sourceURL.appending(
                path: PluginPackageLayout.manifestFileName,
                directoryHint: .notDirectory
            )
        )

        let archiveURL = rootURL.appending(
            path: "formatter-\(version.string).toolpouchplugin",
            directoryHint: .notDirectory
        )
        try ZipArchive.create(
            from: sourceURL,
            to: archiveURL,
            includeRootDirectory: false
        )
        return PluginInstallerFixture(
            rootURL: rootURL,
            storeURL: rootURL.appending(
                path: "store",
                directoryHint: .isDirectory
            ),
            archiveURL: archiveURL,
            ownsRoot: existingRoot == nil
        )
    }

    private func makeDevelopmentInstaller(
        storeURL: URL
    ) -> PluginPackageInstaller {
        PluginPackageInstaller(
            rootDirectory: storeURL,
            policy: .localDevelopment
        )
    }
}

private struct PluginInstallerFixture {
    let rootURL: URL
    let storeURL: URL
    let archiveURL: URL
    let ownsRoot: Bool

    func remove() {
        if ownsRoot {
            try? FileManager.default.removeItem(at: rootURL)
        }
    }
}

private struct StubSignatureVerifier: PluginPackageSignatureVerifying {
    let trustLevel: PluginPackageTrustLevel

    func verify(
        packageURL: URL,
        manifest: PluginPackageManifest
    ) throws -> PluginPackageTrustLevel {
        trustLevel
    }
}
