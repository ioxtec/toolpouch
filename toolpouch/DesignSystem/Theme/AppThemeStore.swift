import Combine
import Foundation

final class AppThemeStore: ObservableObject {
    @Published private(set) var themes: [AppTheme]
    @Published private(set) var selectedThemeID: String

    private let defaults: UserDefaults
    private let preferenceKey: String

    var selectedTheme: AppTheme {
        themes.first { $0.id == selectedThemeID } ?? themes[0]
    }

    init(
        catalog: AppThemeCatalog = AppThemeLoader.loadBundledCatalog(),
        defaults: UserDefaults = .standard,
        preferenceKey: String = AppPreferenceKey.selectedThemeID
    ) {
        let availableThemes = catalog.themes.isEmpty
            ? [.draculaFallback]
            : catalog.themes
        themes = availableThemes
        self.defaults = defaults
        self.preferenceKey = preferenceKey

        let savedID = defaults.string(forKey: preferenceKey)
        if let savedID, availableThemes.contains(where: { $0.id == savedID }) {
            selectedThemeID = savedID
        } else if availableThemes.contains(where: { $0.id == catalog.defaultThemeID }) {
            selectedThemeID = catalog.defaultThemeID
        } else {
            selectedThemeID = availableThemes[0].id
        }
    }

    func selectTheme(id: String) {
        guard themes.contains(where: { $0.id == id }) else { return }
        selectedThemeID = id
        defaults.set(id, forKey: preferenceKey)
    }
}

enum AppThemeLoader {
    static func decode(_ data: Data) throws -> AppThemeCatalog {
        try JSONDecoder().decode(AppThemeCatalog.self, from: data)
    }

    static func loadBundledCatalog(bundle: Bundle = .main) -> AppThemeCatalog {
        guard let url = bundle.url(forResource: "AppThemes", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let catalog = try? decode(data),
              !catalog.themes.isEmpty else {
            return fallbackCatalog
        }
        return catalog
    }

    static let fallbackCatalog = AppThemeCatalog(
        version: 1,
        defaultThemeID: AppTheme.draculaFallback.id,
        themes: [.draculaFallback]
    )
}
