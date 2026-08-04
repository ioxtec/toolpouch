import SwiftUI

struct PasswordGeneratorPlugin: ToolPlugin {
    let definition = ToolDefinition(
        id: .passwordGenerator,
        categoryID: .passwords,
        title: "Password Generator",
        description: "Random passwords and memorable passphrases.",
        systemImage: "key.horizontal.fill",
        supportedPlatforms: [.macOS, .iOS, .watchOS],
        executionBackend: .nativeSwift
    )

    func makeDestination(dependencies: AppDependencies) -> AnyView {
        let words = (try? EFFPassphraseWordList.load()) ?? []
        return AnyView(
            PasswordGeneratorView(
                generator: SecurePasswordGenerator(words: words)
            )
        )
    }
}
