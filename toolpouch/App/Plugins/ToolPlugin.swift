import SwiftUI

@MainActor
/// Describes a tool that is compiled into the app and can create its own root view.
protocol ToolPlugin {
    var definition: ToolDefinition { get }

    /// Declarative metadata describing the plugin's version and requirements.
    var manifest: ToolPluginManifest { get }

    /// Builds the tool's destination with the shared services assembled by the app.
    func makeDestination(dependencies: AppDependencies) -> AnyView
}

extension ToolPlugin {
    /// Defaults to version 1.0.0 and mirrors the tool's declared capabilities.
    var manifest: ToolPluginManifest {
        ToolPluginManifest(
            identifier: ToolPluginIdentifier(rawValue: definition.id.rawValue),
            version: ToolPluginVersion(1, 0, 0),
            runtime: .nativeSwift,
            requiredCapabilities: definition.requiredCapabilities
        )
    }
}

@MainActor
/// Type-erased registration consumed by the registry. Bundled Swift plugins
/// and future package-backed hosts meet at this boundary.
struct RegisteredToolPlugin {
    let definition: ToolDefinition
    let manifest: ToolPluginManifest
    let source: ToolPluginSource

    private let destinationFactory: (AppDependencies) -> AnyView

    init(
        definition: ToolDefinition,
        manifest: ToolPluginManifest,
        source: ToolPluginSource,
        destinationFactory: @escaping (AppDependencies) -> AnyView
    ) {
        self.definition = definition
        self.manifest = manifest
        self.source = source
        self.destinationFactory = destinationFactory
    }

    init(
        bundled plugin: any ToolPlugin
    ) {
        self.init(
            definition: plugin.definition,
            manifest: plugin.manifest,
            source: .bundled,
            destinationFactory: plugin.makeDestination(dependencies:)
        )
    }

    func makeDestination(dependencies: AppDependencies) -> AnyView {
        destinationFactory(dependencies)
    }
}
