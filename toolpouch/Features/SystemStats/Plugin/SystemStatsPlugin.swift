import SwiftUI

/// Bundled, App Store-safe system overview. The collector intentionally avoids
/// private sensor APIs, which keeps this tool portable across Apple platforms.
struct SystemStatsPlugin: ToolPlugin {
    let definition = ToolDefinition(
        id: .systemStats,
        categoryID: .system,
        title: "System Stats",
        description: "CPU, memory, storage, battery, thermal state, and uptime.",
        systemImage: "cpu",
        supportedPlatforms: Set(ToolPlatform.allCases),
        executionBackend: .nativeSwift
    )

    func makeDestination(dependencies: AppDependencies) -> AnyView {
        AnyView(SystemStatsView())
    }
}
