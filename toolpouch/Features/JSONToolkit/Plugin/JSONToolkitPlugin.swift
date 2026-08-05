import SwiftUI

struct JSONToolkitPlugin: ToolPlugin {
    let definition = ToolDefinition(
        id: .jsonToolkit,
        categoryID: .text,
        title: "JSON Toolkit",
        description: "Format, compact, and validate JSON locally.",
        systemImage: "curlybraces",
        supportedPlatforms: [.macOS, .iOS],
        executionBackend: .nativeSwift
    )

    func makeDestination(dependencies: AppDependencies) -> AnyView {
        AnyView(JSONToolkitView(formatter: FoundationJSONFormatter()))
    }
}
