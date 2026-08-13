import SwiftUI

/// Entry point for this bundled Swift tool. New built-in tools follow the same
/// pattern: declare metadata here, then register the plugin in `ToolRegistry`.
struct CoordinateToolPlugin: ToolPlugin {
    let definition = ToolDefinition(
        id: .coordinateTool,
        categoryID: .everyday,
        title: "Map Coordinates",
        description: "Find a place, pick a point on the map, and convert its coordinates.",
        systemImage: "mappin.and.ellipse",
        supportedPlatforms: [.iOS, .macOS],
        executionBackend: .nativeSwift,
        requiredCapabilities: [.network]
    )

    func makeDestination(dependencies: AppDependencies) -> AnyView {
        AnyView(CoordinateToolView())
    }
}
