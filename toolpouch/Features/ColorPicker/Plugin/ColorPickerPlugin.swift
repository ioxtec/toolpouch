#if os(macOS)
import SwiftUI

struct ColorPickerPlugin: ToolPlugin {
    let definition = ToolDefinition(
        id: .colorPicker,
        categoryID: .visual,
        title: "Color Picker",
        description: "Pick an exact pixel color anywhere on your screens.",
        systemImage: "eyedropper.halffull",
        supportedPlatforms: [.macOS],
        executionBackend: .nativeSwift
    )

    func makeDestination(dependencies: AppDependencies) -> AnyView {
        AnyView(ColorPickerView())
    }
}
#endif
