import SwiftUI

struct NetworkCheckPlugin: ToolPlugin {
    let definition = ToolDefinition(
        id: .networkCheck,
        categoryID: .network,
        title: "Network Check",
        description: "Resolve a host and check whether a TCP port is reachable.",
        systemImage: "wave.3.right.circle",
        supportedPlatforms: [.macOS, .iOS],
        executionBackend: .nativeSwift
    )

    func makeDestination(dependencies: AppDependencies) -> AnyView {
        AnyView(NetworkCheckView(checker: SystemNetworkChecker()))
    }
}
