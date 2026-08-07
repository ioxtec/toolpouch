#if os(macOS)
import SwiftUI

struct WiFiScannerPlugin: ToolPlugin {
    let definition = ToolDefinition(
        id: .wiFiScanner,
        categoryID: .network,
        title: "Wi-Fi Scanner",
        description: "Nearby networks, channels, and signal strength.",
        systemImage: "wifi",
        supportedPlatforms: [.macOS],
        executionBackend: .nativeSwift,
        requiredCapabilities: [.wiFiScanning]
    )

    func makeDestination(dependencies: AppDependencies) -> AnyView {
        AnyView(
            WiFiScannerView(
                scanner: dependencies.wiFiScanner,
                authorizer: dependencies.wiFiScanAuthorizer
            )
        )
    }
}
#endif
