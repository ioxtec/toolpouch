import Combine
import Foundation
import SwiftUI

nonisolated enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case system
    case english = "en"
    case polish = "pl"
    case german = "de"
    case french = "fr"
    case spanish = "es"
    case italian = "it"
    case portugueseBrazil = "pt-BR"
    case japanese = "ja"
    case korean = "ko"
    case simplifiedChinese = "zh-Hans"
    case traditionalChinese = "zh-Hant"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: "System".localizedInterfaceText
        case .english: "English"
        case .polish: "Polski"
        case .german: "Deutsch"
        case .french: "Français"
        case .spanish: "Español"
        case .italian: "Italiano"
        case .portugueseBrazil: "Português (Brasil)"
        case .japanese: "日本語"
        case .korean: "한국어"
        case .simplifiedChinese: "简体中文"
        case .traditionalChinese: "繁體中文"
        }
    }

    var locale: Locale {
        switch self {
        case .system:
            Locale(identifier: Locale.preferredLanguages.first ?? "en")
        default:
            Locale(identifier: rawValue)
        }
    }

    var localizationBundle: Bundle {
        let preferences: [String]
        switch self {
        case .system:
            preferences = Locale.preferredLanguages
        default:
            preferences = [rawValue]
        }

        let available = Bundle.main.localizations.filter { $0 != "Base" }
        let localization = Bundle.preferredLocalizations(
            from: available,
            forPreferences: preferences
        ).first ?? Bundle.main.developmentLocalization ?? "en"

        guard let path = Bundle.main.path(
            forResource: localization,
            ofType: "lproj"
        ), let bundle = Bundle(path: path) else {
            return .main
        }
        return bundle
    }

    static var persistedSelection: AppLanguage {
        let rawValue = UserDefaults.standard.string(
            forKey: AppPreferenceKey.interfaceLanguage
        )
        return rawValue.flatMap(AppLanguage.init(rawValue:)) ?? .system
    }
}

final class AppLanguageStore: ObservableObject {
    @Published private(set) var selection: AppLanguage

    private let defaults: UserDefaults
    private let preferenceKey: String

    var locale: Locale { selection.locale }

    init(
        defaults: UserDefaults = .standard,
        preferenceKey: String = AppPreferenceKey.interfaceLanguage
    ) {
        self.defaults = defaults
        self.preferenceKey = preferenceKey
        let rawValue = defaults.string(forKey: preferenceKey)
        selection = rawValue.flatMap(AppLanguage.init(rawValue:)) ?? .system
    }

    func select(_ language: AppLanguage) {
        guard selection != language else { return }
        defaults.set(language.rawValue, forKey: preferenceKey)
        selection = language
    }
}

extension String {
    /// Resolves a runtime localization key from the shared String Catalog.
    /// Use this only for app-owned interface copy, never for user-entered text.
    nonisolated var localizedInterfaceText: String {
        AppLanguage.persistedSelection.localizationBundle.localizedString(
            forKey: self,
            value: self,
            table: nil
        )
    }
}

private struct AppLanguageEnvironmentModifier: ViewModifier {
    @ObservedObject var languageStore: AppLanguageStore
    let rebuildOnChange: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        let localizedContent = content
            .environment(\.locale, languageStore.locale)
            .environmentObject(languageStore)

        if rebuildOnChange {
            localizedContent.id(languageStore.selection)
        } else {
            localizedContent
        }
    }
}

extension View {
    func appLanguage(
        _ languageStore: AppLanguageStore,
        rebuildOnChange: Bool = true
    ) -> some View {
        modifier(
            AppLanguageEnvironmentModifier(
                languageStore: languageStore,
                rebuildOnChange: rebuildOnChange
            )
        )
    }
}
