import SwiftUI

struct NetworkInfoPlugin: ToolPlugin {
    let definition = ToolDefinition(
        id: .networkInfo,
        categoryID: .network,
        title: "Network Info",
        description: "IP addresses, DNS, router, and interface details.",
        systemImage: "network",
        supportedPlatforms: [.macOS, .iOS, .watchOS],
        executionBackend: .nativeSwift,
        requiredCapabilities: [.network]
    )

    func makeDestination(dependencies: AppDependencies) -> AnyView {
        AnyView(NetworkInfoView(dependencies: dependencies))
    }
}
