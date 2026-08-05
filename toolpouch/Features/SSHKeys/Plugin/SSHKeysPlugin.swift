#if os(macOS)
import SwiftUI

struct SSHKeysPlugin: ToolPlugin {
    let definition = ToolDefinition(
        id: .sshKeys,
        categoryID: .developer,
        title: "SSH Keys",
        description: "Browse, generate, and copy SSH key pairs.",
        systemImage: "key.horizontal",
        supportedPlatforms: [.macOS],
        executionBackend: .nativeSwift
    )

    func makeDestination(dependencies: AppDependencies) -> AnyView {
        AnyView(
            SSHKeysView(
                manager: SystemSSHKeyManager(),
                folderStore: SecurityScopedSSHKeyFolderStore()
            )
        )
    }
}
#endif
