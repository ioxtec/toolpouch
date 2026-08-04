import SwiftUI

@MainActor
struct ToolRegistry {
    let categories: [ToolCategory]
    private let plugins: [any ToolPlugin]

    init(
        categories: [ToolCategory],
        plugins: [any ToolPlugin]
    ) {
        let identifiers = plugins.map(\.definition.id)
        precondition(
            Set(identifiers).count == identifiers.count,
            "Tool plugin identifiers must be unique."
        )

        self.categories = categories
        self.plugins = plugins
    }

    var tools: [ToolDefinition] {
        plugins.map(\.definition)
    }

    func category(id: ToolCategory.ID) -> ToolCategory? {
        categories.first { $0.id == id }
    }

    func tool(id: ToolDefinition.ID) -> ToolDefinition? {
        plugins.first { $0.definition.id == id }?.definition
    }

    func tools(in categoryID: ToolCategory.ID) -> [ToolDefinition] {
        tools.filter { $0.categoryID == categoryID }
    }

    func tools(
        in categoryID: ToolCategory.ID,
        for platform: ToolPlatform
    ) -> [ToolDefinition] {
        tools(in: categoryID).filter {
            $0.supportedPlatforms.contains(platform)
        }
    }

    func categories(for platform: ToolPlatform) -> [ToolCategory] {
        categories.filter { $0.supportedPlatforms.contains(platform) }
    }

    func destination(
        for toolID: ToolDefinition.ID,
        dependencies: AppDependencies
    ) -> AnyView? {
        plugins.first { $0.definition.id == toolID }?
            .makeDestination(dependencies: dependencies)
    }
}

extension ToolRegistry {
    static func live() -> ToolRegistry {
        ToolRegistry(
            categories: [
                ToolCategory(
                    id: .network,
                    title: "Network",
                    description: "IP, DNS, Ping, HTTP...",
                    systemImage: "network"
                ),
                ToolCategory(
                    id: .security,
                    title: "Security",
                    description: "SSH, Keys, Hashes...",
                    systemImage: "lock.shield"
                ),
                ToolCategory(
                    id: .passwords,
                    title: "Passwords",
                    description: "Password generator",
                    systemImage: "key.fill"
                ),
                ToolCategory(
                    id: .clipboard,
                    title: "Clipboard",
                    description: "Snippets and notes",
                    systemImage: "clipboard"
                ),
                ToolCategory(
                    id: .design,
                    title: "Design",
                    description: "Colors and UI",
                    systemImage: "paintpalette",
                    supportedPlatforms: [.iOS, .macOS]
                ),
                ToolCategory(
                    id: .images,
                    title: "Images",
                    description: "Resize and convert",
                    systemImage: "photo.on.rectangle",
                    supportedPlatforms: [.iOS, .macOS]
                ),
                ToolCategory(
                    id: .text,
                    title: "Text",
                    description: "JSON, Base64...",
                    systemImage: "textformat"
                ),
                ToolCategory(
                    id: .sync,
                    title: "Sync",
                    description: "Shared files",
                    systemImage: "icloud"
                ),
                ToolCategory(
                    id: .utilities,
                    title: "Utilities",
                    description: "Timer and monitor",
                    systemImage: "wrench.and.screwdriver"
                ),
            ],
            plugins: livePlugins
        )
    }

    private static var livePlugins: [any ToolPlugin] {
        var plugins: [any ToolPlugin] = [NetworkInfoPlugin()]
        #if os(macOS)
        plugins.append(WiFiScannerPlugin())
        plugins.append(SSHKeysPlugin())
        #endif
        return plugins
    }
}
