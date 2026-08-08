import SwiftUI

struct ArchiveToolPlugin: ToolPlugin {
    let definition = ToolDefinition(
        id: .archiveTool,
        categoryID: .everyday,
        title: "Archive Tool",
        description: "Compress folders and files, or extract ZIP, GZIP, BZIP2, XZ, TAR and TGZ archives.",
        systemImage: "shippingbox",
        supportedPlatforms: [.iOS, .macOS],
        executionBackend: .nativeSwift
    )

    func makeDestination(dependencies: AppDependencies) -> AnyView {
        AnyView(ArchiveToolView(archiveManager: ArchiveManager()))
    }
}
