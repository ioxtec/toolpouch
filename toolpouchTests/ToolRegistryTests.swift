import Foundation
import SwiftUI
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
    func categoryIdentifiersCanRepresentExternalCatalogSections() throws {
        let identifier = ToolCategory.ID(
            rawValue: "dev.example.specialized-tools"
        )
        let encoded = try JSONEncoder().encode(identifier)
        let decoded = try JSONDecoder().decode(
            ToolCategory.ID.self,
            from: encoded
        )

        #expect(decoded == identifier)
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
    func bundledToolIdentifiersUseToolpouchNamespace() {
        for tool in registry.tools {
            #expect(tool.id.rawValue.hasPrefix("com.toolpouch."))
        }
    }

    @Test
    func identifiersCanRepresentThirdPartyTools() throws {
        let identifier = ToolDefinition.ID(
            rawValue: "dev.example.formatter"
        )
        let encoded = try JSONEncoder().encode(identifier)
        let decoded = try JSONDecoder().decode(
            ToolDefinition.ID.self,
            from: encoded
        )

        #expect(decoded == identifier)
        #expect(String(decoding: encoded, as: UTF8.self) == "\"dev.example.formatter\"")
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
    func systemStatsIsAvailableOnEveryPlatform() {
        #expect(
            registry.tool(id: .systemStats)?.supportedPlatforms
                == Set(ToolPlatform.allCases)
        )
        #expect(registry.tools(in: .system, for: .watchOS).map(\.id) == [.systemStats])
    }

    @Test
    func unitConverterIsAvailableOnEveryPlatform() {
        #expect(
            registry.tool(id: .unitConverter)?.supportedPlatforms
                == Set(ToolPlatform.allCases)
        )
    }

    @Test
    func quickCopyNotesIsAvailableOnEveryPlatform() {
        #expect(
            registry.tool(id: .quickCopyNotes)?.supportedPlatforms
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
    func archiveToolIsAvailableOnMacOSAndIOS() {
        #expect(
            registry.tool(id: .archiveTool)?.supportedPlatforms
                == [.macOS, .iOS]
        )
        #expect(
            !registry.tools(in: .everyday, for: .watchOS)
                .contains { $0.id == .archiveTool }
        )
    }

    @Test
    func coordinateToolIsAvailableOnMacOSAndIOS() {
        #expect(
            registry.tool(id: .coordinateTool)?.supportedPlatforms
                == [.macOS, .iOS]
        )
        #expect(
            !registry.tools(in: .everyday, for: .watchOS)
                .contains { $0.id == .coordinateTool }
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
            #expect(
                manifest?.requiredCapabilities
                    == tool.requiredCapabilities
            )
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

    @Test
    func quickAccessPreferencesMigrateLegacyAndPreserveExternalIDs() {
        let suiteName = "QuickAccessMigrationTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let storageKey = AppPreferenceKey.quickAccessToolIDs(for: .macOS)
        defaults.set(
            ["networkInfo", "dev.example.formatter"],
            forKey: storageKey
        )

        let preferences = QuickAccessPreferences(
            platform: .macOS,
            defaultToolIDs: [],
            maximumCount: 6,
            defaults: defaults
        )

        #expect(
            preferences.toolIDs == [
                .networkInfo,
                ToolDefinition.ID(rawValue: "dev.example.formatter"),
            ]
        )
        #expect(
            defaults.stringArray(forKey: storageKey) == [
                ToolDefinition.ID.networkInfo.rawValue,
                "dev.example.formatter",
            ]
        )
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
