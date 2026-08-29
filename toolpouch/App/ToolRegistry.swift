import SwiftUI

@MainActor
/// Keeps tool metadata, ordering, platform availability, and destination creation in one place.
struct ToolRegistry {
    let categories: [ToolCategory]
    private let plugins: [any ToolPlugin]
    private let configuration: ToolCatalogConfiguration
    private let capabilityResolver: any CapabilityResolving

    init(
        configuration: ToolCatalogConfiguration,
        plugins: [any ToolPlugin],
        capabilityResolver: any CapabilityResolving = SystemCapabilityResolver()
    ) {
        let identifiers = plugins.map(\.definition.id)
        precondition(
            Set(identifiers).count == identifiers.count,
            "Tool plugin identifiers must be unique."
        )

        self.configuration = configuration
        categories = configuration.sections.map(\.category)
        self.plugins = plugins
        self.capabilityResolver = capabilityResolver
    }

    var tools: [ToolDefinition] {
        plugins.map(\.definition)
    }

    var quickAccessMaximumCount: Int {
        configuration.quickAccess.maximumCount
    }

    func category(id: ToolCategory.ID) -> ToolCategory? {
        categories.first { $0.id == id }
    }

    func tool(id: ToolDefinition.ID) -> ToolDefinition? {
        plugins.first { $0.definition.id == id }?.definition
    }

    /// Returns the plugin manifest for a tool, if it is registered.
    func manifest(for toolID: ToolDefinition.ID) -> ToolPluginManifest? {
        plugins.first { $0.definition.id == toolID }?.manifest
    }

    func tools(in categoryID: ToolCategory.ID) -> [ToolDefinition] {
        let toolsInCategory = tools.filter { $0.categoryID == categoryID }
        guard let order = configuration.section(id: categoryID)?.toolOrder else {
            return toolsInCategory
        }

        let positions = Dictionary(
            uniqueKeysWithValues: order.enumerated().map { ($1, $0) }
        )
        return toolsInCategory.sorted {
            let lhsPosition = positions[$0.id] ?? Int.max
            let rhsPosition = positions[$1.id] ?? Int.max
            return lhsPosition == rhsPosition
                ? $0.title.localizedStandardCompare($1.title) == .orderedAscending
                : lhsPosition < rhsPosition
        }
    }

    func tools(
        in categoryID: ToolCategory.ID,
        for platform: ToolPlatform
    ) -> [ToolDefinition] {
        tools(in: categoryID).filter {
            $0.supportedPlatforms.contains(platform)
                && isAvailable($0)
        }
    }

    func categories(for platform: ToolPlatform) -> [ToolCategory] {
        categories.filter {
            $0.supportedPlatforms.contains(platform)
                && !tools(in: $0.id, for: platform).isEmpty
        }
    }

    func quickAccessTools(for platform: ToolPlatform) -> [ToolDefinition] {
        quickAccessTools(
            for: platform,
            toolIDs: configuration.quickAccess.defaultToolIDs
        )
    }

    func quickAccessTools(
        for platform: ToolPlatform,
        toolIDs: [ToolDefinition.ID]
    ) -> [ToolDefinition] {
        // Stored shortcuts may refer to removed or unsupported tools, so resolve and filter them before display.
        Array(
            toolIDs
                .compactMap { tool(id: $0) }
                .filter {
                    $0.supportedPlatforms.contains(platform)
                        && isAvailable($0)
                }
                .prefix(configuration.quickAccess.maximumCount)
        )
    }

    func tools(for platform: ToolPlatform) -> [ToolDefinition] {
        categories(for: platform).flatMap {
            tools(in: $0.id, for: platform)
        }
    }

    /// Whether the tool is available on the current device given its capabilities.
    private func isAvailable(_ tool: ToolDefinition) -> Bool {
        capabilityResolver.supports(
            requiredCapabilities: tool.requiredCapabilities
        )
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
    /// Creates the production registry from the bundled catalog and platform-appropriate plugins.
    static func live() -> ToolRegistry {
        ToolRegistry(
            configuration: ToolCatalogConfigurationLoader.load(),
            plugins: livePlugins,
            capabilityResolver: SystemCapabilityResolver()
        )
    }

    private static var livePlugins: [any ToolPlugin] {
        var plugins: [any ToolPlugin] = [
            UnitConverterPlugin(),
            QuickCopyNotesPlugin(),
            NetworkInfoPlugin(),
            DomainLookupPlugin(),
            PasswordGeneratorPlugin(),
            TextEncoderPlugin(),
            ArchiveToolPlugin(),
            SystemStatsPlugin(),
        ]
        #if !os(watchOS)
        plugins.append(CoordinateToolPlugin())
        plugins.append(NetworkCheckPlugin())
        plugins.append(JSONToolkitPlugin())
        plugins.append(HashChecksumPlugin())
        plugins.append(ImageInspectorPlugin())
        #endif
        #if os(macOS)
        plugins.append(ClipboardInspectorPlugin())
        plugins.append(ColorPickerPlugin())
        plugins.append(MediaFileInfoPlugin())
        plugins.append(WiFiScannerPlugin())
        plugins.append(SSHKeysPlugin())
        #endif
        return plugins
    }
}
