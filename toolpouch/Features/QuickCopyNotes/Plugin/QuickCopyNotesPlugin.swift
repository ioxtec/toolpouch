import SwiftUI

struct QuickCopyNotesPlugin: ToolPlugin {
    let definition = ToolDefinition(
        id: .quickCopyNotes,
        categoryID: .text,
        title: "Quick Copy Notes",
        description: "Organize reusable text and copy it with one click.",
        systemImage: "doc.on.clipboard",
        supportedPlatforms: Set(ToolPlatform.allCases),
        executionBackend: .nativeSwift
    )

    func makeDestination(dependencies: AppDependencies) -> AnyView {
        AnyView(QuickCopyNotesView())
    }
}
