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
            version: ToolPluginVersion(1, 0, 0),
            requiredCapabilities: definition.requiredCapabilities
        )
    }
}
