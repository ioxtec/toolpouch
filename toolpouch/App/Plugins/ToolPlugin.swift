import SwiftUI

@MainActor
/// Describes a tool that is compiled into the app and can create its own root view.
protocol ToolPlugin {
    var definition: ToolDefinition { get }

    /// Builds the tool's destination with the shared services assembled by the app.
    func makeDestination(dependencies: AppDependencies) -> AnyView
}
