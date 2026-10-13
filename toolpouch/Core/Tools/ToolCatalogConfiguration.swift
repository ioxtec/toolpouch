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
                id: .device,
                title: "Device & System",
                description: "System information and utilities for this device",
                systemImage: "cpu",
                supportedPlatforms: Set(ToolPlatform.allCases),
                toolOrder: [.systemStats, .clipboardInspector]
            ),
            Section(
                id: .network,
                title: "Network & Internet",
                description: "Connection details, Wi-Fi, and internet domains",
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
                id: .credentials,
                title: "Passwords & Keys",
                description: "Generate passwords and manage access keys",
                systemImage: "key.fill",
                supportedPlatforms: Set(ToolPlatform.allCases),
                toolOrder: [.passwordGenerator, .sshKeys]
            ),
            Section(
                id: .text,
                title: "Text & Data",
                description: "Reusable notes and tools for structured text",
                systemImage: "textformat",
                supportedPlatforms: Set(ToolPlatform.allCases),
                toolOrder: [.quickCopyNotes, .textEncoder, .jsonToolkit]
            ),
            Section(
                id: .calculations,
                title: "Calculations & Conversions",
                description: "Calculate hashes and convert common units",
                systemImage: "arrow.left.arrow.right",
                supportedPlatforms: Set(ToolPlatform.allCases),
                toolOrder: [.unitConverter, .hashChecksum]
            ),
            Section(
                id: .science,
                title: "Science & Math",
                description: "Calculators, graphs, and data analysis",
                systemImage: "function",
                supportedPlatforms: [.iOS, .macOS],
                toolOrder: [.scientificCalculator, .functionGraphs]
            ),
            Section(
                id: .files,
                title: "Files & Archives",
                description: "Compress, extract, and inspect files",
                systemImage: "archivebox.fill",
                supportedPlatforms: [.iOS, .macOS],
                toolOrder: [.archiveTool, .mediaFileInfo]
            ),
            Section(
                id: .graphics,
                title: "Graphics",
                description: "Inspect images and work with colors",
                systemImage: "paintpalette.fill",
                supportedPlatforms: [.iOS, .macOS],
                toolOrder: [.imageInspector, .colorPicker]
            ),
            Section(
                id: .location,
                title: "Maps & Coordinates",
                description: "Find places and convert coordinates",
                systemImage: "map.fill",
                supportedPlatforms: [.iOS, .macOS],
                toolOrder: [.coordinateTool]
            ),
        ]
    )
}
