import SwiftUI

struct ScientificCalculatorPlugin: ToolPlugin {
    let definition = ToolDefinition(
        id: .scientificCalculator,
        categoryID: .science,
        title: "Scientific Calculator",
        description: "Calculate expressions with functions, constants, and angle modes.",
        systemImage: "function",
        supportedPlatforms: [.macOS, .iOS],
        executionBackend: .nativeSwift
    )

    func makeDestination(dependencies: AppDependencies) -> AnyView {
        AnyView(
            ScientificCalculatorView(calculator: ScientificExpressionEvaluator())
        )
    }
}
