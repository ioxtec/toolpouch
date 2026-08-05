import SwiftUI

struct HashChecksumPlugin: ToolPlugin {
    let definition = ToolDefinition(
        id: .hashChecksum,
        categoryID: .text,
        title: "Hash & Checksum",
        description: "Calculate and compare hashes for text or files.",
        systemImage: "number",
        supportedPlatforms: [.macOS, .iOS],
        executionBackend: .nativeSwift
    )

    func makeDestination(dependencies: AppDependencies) -> AnyView {
        AnyView(HashChecksumView(calculator: CryptoKitHashCalculator()))
    }
}
