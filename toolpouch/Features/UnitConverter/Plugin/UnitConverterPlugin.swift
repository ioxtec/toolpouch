import SwiftUI

struct UnitConverterPlugin: ToolPlugin {
    let definition = ToolDefinition(
        id: .unitConverter,
        categoryID: .everyday,
        title: "Unit Converter",
        description: "Convert metric, imperial, cooking, and data units.",
        systemImage: "arrow.left.arrow.right",
        supportedPlatforms: Set(ToolPlatform.allCases),
        executionBackend: .nativeSwift
    )

    func makeDestination(dependencies: AppDependencies) -> AnyView {
        AnyView(UnitConverterView(converter: LocalUnitConverter()))
    }
}
