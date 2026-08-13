import Foundation
import Testing
@testable import toolpouch

struct AppThemeTests {
    @Test func decodesThemeCatalog() throws {
        let data = try #require(
            """
            {
              "version": 1,
              "defaultThemeID": "test",
              "themes": [{
                "id": "test",
                "name": "Test",
                "description": "A test theme.",
                "appearance": "dark",
                "renderingStyle": "solid",
                "colors": {
                  "background": { "hex": "111111" },
                  "surface": { "hex": "222222" },
                  "elevatedSurface": { "hex": "333333" },
                  "interactiveSurface": { "hex": "444444" },
                  "border": { "hex": "555555" },
                  "primaryText": { "hex": "FFFFFF" },
                  "secondaryText": { "hex": "AAAAAA" },
                  "primaryAccent": { "hex": "FF79C6" },
                  "secondaryAccent": { "hex": "8BE9FD" },
                  "success": { "hex": "50FA7B" },
                  "warning": { "hex": "F1FA8C" },
                  "danger": { "hex": "FF5555" }
                }
              }]
            }
            """.data(using: .utf8)
        )

        let catalog = try AppThemeLoader.decode(data)

        #expect(catalog.defaultThemeID == "test")
        #expect(catalog.themes.first?.renderingStyle == .solid)
        #expect(catalog.themes.first?.colors.primaryAccent.hex == "FF79C6")
    }

    @Test func themeStorePersistsAValidSelection() {
        let suiteName = "AppThemeTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let secondTheme = AppTheme(
            id: "second",
            name: "Second",
            description: "Second theme",
            appearance: .dark,
            renderingStyle: .solid,
            colors: .draculaTestColors
        )
        let catalog = AppThemeCatalog(
            version: 1,
            defaultThemeID: "dracula",
            themes: [.draculaFallback, secondTheme]
        )
        let store = AppThemeStore(catalog: catalog, defaults: defaults)

        store.selectTheme(id: secondTheme.id)

        #expect(store.selectedThemeID == secondTheme.id)
        #expect(defaults.string(forKey: AppPreferenceKey.selectedThemeID) == secondTheme.id)
    }
}

private extension AppThemeColors {
    static let draculaTestColors = AppTheme.draculaFallback.colors
}
