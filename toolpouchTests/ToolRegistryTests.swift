import Testing
@testable import toolpouch

@MainActor
struct ToolRegistryTests {
    private let registry = ToolRegistry.live()

    @Test
    func categoryIdentifiersAreUnique() {
        let identifiers = registry.categories.map(\.id)

        #expect(Set(identifiers).count == identifiers.count)
    }

    @Test
    func categoriesHaveCompletePresentationMetadata() {
        for category in registry.categories {
            #expect(!category.title.isEmpty)
            #expect(!category.description.isEmpty)
            #expect(!category.systemImage.isEmpty)
            #expect(!category.supportedPlatforms.isEmpty)
        }
    }

    @Test
    func toolIdentifiersAreUnique() {
        let identifiers = registry.tools.map(\.id)

        #expect(Set(identifiers).count == identifiers.count)
    }

    @Test
    func toolsReferenceExistingCategories() {
        let categoryIdentifiers = Set(registry.categories.map(\.id))

        for tool in registry.tools {
            #expect(categoryIdentifiers.contains(tool.categoryID))
            #expect(!tool.supportedPlatforms.isEmpty)
        }
    }

    @Test
    func networkInfoPluginIsRegistered() {
        #expect(registry.tool(id: .networkInfo) != nil)
    }

    @Test
    func passwordGeneratorIsAvailableOnEveryPlatform() {
        #expect(
            registry.tool(id: .passwordGenerator)?.supportedPlatforms
                == Set(ToolPlatform.allCases)
        )
    }

    @Test
    func textEncoderIsAvailableOnEveryPlatform() {
        #expect(
            registry.tool(id: .textEncoder)?.supportedPlatforms
                == Set(ToolPlatform.allCases)
        )
    }

    @Test
    func networkToolsExposeExpectedPlatformAvailability() {
        #expect(
            registry.tool(id: .networkInfo)?.supportedPlatforms
                == Set(ToolPlatform.allCases)
        )
        #expect(
            registry.tool(id: .wiFiScanner)?.supportedPlatforms == [.macOS]
        )
        #expect(registry.tool(id: .sshKeys)?.supportedPlatforms == [.macOS])
    }

    @Test
    func platformFilteringHidesUnsupportedTools() {
        let macTools = registry.tools(in: .network, for: .macOS)
        let iOSTools = registry.tools(in: .network, for: .iOS)

        #expect(macTools.contains { $0.id == .wiFiScanner })
        #expect(!iOSTools.contains { $0.id == .wiFiScanner })
        #expect(iOSTools.contains { $0.id == .networkInfo })

        let iOSSecurityTools = registry.tools(in: .security, for: .iOS)
        #expect(!iOSSecurityTools.contains { $0.id == .sshKeys })
    }

    @Test
    func watchCategoriesHideUnsupportedImageAndDesignSections() {
        let watchCategories = registry.categories(for: .watchOS)

        #expect(!watchCategories.contains { $0.id == .images })
        #expect(!watchCategories.contains { $0.id == .design })
        #expect(watchCategories.contains { $0.id == .network })
    }
}
