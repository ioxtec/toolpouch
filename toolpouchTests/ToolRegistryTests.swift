import Foundation
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
    func unitConverterIsAvailableOnEveryPlatform() {
        #expect(
            registry.tool(id: .unitConverter)?.supportedPlatforms
                == Set(ToolPlatform.allCases)
        )
    }

    @Test
    func domainLookupIsAvailableOnEveryPlatform() {
        #expect(
            registry.tool(id: .domainLookup)?.supportedPlatforms
                == Set(ToolPlatform.allCases)
        )
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
    func jsonToolkitIsAvailableOnMacOSAndIOS() {
        #expect(
            registry.tool(id: .jsonToolkit)?.supportedPlatforms
                == [.macOS, .iOS]
        )
    }

    @Test
    func hashChecksumIsAvailableOnMacOSAndIOS() {
        #expect(
            registry.tool(id: .hashChecksum)?.supportedPlatforms
                == [.macOS, .iOS]
        )
    }

    @Test
    func imageInspectorUsesRustOnMacOSAndIOS() {
        let tool = registry.tool(id: .imageInspector)

        #expect(tool?.supportedPlatforms == [.macOS, .iOS])
        #expect(tool?.executionBackend == .rust)
    }

    @Test
    func colorPickerIsAvailableOnlyOnMacOS() {
        #expect(registry.tool(id: .colorPicker)?.supportedPlatforms == [.macOS])
    }

    @Test
    func networkCheckIsAvailableOnMacOSAndIOS() {
        #expect(
            registry.tool(id: .networkCheck)?.supportedPlatforms
                == [.macOS, .iOS]
        )
    }

    @Test
    func clipboardInspectorIsAvailableOnMacOS() {
        #expect(
            registry.tool(id: .clipboardInspector)?.supportedPlatforms
                == [.macOS]
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

        let iOSDeveloperTools = registry.tools(in: .developer, for: .iOS)
        #expect(!iOSDeveloperTools.contains { $0.id == .sshKeys })
    }

    @Test
    func platformCategoriesHideEmptyAndUnsupportedSections() {
        let watchCategories = registry.categories(for: .watchOS)

        #expect(!watchCategories.contains { $0.id == .visual })
        #expect(!watchCategories.contains { $0.id == .developer })
        #expect(watchCategories.contains { $0.id == .network })
    }

    @Test
    func catalogControlsToolOrder() {
        let networkTools = registry.tools(in: .network, for: .macOS)

        #expect(
            networkTools.map(\.id)
                == [.networkInfo, .networkCheck, .wiFiScanner, .domainLookup]
        )
    }

    @Test
    func quickAccessUsesCatalogOrderAndPlatformAvailability() {
        let macTools = registry.quickAccessTools(for: .macOS)
        let watchTools = registry.quickAccessTools(for: .watchOS)

        #expect(macTools.count == 6)
        #expect(macTools.first?.id == .passwordGenerator)
        #expect(!watchTools.contains { $0.id == .clipboardInspector })
        #expect(!watchTools.contains { $0.id == .sshKeys })
    }

    @Test
    func domainLookupUsesFamiliarWhoisName() {
        #expect(registry.tool(id: .domainLookup)?.title == "Whois")
    }

    @Test
    func everyToolExposesAPluginManifest() {
        for tool in registry.tools {
            let manifest = registry.manifest(for: tool.id)
            #expect(manifest != nil)
            #expect(manifest?.version.string == "1.0.0")
        }
    }

    @Test
    func manifestExposesRequiredCapabilities() {
        let manifest = registry.manifest(for: .colorPicker)
        #expect(manifest?.requiredCapabilities.contains(.screenCapture) == true)
    }

    @Test
    func networkToolsAreHiddenWhenNetworkCapabilityIsMissing() {
        let registry = ToolRegistry(
            configuration: ToolCatalogConfigurationLoader.load(),
            plugins: [NetworkInfoPlugin(), DomainLookupPlugin()],
            capabilityResolver: NoNetworkCapabilityResolver()
        )

        #expect(registry.tools(in: .network, for: .macOS).isEmpty)
        #expect(registry.tool(id: .networkInfo) != nil)
    }

    @Test
    func quickAccessPreferencesPersistUniqueLimitedToolIDs() {
        let suiteName = "QuickAccessPreferencesTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let preferences = QuickAccessPreferences(
            platform: .macOS,
            defaultToolIDs: [.passwordGenerator],
            maximumCount: 3,
            defaults: defaults
        )

        preferences.save([
            .networkInfo,
            .networkInfo,
            .passwordGenerator,
            .domainLookup,
            .textEncoder,
        ])

        #expect(
            preferences.toolIDs
                == [.networkInfo, .passwordGenerator, .domainLookup]
        )

        let restoredPreferences = QuickAccessPreferences(
            platform: .macOS,
            defaultToolIDs: [],
            maximumCount: 3,
            defaults: defaults
        )
        #expect(restoredPreferences.toolIDs == preferences.toolIDs)

        preferences.save([])
        let emptyPreferences = QuickAccessPreferences(
            platform: .macOS,
            defaultToolIDs: [.passwordGenerator],
            maximumCount: 3,
            defaults: defaults
        )
        #expect(emptyPreferences.toolIDs.isEmpty)
    }
}

/// Resolver that never exposes the network capability, used to verify that
/// tools requiring it are hidden from the registry.
private struct NoNetworkCapabilityResolver: CapabilityResolving {
    let platform: ToolPlatform = .macOS

    func hasCapability(_ capability: ToolCapability) -> Bool {
        capability != .network
    }
}
