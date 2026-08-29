import SwiftUI

struct MediaFileInfoPlugin: ToolPlugin {
    let definition = ToolDefinition(
        id: .mediaFileInfo,
        categoryID: .visual,
        title: "Media File Info",
        description: "Inspect image, audio, and video metadata, codecs, and tracks.",
        systemImage: "play.rectangle.on.rectangle",
        supportedPlatforms: [.macOS],
        executionBackend: .nativeSwift
    )

    func makeDestination(dependencies: AppDependencies) -> AnyView {
        AnyView(MediaFileInfoView(inspector: AVFoundationMediaFileInspector()))
    }
}
