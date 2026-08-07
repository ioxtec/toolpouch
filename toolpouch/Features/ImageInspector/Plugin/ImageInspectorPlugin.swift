import SwiftUI

struct ImageInspectorPlugin: ToolPlugin {
    let definition = ToolDefinition(
        id: .imageInspector,
        categoryID: .visual,
        title: "Image Toolkit",
        description: "Inspect metadata, resize images, and convert formats.",
        systemImage: "photo.badge.magnifyingglass",
        supportedPlatforms: [.macOS, .iOS],
        executionBackend: .rust,
        requiredCapabilities: [.rustEngine]
    )

    func makeDestination(dependencies: AppDependencies) -> AnyView {
        AnyView(ImageInspectorView(inspector: RustImageInspector()))
    }
}
