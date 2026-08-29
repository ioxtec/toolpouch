import Foundation

nonisolated struct ToolCatalogConfiguration: Codable, Sendable {
    struct QuickAccess: Codable, Sendable {
        let maximumCount: Int
        let defaultToolIDs: [ToolDefinition.ID]
    }

    struct Section: Codable, Sendable {
        let id: ToolCategory.ID
        let title: String
        let description: String
        let systemImage: String
        let supportedPlatforms: Set<ToolPlatform>
        let toolOrder: [ToolDefinition.ID]

        var category: ToolCategory {
            ToolCategory(
                id: id,
                title: title,
                description: description,
                systemImage: systemImage,
                supportedPlatforms: supportedPlatforms
            )
        }
    }

    let schemaVersion: Int
    let quickAccess: QuickAccess
    let sections: [Section]

    func section(id: ToolCategory.ID) -> Section? {
        sections.first { $0.id == id }
    }
}

enum ToolCatalogConfigurationLoader {
    /// Reads the bundled catalog and falls back to a built-in copy when the resource is unavailable or invalid.
    static func load(bundle: Bundle = .main) -> ToolCatalogConfiguration {
        guard let url = bundle.url(
            forResource: "ToolCatalog",
            withExtension: "json"
        ),
        let data = try? Data(contentsOf: url),
        let configuration = try? JSONDecoder().decode(
            ToolCatalogConfiguration.self,
            from: data
        ) else {
            return .fallback
        }

        return configuration
    }
}

private extension ToolCatalogConfiguration {
    static let fallback = ToolCatalogConfiguration(
        schemaVersion: 1,
        quickAccess: QuickAccess(
            maximumCount: 6,
            defaultToolIDs: [
                .passwordGenerator,
                .networkInfo,
                .clipboardInspector,
                .textEncoder,
                .domainLookup,
                .sshKeys,
            ]
        ),
        sections: [
            Section(
                id: .everyday,
                title: "Everyday",
                description: "Useful tools for daily tasks",
                systemImage: "sparkles",
                supportedPlatforms: Set(ToolPlatform.allCases),
                toolOrder: [.quickCopyNotes, .unitConverter, .archiveTool]
            ),
            Section(
                id: .system,
                title: "System",
                description: "Live health, resource, storage, and power information",
                systemImage: "cpu",
                supportedPlatforms: Set(ToolPlatform.allCases),
                toolOrder: [.systemStats]
            ),
            Section(
                id: .network,
                title: "Network",
                description: "Connection details, Wi-Fi, and domains",
                systemImage: "network",
                supportedPlatforms: Set(ToolPlatform.allCases),
                toolOrder: [
                    .networkInfo,
                    .networkCheck,
                    .wiFiScanner,
                    .domainLookup,
                ]
            ),
            Section(
                id: .passwords,
                title: "Passwords",
                description: "Create secure and memorable passwords",
                systemImage: "key.fill",
                supportedPlatforms: Set(ToolPlatform.allCases),
                toolOrder: [.passwordGenerator]
            ),
            Section(
                id: .clipboard,
                title: "Clipboard",
                description: "Inspect and work with copied content",
                systemImage: "clipboard",
                supportedPlatforms: [.macOS],
                toolOrder: [.clipboardInspector]
            ),
            Section(
                id: .text,
                title: "Text & Files",
                description: "Convert and clean up text and data",
                systemImage: "textformat",
                supportedPlatforms: Set(ToolPlatform.allCases),
                toolOrder: [.textEncoder, .jsonToolkit, .hashChecksum]
            ),
            Section(
                id: .developer,
                title: "Developer",
                description: "Keys and advanced technical tools",
                systemImage: "chevron.left.forwardslash.chevron.right",
                supportedPlatforms: Set(ToolPlatform.allCases),
                toolOrder: [.sshKeys]
            ),
            Section(
                id: .visual,
                title: "Images & Colors",
                description: "Images, colors, and visual utilities",
                systemImage: "photo.on.rectangle.angled",
                supportedPlatforms: [.iOS, .macOS],
                toolOrder: [.imageInspector, .colorPicker]
            ),
        ]
    )
}
