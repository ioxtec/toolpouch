import SwiftUI

@MainActor
protocol ToolPlugin {
    var definition: ToolDefinition { get }

    func makeDestination(dependencies: AppDependencies) -> AnyView
}
