#if os(macOS)
import SwiftUI

struct ClipboardInspectorPlugin: ToolPlugin {
    let definition = ToolDefinition(
        id: .clipboardInspector,
        categoryID: .clipboard,
        title: "Clipboard Inspector",
        description: "Preview formats and clear the current clipboard.",
        systemImage: "clipboard.fill",
        supportedPlatforms: [.macOS],
        executionBackend: .nativeSwift
    )

    func makeDestination(dependencies: AppDependencies) -> AnyView {
        AnyView(
            ClipboardInspectorView(inspector: SystemClipboardInspector())
        )
    }
}
#endif
