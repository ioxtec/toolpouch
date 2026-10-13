import SwiftUI

struct FunctionGraphsPlugin: ToolPlugin {
    let definition = ToolDefinition(
        id: .functionGraphs,
        categoryID: .science,
        title: "Function Graphs",
        description: "Plot mathematical expressions and explore their ranges.",
        systemImage: "chart.xyaxis.line",
        supportedPlatforms: [.macOS, .iOS],
        executionBackend: .nativeSwift
    )

    func makeDestination(dependencies: AppDependencies) -> AnyView {
        let calculator = ScientificExpressionEvaluator()
        return AnyView(
            FunctionGraphsView(
                sampler: LocalFunctionGraphSampler(calculator: calculator)
            )
        )
    }
}
