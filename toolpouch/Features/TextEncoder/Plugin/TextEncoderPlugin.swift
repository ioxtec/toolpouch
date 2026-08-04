import SwiftUI

struct TextEncoderPlugin: ToolPlugin {
    let definition = ToolDefinition(
        id: .textEncoder,
        categoryID: .text,
        title: "Text Encoder",
        description: "Convert text with Base64, Base32, Base64URL, or Hex.",
        systemImage: "textformat.abc",
        supportedPlatforms: [.macOS, .iOS, .watchOS],
        executionBackend: .nativeSwift
    )

    func makeDestination(dependencies: AppDependencies) -> AnyView {
        AnyView(TextEncoderView(converter: BinaryTextConverter()))
    }
}
